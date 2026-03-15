import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/local_database.dart';
import '../models/plant_model.dart';
import '../models/sensor_reading.dart';
import '../models/plant_note.dart';
import '../models/reminder.dart';

// Auth Providers
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.userChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Plants Providers
final plantsStreamProvider = StreamProvider<List<PlantModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return FirebaseService.streamCollection(
    FirebaseService.plantsRef,
    filters: [QueryFilter('userId', user.uid)],
  ).map((snapshot) {
    final plants = snapshot.docs
        .map((doc) => PlantModel.fromFirestore(doc))
        .toList();
    
    // Sort locally by descending createdAt to avoid needing a Firestore composite index
    plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Cache locally
    for (final plant in plants) {
      LocalDatabase.upsertPlant(plant);
    }
    return plants;
  });
});

final plantProvider = StreamProvider.family<PlantModel?, String>((ref, plantId) {
  return FirebaseService.plantsRef
      .doc(plantId)
      .snapshots()
      .map((doc) => doc.exists ? PlantModel.fromFirestore(doc) : null);
});

// Sensor Readings Providers
final sensorReadingsProvider = StreamProvider.family<List<SensorReading>, String>((ref, plantId) {
  return FirebaseService.sensorReadingsRef(plantId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    final readings = snapshot.docs
        .map((doc) => SensorReading.fromFirestore(doc))
        .toList();
    for (final r in readings) {
      LocalDatabase.upsertSensorReading(r);
    }
    return readings;
  });
});

final latestSensorReadingProvider = Provider.family<SensorReading?, String>((ref, plantId) {
  final readings = ref.watch(sensorReadingsProvider(plantId));
  return readings.value?.isNotEmpty == true ? readings.value!.first : null;
});

// Notes Providers
final plantNotesProvider = StreamProvider.family<List<PlantNote>, String>((ref, plantId) {
  return FirebaseService.plantNotesRef(plantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    final notes = snapshot.docs
        .map((doc) => PlantNote.fromFirestore(doc))
        .toList();
    for (final n in notes) {
      LocalDatabase.upsertNote(n);
    }
    return notes;
  });
});

// Reminders Providers
final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return FirebaseService.remindersRef
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final reminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
        // Sort locally by nextDueDate ascending to avoid needing a Firestore composite index
        reminders.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        return reminders;
      });
});

final pendingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.value?.where((r) => !r.isCompleted).toList() ?? [];
});

final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(pendingRemindersProvider);
  return reminders.where((r) => r.isOverdue).toList();
});

// Garden Stats Provider
final gardenStatsProvider = Provider<GardenStats>((ref) {
  final plants = ref.watch(plantsStreamProvider).value ?? [];
  final reminders = ref.watch(pendingRemindersProvider);

  if (plants.isEmpty) return GardenStats.empty();

  final avgHealth = plants.fold<double>(0, (sum, p) => sum + p.healthScore) / plants.length;
  final alerts = <String>[];

  for (final plant in plants) {
    if (plant.healthScore < 40) {
      alerts.add('${plant.name} a besoin d\'attention');
    }
  }

  return GardenStats(
    totalPlants: plants.length,
    averageHealth: avgHealth,
    pendingReminders: reminders.length,
    alerts: alerts,
    overdueCount: ref.watch(overdueRemindersProvider).length,
    varietiesCount: plants.map((p) => p.species.toLowerCase()).toSet().length,
  );
});

class GardenStats {
  final int totalPlants;
  final double averageHealth;
  final int pendingReminders;
  final List<String> alerts;
  final int overdueCount;
  final int varietiesCount;

  GardenStats({
    required this.totalPlants,
    required this.averageHealth,
    required this.pendingReminders,
    required this.alerts,
    required this.overdueCount,
    required this.varietiesCount,
  });

  factory GardenStats.empty() => GardenStats(
    totalPlants: 0,
    averageHealth: 0,
    pendingReminders: 0,
    alerts: [],
    overdueCount: 0,
    varietiesCount: 0,
  );
}

// Sensor Simulation
class SensorSimulator {
  static final _random = Random();

  static SensorReading generateReading(String plantId, {SensorReading? previous}) {
    double moisture, temp, light;

    if (previous != null) {
      // Gradual changes from previous reading
      moisture = (previous.soilMoisture + (_random.nextDouble() * 20 - 12)).clamp(10, 95);
      temp = (previous.temperature + (_random.nextDouble() * 4 - 2)).clamp(5, 40);
      light = (previous.light + (_random.nextDouble() * 30 - 15)).clamp(5, 100);
    } else {
      // Fresh random reading
      moisture = 30 + _random.nextDouble() * 50;
      temp = 18 + _random.nextDouble() * 12;
      light = 40 + _random.nextDouble() * 50;
    }

    return SensorReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantId: plantId,
      soilMoisture: double.parse(moisture.toStringAsFixed(1)),
      temperature: double.parse(temp.toStringAsFixed(1)),
      light: double.parse(light.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
  }
}

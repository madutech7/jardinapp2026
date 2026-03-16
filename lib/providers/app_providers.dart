import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/local_database.dart';
import '../models/plant_model.dart';
import '../models/sensor_reading.dart';
import '../models/plant_note.dart';
import '../models/reminder.dart';

// === Fournisseurs d'Authentification (Auth Providers) ===

/// Fournisseur d'état écoutant les changements d'authentification de l'utilisateur.
/// Retourne le flux (stream) de l'utilisateur Firebase actuel.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.userChanges;
});

/// Fournisseur utilitaire pour accéder facilement à l'utilisateur connecté de manière synchrone.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// === Fournisseurs de Plantes (Plants Providers) ===

/// Écoute en temps réel la collection de plantes de l'utilisateur connecté depuis Firestore.
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
    
    // Tri localement par date de création (les plus récentes en premier)
    // Cela évite de devoir créer un index composite complexe sur Firestore.
    plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Mise en cache locale (dans la base de données SQLite locale)
    for (final plant in plants) {
      LocalDatabase.upsertPlant(plant);
    }
    return plants;
  });
});

/// Fournisseur permettant d'écouter les détails d'une seule plante spécifique.
/// Reste synchronisé en temps réel avec Firestore.

final plantProvider = StreamProvider.family<PlantModel?, String>((ref, plantId) {
  return FirebaseService.plantsRef
      .doc(plantId)
      .snapshots()
      .map((doc) => doc.exists ? PlantModel.fromFirestore(doc) : null);
});

// === Fournisseurs de Capteurs (Sensor Readings Providers) ===

/// Écoute les 50 dernières lectures de capteurs pour une plante donnée.
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

/// Fournisseur utilitaire extrayant uniquement la lecture de capteur la plus récente.
final latestSensorReadingProvider = Provider.family<SensorReading?, String>((ref, plantId) {
  final readings = ref.watch(sensorReadingsProvider(plantId));
  return readings.value?.isNotEmpty == true ? readings.value!.first : null;
});

// === Fournisseurs de Notes (Notes Providers) ===

/// Écoute en temps réel toutes les notes (journal) associées à une plante spécifique.
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

// === Fournisseurs de Rappels (Reminders Providers) ===

/// Écoute la liste complète des rappels de l'utilisateur depuis Firestore.
final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return FirebaseService.remindersRef
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final reminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
        // Tri localement par date prévue croissante pour éviter le besoin d'un index composite Firestore.
        reminders.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        return reminders;
      });
});

/// Extrait et filtre uniquement les rappels qui ne sont pas encore terminés.
final pendingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.value?.where((r) => !r.isCompleted).toList() ?? [];
});

/// Extrait spécifiquement les rappels dont la date prévue est dépassée.
final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(pendingRemindersProvider);
  return reminders.where((r) => r.isOverdue).toList();
});

// === Fournisseur de Statistiques du Jardin (Garden Stats Provider) ===

/// Calcule et fournit les statistiques globales du jardin (santé moyenne, nb de plantes, alertes).
/// Se met à jour automatiquement si les données des plantes ou des rappels changent.
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

// === Outil de Simulation (Sensor Simulation) ===

/// Classe utilitaire générant des données factices (simulées) pour les capteurs.
/// Utilisé pour démontrer les fonctionnalités de l'application sans matériel physique.
class SensorSimulator {
  static final _random = Random();

  static SensorReading generateReading(String plantId, {SensorReading? previous}) {
    double moisture, temp, light;

    if (previous != null) {
      // Évolution graduelle et réaliste par rapport à la dernière lecture
      moisture = (previous.soilMoisture + (_random.nextDouble() * 20 - 12)).clamp(10, 95);
      temp = (previous.temperature + (_random.nextDouble() * 4 - 2)).clamp(5, 40);
      light = (previous.light + (_random.nextDouble() * 30 - 15)).clamp(5, 100);
    } else {
      // Nouvelle lecture complètement aléatoire
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

import 'package:cloud_firestore/cloud_firestore.dart';

class SensorReading {
  final String id;
  final String plantId;
  final double soilMoisture; // 0-100%
  final double temperature; // celsius
  final double light; // 0-100%
  final DateTime timestamp;
  final String? notes;

  SensorReading({
    required this.id,
    required this.plantId,
    required this.soilMoisture,
    required this.temperature,
    required this.light,
    required this.timestamp,
    this.notes,
  });

  factory SensorReading.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SensorReading(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      soilMoisture: (data['soilMoisture'] ?? 50).toDouble(),
      temperature: (data['temperature'] ?? 20).toDouble(),
      light: (data['light'] ?? 60).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plantId': plantId,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'light': light,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] ?? '',
      plantId: map['plantId'] ?? '',
      soilMoisture: (map['soilMoisture'] ?? 50).toDouble(),
      temperature: (map['temperature'] ?? 20).toDouble(),
      light: (map['light'] ?? 60).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'light': light,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Alert logic
  bool get needsWatering => soilMoisture < 30;
  bool get tooCold => temperature < 10;
  bool get tooHot => temperature > 35;
  bool get insufficientLight => light < 20;

  double get healthScore {
    double score = 100;
    if (soilMoisture < 20) {
      score -= 30;
    } else if (soilMoisture < 30) {
      score -= 15;
    } else if (soilMoisture > 80) {
      score -= 10;
    }
    if (temperature < 10 || temperature > 35) {
      score -= 20;
    } else if (temperature < 15 || temperature > 30) {
      score -= 5;
    }
    if (light < 20) {
      score -= 15;
    } else if (light < 30) {
      score -= 5;
    }
    return score.clamp(0, 100);
  }
}

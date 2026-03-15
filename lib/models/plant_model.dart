import 'package:cloud_firestore/cloud_firestore.dart';

class PlantModel {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? photoUrl;
  final DateTime acquisitionDate;
  final String? location;
  final String? description;
  final double healthScore; // 0-100
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.photoUrl,
    required this.acquisitionDate,
    this.location,
    this.description,
    this.healthScore = 80.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      photoUrl: data['photoUrl'],
      acquisitionDate: _parseDate(data['acquisitionDate']),
      location: data['location'],
      description: data['description'],
      healthScore: (data['healthScore'] ?? 80).toDouble(),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'species': species,
      'photoUrl': photoUrl,
      'acquisitionDate': Timestamp.fromDate(acquisitionDate),
      'location': location,
      'description': description,
      'healthScore': healthScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      photoUrl: map['photoUrl'],
      acquisitionDate: DateTime.fromMillisecondsSinceEpoch(map['acquisitionDate'] ?? 0),
      location: map['location'],
      description: map['description'],
      healthScore: (map['healthScore'] ?? 80).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'photoUrl': photoUrl,
      'acquisitionDate': acquisitionDate.millisecondsSinceEpoch,
      'location': location,
      'description': description,
      'healthScore': healthScore,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  PlantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? photoUrl,
    DateTime? acquisitionDate,
    String? location,
    String? description,
    double? healthScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      photoUrl: photoUrl ?? this.photoUrl,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      location: location ?? this.location,
      description: description ?? this.description,
      healthScore: healthScore ?? this.healthScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

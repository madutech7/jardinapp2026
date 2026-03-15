import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType { general, problem, treatment, observation }

class PlantNote {
  final String id;
  final String plantId;
  final String title;
  final String content;
  final NoteType type;
  final String? photoUrl;
  final DateTime createdAt;

  PlantNote({
    required this.id,
    required this.plantId,
    required this.title,
    required this.content,
    required this.type,
    this.photoUrl,
    required this.createdAt,
  });

  factory PlantNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantNote(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'general'),
        orElse: () => NoteType.general,
      ),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plantId': plantId,
      'title': title,
      'content': content,
      'type': type.name,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PlantNote.fromMap(Map<String, dynamic> map) {
    return PlantNote(
      id: map['id'] ?? '',
      plantId: map['plantId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'general'),
        orElse: () => NoteType.general,
      ),
      photoUrl: map['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'title': title,
      'content': content,
      'type': type.name,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

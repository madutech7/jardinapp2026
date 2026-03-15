import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { watering, fertilization, pruning, repotting, treatment, other }
enum ReminderFrequency { once, daily, weekly, biweekly, monthly }

class Reminder {
  final String id;
  final String plantId;
  final String plantName;
  final ReminderType type;
  final String title;
  final String? notes;
  final DateTime nextDueDate;
  final ReminderFrequency frequency;
  final bool isCompleted;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.type,
    required this.title,
    this.notes,
    required this.nextDueDate,
    required this.frequency,
    this.isCompleted = false,
    required this.createdAt,
  });

  bool get isOverdue => !isCompleted && nextDueDate.isBefore(DateTime.now());
  bool get isDueToday {
    final now = DateTime.now();
    return !isCompleted &&
        nextDueDate.year == now.year &&
        nextDueDate.month == now.month &&
        nextDueDate.day == now.day;
  }

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      plantName: data['plantName'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'watering'),
        orElse: () => ReminderType.watering,
      ),
      title: data['title'] ?? '',
      notes: data['notes'],
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == (data['frequency'] ?? 'weekly'),
        orElse: () => ReminderFrequency.weekly,
      ),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'type': type.name,
      'title': title,
      'notes': notes,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'frequency': frequency.name,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Reminder copyWith({
    String? id,
    bool? isCompleted,
    DateTime? nextDueDate,
  }) {
    return Reminder(
      id: id ?? this.id,
      plantId: plantId,
      plantName: plantName,
      type: type,
      title: title,
      notes: notes,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      frequency: frequency,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

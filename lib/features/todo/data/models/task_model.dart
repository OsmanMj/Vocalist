import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String priority; // 'High', 'Medium', 'Low'

  @HiveField(5)
  final DateTime? dueDate;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final int? estimatedDurationMinutes;

  Task({
    String? id,
    required this.title,
    this.description,
    this.category = 'Uncategorized',
    this.priority = 'Medium',
    this.dueDate,
    this.isCompleted = false,
    this.estimatedDurationMinutes,
  }) : id = id ?? const Uuid().v4();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    int? estimatedDurationMinutes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    );
  }
}

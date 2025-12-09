import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/services_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/task_model.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

part 'todo_provider.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<Task>> build() async {
    final repository = ref.watch(todoRepositoryProvider);
    return repository.getTasks();
  }

  Future<void> addTask(
    String title, {
    String? description,
    String category = 'Uncategorized',
    String priority = 'Medium',
    int? estimatedDurationMinutes,
    DateTime? dueDate,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final newTask = Task(
      title: title,
      description: description,
      category: category,
      priority: priority,
      estimatedDurationMinutes: estimatedDurationMinutes,
      dueDate: dueDate,
    );
    await repository.addTask(newTask);

    if (dueDate != null) {
      await NotificationService.scheduleTaskNotification(
        id: newTask.id.hashCode,
        title: 'Task Reminder',
        body: 'It\'s time for: $title',
        scheduledDate: dueDate,
      );
    }

    ref.invalidateSelf();
  }

  Future<void> toggleTask(Task task) async {
    final repository = ref.read(todoRepositoryProvider);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await repository.updateTask(updatedTask);

    // If completed, remove the in-app notification immediately
    if (updatedTask.isCompleted) {
      ref
          .read(notificationProvider.notifier)
          .removeNotificationForTask(task.id);
    }

    ref.invalidateSelf();
  }

  Future<void> deleteTask(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.deleteTask(id);
    await NotificationService.cancelNotification(id.hashCode);
    ref.invalidateSelf();
  }

  Future<void> deleteCompletedTasks() async {
    final repository = ref.read(todoRepositoryProvider);
    final tasks = state.value ?? [];
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    for (final task in completedTasks) {
      await repository.deleteTask(task.id);
      await NotificationService.cancelNotification(task.id.hashCode);
    }

    if (completedTasks.isNotEmpty) {
      ref.invalidateSelf();
    }
  }
}

// Filter System
enum FilterType {
  all,
  today,
  tomorrow,
  upcoming,
  category,
  categoryUpcoming,
  categoryToday
}

class TaskFilter {
  final FilterType type;
  final String? category;

  const TaskFilter({this.type = FilterType.all, this.category});

  bool matches(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    switch (type) {
      case FilterType.all:
        return true;
      case FilterType.today:
        if (task.dueDate == null) return false;
        final taskDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDate.isAtSameMomentAs(today);
      case FilterType.tomorrow:
        if (task.dueDate == null) return false;
        final taskDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDate.isAtSameMomentAs(tomorrow);
      case FilterType.upcoming:
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(nextWeek);
      case FilterType.category:
        return task.category.toLowerCase() == category?.toLowerCase();
      case FilterType.categoryUpcoming:
        if (task.category.toLowerCase() != category?.toLowerCase())
          return false;
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(nextWeek);
      case FilterType.categoryToday:
        if (task.category.toLowerCase() != category?.toLowerCase())
          return false;
        if (task.dueDate == null) return false;
        final taskDate = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDate.isAtSameMomentAs(today);
    }
  }
}

@Riverpod(keepAlive: true)
class TodoFilter extends _$TodoFilter {
  @override
  TaskFilter build() => const TaskFilter();

  void setFilter(FilterType type, {String? category}) {
    state = TaskFilter(type: type, category: category);
  }
}

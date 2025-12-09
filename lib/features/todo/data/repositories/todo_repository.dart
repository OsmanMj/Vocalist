import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

abstract class TodoRepository {
  Future<List<Task>> getTasks();
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
}

class TodoRepositoryImpl implements TodoRepository {
  final Box<Task> _taskBox;

  TodoRepositoryImpl(this._taskBox);

  @override
  Future<List<Task>> getTasks() async {
    return _taskBox.values.toList();
  }

  @override
  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  @override
  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }
}

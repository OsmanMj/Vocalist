import 'package:hive_flutter/hive_flutter.dart';
import '../../features/todo/data/models/task_model.dart';
import '../../features/todo/data/repositories/todo_repository.dart';

class HiveService {
  static const String taskBoxName = 'tasks';
  static const String categoryBoxName = 'categories';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<String>(categoryBoxName);
  }

  static Box<Task> get taskBox => Hive.box<Task>(taskBoxName);
  static Box<String> get categoryBox => Hive.box<String>(categoryBoxName);

  static TodoRepository get todoRepository => TodoRepositoryImpl(taskBox);
}

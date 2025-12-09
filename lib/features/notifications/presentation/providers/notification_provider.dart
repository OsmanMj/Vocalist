import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/notification_item.dart';
import '../../../todo/data/models/task_model.dart'; // Import Task model

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString('notifications');
    if (notificationsJson != null) {
      final List<dynamic> decodedList = jsonDecode(notificationsJson);
      state =
          decodedList.map((item) => NotificationItem.fromMap(item)).toList();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList =
        jsonEncode(state.map((item) => item.toMap()).toList());
    await prefs.setString('notifications', encodedList);
  }

  void addNotification(NotificationItem item) {
    // Check if notification with same ID already exists to prevent duplicates
    if (state.any((n) => n.id == item.id)) return;

    state = [item, ...state];
    _saveNotifications();
  }

  void removeNotificationForTask(String taskId) {
    // The notification ID format is 'reminder_{taskId}'
    final notificationId = 'reminder_$taskId';
    if (state.any((n) => n.id == notificationId)) {
      state = state.where((n) => n.id != notificationId).toList();
      _saveNotifications();
    }
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    _saveNotifications();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    _saveNotifications();
  }

  void clearAll() {
    state = [];
    _saveNotifications();
  }

  // Check tasks for due dates and generate notifications if needed
  void checkReminders(List<Task> tasks) {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.dueDate != null) {
        final notificationId = 'reminder_${task.id}';

        // If task is completed, ensure no notification exists
        if (task.isCompleted) {
          if (state.any((n) => n.id == notificationId)) {
            removeNotificationForTask(task.id);
          }
          continue;
        }

        // If task is due or past due
        if (task.dueDate!.isBefore(now) ||
            task.dueDate!.isAtSameMomentAs(now)) {
          final notificationId = 'reminder_${task.id}';

          // Create the notification item
          final notification = NotificationItem(
            id: notificationId,
            title: 'Task Reminder',
            message: 'It\'s time for: ${task.title}',
            timestamp: task.dueDate!,
            isRead: false,
          );

          // Add it (addNotification handles duplicate check)
          addNotification(notification);
        }
      }
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

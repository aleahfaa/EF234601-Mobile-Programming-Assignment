import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'task.dart';
import 'user_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserPreferences _preferences = UserPreferences();
  Function(String?)? _onNotificationTapped;
  Future<void> initialize() async {
    await Firebase.initializeApp();
    await AwesomeNotifications().initialize('resource://mipmap/ic_launcher', [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Channel for basic notifications',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        defaultPrivacy: NotificationPrivacy.Public,
      ),
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Deadline Reminders',
        channelDescription: 'Channel for task deadline reminders',
        defaultColor: Colors.orange,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        ledColor: Colors.orange,
        defaultPrivacy: NotificationPrivacy.Public,
      ),
      NotificationChannel(
        channelKey: 'completion_channel',
        channelName: 'Completion Notifications',
        channelDescription: 'Channel for task/subtask completion notifications',
        defaultColor: Colors.green,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        ledColor: Colors.green,
        defaultPrivacy: NotificationPrivacy.Public,
      ),
    ]);
    await _requestNotificationPermissions();
    _configureFCM();
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
    );
    print('NotificationService initialized successfully');
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final instance = NotificationService();
    if (instance._onNotificationTapped != null &&
        receivedAction.payload != null &&
        receivedAction.payload!.containsKey('task_id')) {
      instance._onNotificationTapped!(receivedAction.payload!['task_id']);
    }
  }

  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    print('Notification permissions requested');
  }

  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleFCMMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleFCMMessage(message);
    });
    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
    });
  }

  void _handleFCMMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    if (notification != null) {
      final convertedData = data.map<String, String?>(
        (key, value) => MapEntry(key, value?.toString()),
      );
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: notification.title,
          body: notification.body,
          notificationLayout: NotificationLayout.Messaging,
          payload: convertedData,
          summary: 'New message',
        ),
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
    String channelKey = 'basic_channel',
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          category: NotificationCategory.Reminder,
        ),
        actionButtons: [
          NotificationActionButton(key: 'VIEW', label: 'View Task'),
        ],
      );
      print('Notification shown: $title - $body');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? summary,
    Map<String, String>? payload,
    String channelKey = 'basic_channel',
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          summary: summary ?? 'New notification',
          notificationLayout: NotificationLayout.Messaging,
          payload: payload,
          category: NotificationCategory.Message,
        ),
        actionButtons: [NotificationActionButton(key: 'VIEW', label: 'View')],
      );
      print('Message notification shown: $title - $body');
    } catch (e) {
      print('Error showing message notification: $e');
    }
  }

  Future<void> scheduleTaskReminderNotification(Task task) async {
    if (task.deadline == null) return;
    final dueDateTime = task.getFullDueDateTime();
    if (dueDateTime == null) return;
    final notificationMinutes = _preferences.getNotificationTime();
    final scheduledTime = dueDateTime.subtract(
      Duration(minutes: notificationMinutes),
    );
    await cancelTaskNotification(task);
    if (scheduledTime.isAfter(DateTime.now())) {
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: task.id.hashCode,
            channelKey: 'scheduled_channel',
            title: 'Task Reminder: ${task.title}',
            body:
                'Your task "${task.title}" is due in $notificationMinutes minutes',
            summary: 'Deadline approaching',
            notificationLayout: NotificationLayout.Messaging,
            payload: {'task_id': task.id.toString()},
            category: NotificationCategory.Reminder,
          ),
          schedule: NotificationCalendar(
            year: scheduledTime.year,
            month: scheduledTime.month,
            day: scheduledTime.day,
            hour: scheduledTime.hour,
            minute: scheduledTime.minute,
            second: 0,
            millisecond: 0,
            allowWhileIdle: true,
            preciseAlarm: true,
          ),
          actionButtons: [
            NotificationActionButton(key: 'VIEW', label: 'View Task'),
            NotificationActionButton(
              key: 'MARK_COMPLETE',
              label: 'Mark Complete',
            ),
          ],
        );
        print(
          'Scheduled reminder for task ${task.title} at ${scheduledTime.toString()}',
        );
      } catch (e) {
        print('Error scheduling task reminder: $e');
      }
    } else {
      print(
        'Cannot schedule reminder for ${task.title} as the time is in the past',
      );
    }
  }

  Future<void> sendTaskCompletionNotification(Task task) async {
    if (!_preferences.getNotifyOnTaskCompletion()) return;
    await showMessageNotification(
      title: 'Task Completed ✅',
      body: 'You have completed "${task.title}"',
      summary: 'Task completed',
      channelKey: 'completion_channel',
      payload: {'task_id': task.id.toString()},
    );
  }

  Future<void> sendSubtaskCompletionNotification(
    Task task,
    SubTask subtask,
  ) async {
    if (!_preferences.getNotifyOnSubtaskCompletion()) return;
    final completedCount = task.subTasks.where((st) => st.isCompleted).length;
    final totalCount = task.subTasks.length;
    await showMessageNotification(
      title: 'Subtask Completed',
      body:
          'Progress: $completedCount/$totalCount subtasks done in "${task.title}"',
      summary: 'Subtask progress',
      channelKey: 'completion_channel',
      payload: {'task_id': task.id.toString()},
    );
  }

  Future<void> sendAllSubtasksCompletionNotification(Task task) async {
    if (!_preferences.getNotifyOnSubtaskCompletion()) return;
    await showMessageNotification(
      title: 'All Subtasks Completed! 🎉',
      body:
          'You have completed all ${task.subTasks.length} subtasks in "${task.title}"',
      summary: 'All subtasks done',
      channelKey: 'completion_channel',
      payload: {'task_id': task.id.toString()},
    );
  }

  Future<void> cancelTaskNotification(Task task) async {
    try {
      await AwesomeNotifications().cancel(task.id.hashCode);
      print('Cancelled notifications for task ${task.id}');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  void setupNotificationActionListeners(
    Function(String?) onNotificationTapped,
  ) {
    _onNotificationTapped = onNotificationTapped;
    print('Notification action listeners set up');
  }

  void dispose() {
    _onNotificationTapped = null;
  }

  Future<void> showDetailedMessageNotification({
    required String title,
    required String body,
    String? summary,
    String? largeIcon,
    String? bigPicture,
    Map<String, String>? payload,
    String channelKey = 'basic_channel',
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          summary: summary ?? 'New notification',
          largeIcon: largeIcon,
          bigPicture: bigPicture,
          notificationLayout: NotificationLayout.Messaging,
          payload: payload,
          category: NotificationCategory.Message,
          color:
              channelKey == 'completion_channel'
                  ? Colors.green
                  : (channelKey == 'scheduled_channel'
                      ? Colors.orange
                      : Colors.blue),
        ),
        actionButtons: [
          NotificationActionButton(key: 'VIEW', label: 'View'),
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.DismissAction,
          ),
        ],
      );
      print('Detailed message notification shown: $title - $body');
    } catch (e) {
      print('Error showing detailed message notification: $e');
    }
  }
}

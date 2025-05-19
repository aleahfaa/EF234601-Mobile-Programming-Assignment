import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final UserPreferences _instance = UserPreferences._internal();
  factory UserPreferences() => _instance;
  UserPreferences._internal();
  late SharedPreferences _prefs;
  static const String _notificationTimeKey = 'notification_time';
  static const String _notifyTaskCompletionKey = 'notify_task_completion';
  static const String _notifySubtaskCompletionKey = 'notify_subtask_completion';
  static const int _defaultNotificationTime = 30;
  static const bool _defaultNotifyTaskCompletion = true;
  static const bool _defaultNotifySubtaskCompletion = true;
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey(_notificationTimeKey)) {
      await setNotificationTime(_defaultNotificationTime);
    }
    if (!_prefs.containsKey(_notifyTaskCompletionKey)) {
      await setNotifyOnTaskCompletion(_defaultNotifyTaskCompletion);
    }
    if (!_prefs.containsKey(_notifySubtaskCompletionKey)) {
      await setNotifyOnSubtaskCompletion(_defaultNotifySubtaskCompletion);
    }
    print('UserPreferences initialized with:');
    print('- Notification time: ${getNotificationTime()} minutes');
    print('- Notify on task completion: ${getNotifyOnTaskCompletion()}');
    print('- Notify on subtask completion: ${getNotifyOnSubtaskCompletion()}');
  }

  int getNotificationTime() {
    return _prefs.getInt(_notificationTimeKey) ?? _defaultNotificationTime;
  }

  Future<bool> setNotificationTime(int minutes) async {
    print('Setting notification time to $minutes minutes');
    return await _prefs.setInt(_notificationTimeKey, minutes);
  }

  bool getNotifyOnTaskCompletion() {
    return _prefs.getBool(_notifyTaskCompletionKey) ??
        _defaultNotifyTaskCompletion;
  }

  Future<bool> setNotifyOnTaskCompletion(bool value) async {
    print('Setting notify on task completion to $value');
    return await _prefs.setBool(_notifyTaskCompletionKey, value);
  }

  bool getNotifyOnSubtaskCompletion() {
    return _prefs.getBool(_notifySubtaskCompletionKey) ??
        _defaultNotifySubtaskCompletion;
  }

  Future<bool> setNotifyOnSubtaskCompletion(bool value) async {
    print('Setting notify on subtask completion to $value');
    return await _prefs.setBool(_notifySubtaskCompletionKey, value);
  }

  Future<void> resetNotificationPreferences() async {
    await setNotificationTime(_defaultNotificationTime);
    await setNotifyOnTaskCompletion(_defaultNotifyTaskCompletion);
    await setNotifyOnSubtaskCompletion(_defaultNotifySubtaskCompletion);
    print('All notification preferences reset to defaults');
  }
}

import 'package:flutter/material.dart';
import 'user_preferences.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserPreferences _preferences = UserPreferences();
  late int _notificationTime;
  late bool _notifyTaskCompletion;
  late bool _notifySubtaskCompletion;
  final List<int> _notificationTimeOptions = [15, 30, 60, 120];
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _notificationTime = _preferences.getNotificationTime();
      _notifyTaskCompletion = _preferences.getNotifyOnTaskCompletion();
      _notifySubtaskCompletion = _preferences.getNotifyOnSubtaskCompletion();
    });
  }

  String _getNotificationTimeText(int minutes) {
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes minutes';
      }
    } else {
      return '$minutes minutes';
    }
  }

  void _showTestNotification(String type) async {
    switch (type) {
      case 'deadline':
        await notificationService.showMessageNotification(
          title: 'Test Deadline Reminder',
          body: 'This is how your deadline reminders will look ⏰',
          summary: 'Test reminder',
          channelKey: 'scheduled_channel',
        );
        break;
      case 'completion':
        await notificationService.showMessageNotification(
          title: 'Test Completion Notification',
          body: 'This is how your completion notifications will look ✅',
          summary: 'Test completion',
          channelKey: 'completion_channel',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Settings'), elevation: 2),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Customize how and when you receive notifications',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.orange),
                      SizedBox(width: 12),
                      Text(
                        'Deadline Reminders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 0),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remind me before the deadline:'),
                      SizedBox(height: 12),
                      DropdownButton<int>(
                        value: _notificationTime,
                        isExpanded: true,
                        onChanged: (value) async {
                          if (value != null) {
                            await _preferences.setNotificationTime(value);
                            setState(() {
                              _notificationTime = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'You\'ll now be reminded ${_getNotificationTimeText(value)} before deadlines',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        items:
                            _notificationTimeOptions.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(_getNotificationTimeText(value)),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: Icon(Icons.notifications_active),
                        label: Text('Test Deadline Reminder'),
                        onPressed: () => _showTestNotification('deadline'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Completion Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 0),
                SwitchListTile(
                  title: Text('Task Completion'),
                  subtitle: Text('Get notified when you complete a task'),
                  value: _notifyTaskCompletion,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    await _preferences.setNotifyOnTaskCompletion(value);
                    setState(() {
                      _notifyTaskCompletion = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Task completion notifications enabled'
                              : 'Task completion notifications disabled',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  title: Text('Subtask Completion'),
                  subtitle: Text('Get notified when you complete subtasks'),
                  value: _notifySubtaskCompletion,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    await _preferences.setNotifyOnSubtaskCompletion(value);
                    setState(() {
                      _notifySubtaskCompletion = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Subtask completion notifications enabled'
                              : 'Subtask completion notifications disabled',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.notifications_active),
                    label: Text('Test Completion Notification'),
                    onPressed: () => _showTestNotification('completion'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• You\'ll receive deadline reminders ${_getNotificationTimeText(_notificationTime)} before the due time of your tasks',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• ${_notifyTaskCompletion ? "You will" : "You won\'t"} be notified when you complete a task',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• ${_notifySubtaskCompletion ? "You will" : "You won\'t"} be notified about progress on subtasks',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

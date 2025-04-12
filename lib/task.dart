import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Task {
  @Id()
  int id = 0;
  String title;
  String description;
  bool isCompleted;
  DateTime? deadline;
  int? dueTimeMinutes;
  @Transient()
  TimeOfDay? get dueTime {
    if (dueTimeMinutes == null) return null;
    return TimeOfDay(hour: dueTimeMinutes! ~/ 60, minute: dueTimeMinutes! % 60);
  }

  set dueTime(TimeOfDay? time) {
    if (time == null) {
      dueTimeMinutes = null;
    } else {
      dueTimeMinutes = time.hour * 60 + time.minute;
    }
  }

  @Backlink('task')
  final subTasks = ToMany<SubTask>();
  Task({
    this.id = 0,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.deadline,
    TimeOfDay? dueTime,
  }) {
    this.dueTime = dueTime;
  }

  DateTime? getFullDueDateTime() {
    if (deadline == null) return null;
    if (dueTime == null) return deadline;
    return DateTime(
      deadline!.year,
      deadline!.month,
      deadline!.day,
      dueTime!.hour,
      dueTime!.minute,
    );
  }

  String getDueDateString() {
    if (deadline == null) return 'No date';
    return '${deadline!.day}/${deadline!.month}/${deadline!.year}';
  }

  String getDueTimeString() {
    if (dueTime == null) return '';
    final hour = dueTime!.hour.toString().padLeft(2, '0');
    final minute = dueTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

@Entity()
class SubTask {
  @Id()
  int id = 0;
  String title;
  bool isCompleted;
  final task = ToOne<Task>();
  SubTask({required this.title, this.isCompleted = false});
}

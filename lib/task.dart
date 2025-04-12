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
  @Transient()
  TimeOfDay? dueTime;
  @Backlink('task')
  final subTasks = ToMany<SubTask>();
  Task({
    this.id = 0,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.deadline,
    this.dueTime,
  });
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

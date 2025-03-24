import 'package:flutter/material.dart';

class SubTask {
  String id;
  String title;
  bool isCompleted;
  SubTask({required this.title, this.isCompleted = false})
    : id = DateTime.now().millisecondsSinceEpoch.toString();
}

class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? deadline;
  TimeOfDay? dueTime;
  List<SubTask> subTasks;
  Task({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.deadline,
    this.dueTime,
    List<SubTask>? subTasks,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       subTasks = subTasks ?? [];
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

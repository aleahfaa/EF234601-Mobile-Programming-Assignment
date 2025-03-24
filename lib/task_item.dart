import 'package:flutter/material.dart';
import 'task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(String) onEdit;
  final VoidCallback onEditPressed;
  TaskItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isOverdue = false;
    if (!task.isCompleted && task.deadline != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(
        task.deadline!.year,
        task.deadline!.month,
        task.deadline!.day,
      );

      if (dueDate.isBefore(today)) {
        isOverdue = true;
      } else if (dueDate.isAtSameMomentAs(today) && task.dueTime != null) {
        final currentTime = TimeOfDay.now();
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final dueMinutes = task.dueTime!.hour * 60 + task.dueTime!.minute;
        if (dueMinutes < currentMinutes) {
          isOverdue = true;
        }
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                task.isCompleted
                                    ? Colors.grey
                                    : isOverdue
                                    ? Colors.red
                                    : null,
                          ),
                        ),
                      ),
                      if (isOverdue && !task.isCompleted)
                        Tooltip(
                          message: 'Overdue',
                          child: Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                  Row(
                    children: [
                      if (task.deadline != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color:
                              isOverdue && !task.isCompleted
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          task.getDueDateString(),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isOverdue && !task.isCompleted
                                    ? Colors.red
                                    : Colors.grey,
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],

                      if (task.dueTime != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color:
                              isOverdue && !task.isCompleted
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          task.getDueTimeString(),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isOverdue && !task.isCompleted
                                    ? Colors.red
                                    : Colors.grey,
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],

                      if (task.subTasks.isNotEmpty) ...[
                        Icon(Icons.checklist, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '${task.subTasks.where((st) => st.isCompleted).length}/${task.subTasks.length}',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEditPressed,
              tooltip: 'Edit Task',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEditPressed();
                    break;
                  case 'delete':
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: Text('Delete Task'),
                          content: Text(
                            'Are you sure you want to delete "${task.title}"?',
                          ),
                          actions: [
                            TextButton(
                              child: Text('CANCEL'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              child: Text('DELETE'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                onDelete();
                              },
                            ),
                          ],
                        );
                      },
                    );
                    break;
                  case 'toggle':
                    onToggle();
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.refresh : Icons.check,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            task.isCompleted
                                ? 'Mark as incomplete'
                                : 'Mark as complete',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'task.dart';
import 'add_task.dart';

class TaskDetail extends StatelessWidget {
  final Task task;
  final Function(Task) onUpdate;
  final VoidCallback onDelete;

  TaskDetail({
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit Task',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddTask(onAdd: onUpdate, taskToEdit: task),
                    ),
                  )
                  .then((_) {
                    (context as Element).markNeedsBuild();
                  });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Delete Task',
            onPressed: () {
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
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: task.isCompleted ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                task.isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            SizedBox(height: 8),
            Divider(),
            if (task.description.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Description:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 16,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Divider(),
            ],
            if (task.deadline != null || task.dueTime != null) ...[
              Row(
                children: [
                  Icon(Icons.event, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Deadline:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.deadline != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Date: ${task.getDueDateString()}',
                            style: TextStyle(
                              fontSize: 16,
                              decoration:
                                  task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    if (task.deadline != null && task.dueTime != null)
                      SizedBox(height: 4),
                    if (task.dueTime != null)
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Time: ${task.getDueTimeString()}',
                            style: TextStyle(
                              fontSize: 16,
                              decoration:
                                  task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(),
            ],
            if (task.subTasks.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.checklist, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Sub-Tasks (${task.subTasks.where((st) => st.isCompleted).length}/${task.subTasks.length}):',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children:
                      task.subTasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subTask = entry.value;
                        return CheckboxListTile(
                          title: Text(
                            subTask.title,
                            style: TextStyle(
                              decoration:
                                  subTask.isCompleted || task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                          value: subTask.isCompleted,
                          activeColor: Colors.green,
                          onChanged:
                              task.isCompleted
                                  ? null
                                  : (bool? value) {
                                    if (value != null) {
                                      final updatedSubTasks =
                                          List<SubTask>.from(task.subTasks);
                                      updatedSubTasks[index].isCompleted =
                                          value;

                                      final updatedTask = Task(
                                        id: task.id,
                                        title: task.title,
                                        description: task.description,
                                        isCompleted: task.isCompleted,
                                        deadline: task.deadline,
                                        dueTime: task.dueTime,
                                        subTasks: updatedSubTasks,
                                      );
                                      onUpdate(updatedTask);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            value
                                                ? 'Sub-task marked as completed'
                                                : 'Sub-task marked as incomplete',
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                        );
                      }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(task.isCompleted ? Icons.refresh : Icons.check),
        label: Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
        backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
        onPressed: () {
          final List<SubTask> updatedSubTasks =
              task.subTasks.map((subTask) {
                if (!task.isCompleted) {
                  return SubTask(title: subTask.title, isCompleted: true);
                }
                return SubTask(
                  title: subTask.title,
                  isCompleted: subTask.isCompleted,
                );
              }).toList();

          final updatedTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: !task.isCompleted,
            deadline: task.deadline,
            dueTime: task.dueTime,
            subTasks: updatedSubTasks,
          );
          onUpdate(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updatedTask.isCompleted
                    ? 'Task "${task.title}" marked as completed'
                    : 'Task "${task.title}" marked as incomplete',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'task.dart';
import 'add_task.dart';
import 'task_item.dart';
import 'task_detail.dart';

class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<Task> tasks = [];
  void addTask(Task task) {
    setState(() {
      tasks.add(task);
      _sortTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" added'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                tasks.removeWhere((t) => t.id == task.id);
              });
            },
          ),
        ),
      );
    });
  }

  void updateTask(Task updatedTask) {
    setState(() {
      final index = tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        final oldTask = tasks[index];
        tasks[index] = updatedTask;
        _sortTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${updatedTask.title}" updated'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                setState(() {
                  tasks[tasks.indexWhere((task) => task.id == updatedTask.id)] =
                      oldTask;
                  _sortTasks();
                });
              },
            ),
          ),
        );
      }
    });
  }

  void deleteTask(String taskId) {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final deletedTask = tasks[index];

    setState(() {
      tasks.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${deletedTask.title}" deleted'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                tasks.add(deletedTask);
                _sortTasks();
              });
            },
          ),
        ),
      );
    });
  }

  void toggleTaskCompletion(String taskId) {
    setState(() {
      final index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final updatedTask = tasks[index];
        updatedTask.isCompleted = !updatedTask.isCompleted;
        if (updatedTask.isCompleted) {
          for (var subTask in updatedTask.subTasks) {
            subTask.isCompleted = true;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedTask.isCompleted
                  ? 'Task "${updatedTask.title}" completed'
                  : 'Task "${updatedTask.title}" marked as incomplete',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _sortTasks() {
    tasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      final dateComparison = a.deadline!.compareTo(b.deadline!);
      if (dateComparison != 0) return dateComparison;
      if (a.dueTime == null && b.dueTime == null) return 0;
      if (a.dueTime == null) return 1;
      if (b.dueTime == null) return -1;
      final aMinutes = a.dueTime!.hour * 60 + a.dueTime!.minute;
      final bMinutes = b.dueTime!.hour * 60 + b.dueTime!.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  Map<String, List<Task>> _getGroupedTasks() {
    final Map<String, List<Task>> grouped = {};
    grouped['No date'] = [];
    grouped['Completed'] = [];
    for (final task in tasks) {
      if (task.isCompleted) {
        grouped['Completed']!.add(task);
        continue;
      }
      final key =
          task.deadline == null
              ? 'No date'
              : '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTasks = _getGroupedTasks();
    final sortedDates =
        groupedTasks.keys.toList()..sort((a, b) {
          if (a == 'Completed') return 1;
          if (b == 'Completed') return -1;
          if (a == 'No date') return 1;
          if (b == 'No date') return -1;

          final aParts = a.split('/').map(int.parse).toList();
          final bParts = b.split('/').map(int.parse).toList();
          final aDate = DateTime(aParts[2], aParts[1], aParts[0]);
          final bDate = DateTime(bParts[2], bParts[1], bParts[0]);
          return aDate.compareTo(bDate);
        });

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Search feature coming soon')),
              );
            },
          ),
        ],
      ),
      body:
          tasks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tasks yet. Add some!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add New Task'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddTask(onAdd: addTask),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, groupIndex) {
                  final dateKey = sortedDates[groupIndex];
                  final tasksInGroup = groupedTasks[dateKey]!;
                  if (tasksInGroup.isEmpty) return SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              dateKey,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    dateKey == 'Completed'
                                        ? Colors.green
                                        : null,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('(${tasksInGroup.length})'),
                          ],
                        ),
                      ),
                      ...tasksInGroup
                          .map(
                            (task) => GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => TaskDetail(
                                          task: task,
                                          onUpdate: updateTask,
                                          onDelete: () => deleteTask(task.id),
                                        ),
                                  ),
                                );
                              },
                              child: TaskItem(
                                task: task,
                                onToggle: () => toggleTaskCompletion(task.id),
                                onDelete: () => deleteTask(task.id),
                                onEdit: (title) {
                                  final updatedTask = Task(
                                    id: task.id,
                                    title: title,
                                    description: task.description,
                                    isCompleted: task.isCompleted,
                                    deadline: task.deadline,
                                    dueTime: task.dueTime,
                                    subTasks: task.subTasks,
                                  );
                                  updateTask(updatedTask);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddTask(onAdd: addTask)),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add New Task',
      ),
    );
  }
}

import 'package:assignment1/main.dart';
import 'package:flutter/material.dart';
import 'task.dart';
import 'add_task.dart';
import 'task_item.dart';
import 'task_detail.dart';

class TaskList extends StatefulWidget {
  TaskList();
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<Task> tasks = [];
  @override
  void initState() {
    _loadTasks();
    super.initState();
  }

  Future<void> _loadTasks() async {
    final taskBox = objectBox.store.box<Task>();
    tasks = taskBox.getAll();
    setState(() {});
  }

  void addTask(Task task) {
    print(objectBox);
    final taskBox = objectBox.store.box<Task>();
    taskBox.put(task);
    _loadTasks();
  }

  void updateTask(Task updatedTask) {
    print("Update Called");
    print("ID: ${updatedTask.id}");
    print("Title: ${updatedTask.title}");
    print("Desc: ${updatedTask.description}");
    print("isCompleted: ${updatedTask.isCompleted}");
    final taskBox = objectBox.store.box<Task>();
    if (updatedTask.id == 0) {
      print(
        "[ERROR] Task ID is 0, tidak bisa update. Data baru akan ditambahkan!",
      );
    } else {
      final exists = taskBox.contains(updatedTask.id);
      if (exists) {
        taskBox.put(updatedTask);
        print("[SUCCESS] Task updated di database.");
      } else {
        print(
          "[WARNING] ID ${updatedTask.id} tidak ditemukan di DB. Data baru akan ditambahkan.",
        );
        taskBox.put(updatedTask);
      }
    }
    _loadTasks();
  }

  void deleteTask(int taskId) {
    final taskBox = objectBox.store.box<Task>();
    taskBox.remove(taskId);
    _loadTasks();
  }

  void toggleTaskCompletion(int taskId) {
    final taskBox = objectBox.store.box<Task>();
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedTask = tasks[index];
      updatedTask.isCompleted = !updatedTask.isCompleted;
      taskBox.put(updatedTask);
      _loadTasks();
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
  }

  void editTask(Task task) {
    print("Edit Task");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                AddTask(onAdd: (task) => updateTask(task), taskToEdit: task),
      ),
    );
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
                                          key: ValueKey(task.id),
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
                                    title: title,
                                    description: task.description,
                                    isCompleted: task.isCompleted,
                                    deadline: task.deadline,
                                    dueTime: task.dueTime,
                                  );
                                  updatedTask.id = task.id;
                                  print("ON EDIT presen");
                                  updateTask(updatedTask);
                                },
                                onEditPressed: () {
                                  print("ON EDIT task");
                                  print(task.id);

                                  editTask(task);
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

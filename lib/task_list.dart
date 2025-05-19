import 'package:flutter/material.dart';
import 'package:todolist/main.dart';
import 'task.dart';
import 'add_task.dart';
import 'task_detail.dart';
import 'task_search_delegate.dart';
import 'settings_screen.dart';
import 'task_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  String searchQuery = '';
  Map<int, List<bool>> _previousSubtaskStates = {};
  @override
  void initState() {
    _loadTasks();
    _setupNotificationListeners();
    super.initState();
  }

  @override
  void dispose() {
    notificationService.dispose();
    super.dispose();
  }

  void _setupNotificationListeners() {
    notificationService.setupNotificationActionListeners((taskId) {
      if (taskId != null) {
        _openTaskFromNotification(int.parse(taskId));
      }
    });
  }

  void _openTaskFromNotification(int taskId) {
    try {
      final task = tasks.firstWhere((task) => task.id == taskId);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => TaskDetail(
                key: ValueKey(task.id),
                task: task,
                onUpdate: updateTask,
                onDelete: () => deleteTask(task.id),
                previousSubtaskStates: _previousSubtaskStates,
                onSubtaskStatesChanged: (taskId, states) {
                  setState(() {
                    _previousSubtaskStates[taskId] = states;
                  });
                },
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task not found')));
    }
  }

  Future<void> _loadTasks() async {
    final taskBox = objectBox.store.box<Task>();
    setState(() {
      tasks = taskBox.getAll();
      filteredTasks = tasks;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredTasks =
          tasks.where((task) {
            return task.title.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
    });
  }

  Future<void> addTask(Task task) async {
    final taskBox = objectBox.store.box<Task>();
    taskBox.put(task);
    await _loadTasks();
    if (task.deadline != null) {
      await notificationService.scheduleTaskReminderNotification(task);
    }
  }

  Future<void> updateTask(Task newTask) async {
    final taskBox = objectBox.store.box<Task>();
    final oldTaskIndex = tasks.indexWhere((t) => t.id == newTask.id);
    if (oldTaskIndex != -1) {
      final oldTask = tasks[oldTaskIndex];
      final wasCompleted = oldTask.isCompleted;
      final oldSubtasks = List<SubTask>.from(oldTask.subTasks);
      oldTask.title = newTask.title;
      oldTask.description = newTask.description;
      oldTask.deadline = newTask.deadline;
      oldTask.dueTime = newTask.dueTime;
      oldTask.isCompleted = newTask.isCompleted;
      oldTask.subTasks.clear();
      oldTask.subTasks.addAll(newTask.subTasks);
      taskBox.put(oldTask);
      await _loadTasks();
      if (!wasCompleted && newTask.isCompleted) {
        await notificationService.sendTaskCompletionNotification(newTask);
      }
      if (newTask.subTasks.isNotEmpty &&
          newTask.subTasks.every((subtask) => subtask.isCompleted) &&
          !oldSubtasks.every((subtask) => subtask.isCompleted)) {
        await notificationService.sendAllSubtasksCompletionNotification(
          newTask,
        );
      }
      if (newTask.deadline != null) {
        await notificationService.scheduleTaskReminderNotification(newTask);
      } else {
        await notificationService.cancelTaskNotification(newTask);
      }
    }
  }

  void deleteTask(int taskId) {
    final taskBox = objectBox.store.box<Task>();
    final deletedTaskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (deletedTaskIndex != -1) {
      final deletedTask = tasks[deletedTaskIndex];
      notificationService.cancelTaskNotification(deletedTask);
      taskBox.remove(taskId);
      _loadTasks();
      _previousSubtaskStates.remove(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${deletedTask.title}" deleted'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              final taskBox = objectBox.store.box<Task>();
              taskBox.put(deletedTask);
              _loadTasks();
              if (deletedTask.deadline != null) {
                notificationService.scheduleTaskReminderNotification(
                  deletedTask,
                );
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    final taskBox = objectBox.store.box<Task>();
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedTask = tasks[index];
      final wasCompleted = updatedTask.isCompleted;
      if (!wasCompleted) {
        _previousSubtaskStates[taskId] =
            updatedTask.subTasks.map((subtask) => subtask.isCompleted).toList();
        updatedTask.isCompleted = true;
        for (var subtask in updatedTask.subTasks) {
          subtask.isCompleted = true;
        }
      } else {
        updatedTask.isCompleted = false;
        if (_previousSubtaskStates.containsKey(taskId)) {
          final previousStates = _previousSubtaskStates[taskId]!;
          for (
            int i = 0;
            i < updatedTask.subTasks.length && i < previousStates.length;
            i++
          ) {
            updatedTask.subTasks[i].isCompleted = previousStates[i];
          }
          _previousSubtaskStates.remove(taskId);
        }
      }
      taskBox.put(updatedTask);
      await _loadTasks();
      if (!wasCompleted && updatedTask.isCompleted) {
        await notificationService.sendTaskCompletionNotification(updatedTask);
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
  }

  Future<void> toggleSubtaskCompletion(Task task, int subtaskIndex) async {
    final subtask = task.subTasks[subtaskIndex];
    final wasCompleted = subtask.isCompleted;
    subtask.isCompleted = !subtask.isCompleted;
    await updateTask(task);
    if (!wasCompleted && subtask.isCompleted) {
      await notificationService.sendSubtaskCompletionNotification(
        task,
        subtask,
      );
    }
    if (task.subTasks.every((st) => st.isCompleted)) {
      await notificationService.sendAllSubtasksCompletionNotification(task);
    }
  }

  void editTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                AddTask(onAdd: (task) => updateTask(task), taskToEdit: task),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
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
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(
                  tasks: tasks,
                  onSearch: _updateSearchQuery,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
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
                            ...tasksInGroup.map(
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
                                            previousSubtaskStates:
                                                _previousSubtaskStates,
                                            onSubtaskStatesChanged: (
                                              taskId,
                                              states,
                                            ) {
                                              setState(() {
                                                _previousSubtaskStates[taskId] =
                                                    states;
                                              });
                                            },
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
                                    updateTask(updatedTask);
                                  },
                                  onEditPressed: () {
                                    editTask(task);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddTask(onAdd: addTask)),
          );
        },
        tooltip: 'Add New Task',
        child: Icon(Icons.add),
      ),
    );
  }
}

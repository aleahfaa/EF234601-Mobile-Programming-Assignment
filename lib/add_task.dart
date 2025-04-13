import 'package:flutter/material.dart';
import 'task.dart';

class AddTask extends StatefulWidget {
  final Function(Task) onAdd;
  final Task? taskToEdit;
  AddTask({required this.onAdd, this.taskToEdit});
  @override
  _AddTaskState createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _subTaskController;
  DateTime? _deadline;
  TimeOfDay? _dueTime;
  List<SubTask> _subTasks = [];
  bool _isEditing = false;
  String? _taskId;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _subTaskController = TextEditingController();
    if (widget.taskToEdit != null) {
      _isEditing = true;
      _taskId = widget.taskToEdit!.id.toString();
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _deadline = widget.taskToEdit!.deadline;
      _dueTime = widget.taskToEdit!.dueTime;
      _subTasks = List.from(widget.taskToEdit!.subTasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _addSubTask(String title) {
    if (title.isEmpty) return;
    setState(() {
      _subTasks.add(SubTask(title: title));
      _subTaskController.clear();
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  void _toggleSubTaskCompletion(int index) {
    setState(() {
      _subTasks[index].isCompleted = !_subTasks[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _deadline = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _deadline == null
                            ? 'Select Date'
                            : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _dueTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _dueTime = pickedTime;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Time (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dueTime == null
                            ? 'Select Time'
                            : '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sub-Tasks (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_deadline != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _deadline = null;
                        _dueTime = null;
                      });
                    },
                    child: Text('Clear Deadline'),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: InputDecoration(
                      labelText: 'Add Sub-task',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _addSubTask(value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addSubTask(_subTaskController.text);
                  },
                  child: Icon(Icons.add),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_subTasks.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _subTasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _subTasks[index].title,
                        style: TextStyle(
                          decoration:
                              _subTasks[index].isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: _subTasks[index].isCompleted,
                        onChanged: (_) => _toggleSubTaskCompletion(index),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSubTask(index),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_titleController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task title cannot be empty')),
            );
            return;
          }
          final task = Task(
            id: _isEditing ? widget.taskToEdit!.id : 0,
            title: _titleController.text,
            description: _descriptionController.text,
            deadline: _deadline,
            dueTime: _dueTime,
            isCompleted: _isEditing ? widget.taskToEdit!.isCompleted : false,
          );
          task.subTasks.addAll(_subTasks);
          widget.onAdd(task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Task updated successfully'
                    : 'Task added successfully',
              ),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        },
        child: Icon(Icons.save),
        tooltip: _isEditing ? 'Update Task' : 'Save Task',
      ),
    );
  }
}

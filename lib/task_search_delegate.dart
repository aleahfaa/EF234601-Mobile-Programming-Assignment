import 'package:flutter/material.dart';
import 'task.dart';
import 'task_detail.dart';

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final Function(String) onSearch;
  TaskSearchDelegate({required this.tasks, required this.onSearch});
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredTasks =
        tasks.where((task) {
          return task.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return ListTile(
          title: Text(task.title),
          onTap: () {
            close(context, null);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => TaskDetail(
                      task: task,
                      onUpdate: (updatedTask) {},
                      onDelete: () {},
                    ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        tasks.where((task) {
          return task.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final task = suggestions[index];
        return ListTile(
          title: Text(task.title),
          onTap: () {
            close(context, null);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => TaskDetail(
                      task: task,
                      onUpdate: (updatedTask) {},
                      onDelete: () {},
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

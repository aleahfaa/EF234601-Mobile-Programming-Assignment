import 'package:flutter/material.dart';
import 'task_list.dart';
import 'objectbox.dart';

late ObjectBox objectBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primaryColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(centerTitle: true),
      ),
      home: TaskList(),
    );
  }
}

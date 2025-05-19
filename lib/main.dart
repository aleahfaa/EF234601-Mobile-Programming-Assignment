import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_list.dart';
import 'objectbox.dart';
import 'notification_service.dart';
import 'user_preferences.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'firebase_options.dart';

late ObjectBox objectBox;
final notificationService = NotificationService();
final userPreferences = UserPreferences();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  objectBox = await ObjectBox.create();
  await notificationService.initialize();
  await userPreferences.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        'register':
            (context) => SignupScreen(
              onSignupSuccess: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskList()),
                );
              },
            ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _handleLoginSuccess() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (FirebaseAuth.instance.currentUser != null) {
      return const TaskList();
    } else {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }
  }
}

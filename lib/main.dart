import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiddensig/view/login_view.dart';
import 'package:hiddensig/view/register_view.dart';
import 'package:hiddensig/view/message_board_view.dart';
import 'package:hiddensig/view/profile_creation_view.dart';
import 'package:hiddensig/custom_bottom_navigation_bar.dart';
import 'package:hiddensig/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiddenSig',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
        primaryColor: Colors.grey.shade900,
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(
          color: Colors.grey.shade900,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          return Builder(
            builder: (newContext) {
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                if (user == null) {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushReplacementNamed(newContext, '/login');
                  });
                } else {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushReplacementNamed(newContext, '/bottom');
                  });
                }
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginView(),
        '/register': (context) => const RegisterView(),
        '/message_board': (context) => const MessageBoardView(),
        '/profile_creation': (context) => const ProfileCreationView(),
        '/bottom': (context) => const HomeScreen(),
      },
    );
  }
}

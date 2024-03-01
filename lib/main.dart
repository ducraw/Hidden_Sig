import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiddensig/view/login_view.dart';
import 'package:hiddensig/view/register_view.dart';
import 'package:hiddensig/view/message_board_view.dart';
import 'package:hiddensig/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiddenSig',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          // Use a Builder to get a context that is below the MaterialApp.
          return Builder(
            builder: (newContext) {
              // Use newContext for Navigator
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                if (user == null) {
                  // Use Future.delayed to ensure the context is built
                  Future.delayed(Duration.zero, () {
                    Navigator.pushReplacementNamed(newContext, '/login');
                  });
                } else {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushReplacementNamed(
                        newContext, '/message_board');
                  });
                }
                // Return a placeholder to handle the brief period before navigation.
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // Default loading state
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        },
      ),
      routes: {
        '/login': (context) => LoginView(),
        '/register': (context) => RegisterView(),
        '/message_board': (context) => MessageBoardView(),
        // Add more routes as needed
      },
    );
  }
}

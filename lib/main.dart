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
  ); // Initialize Firebase
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
        // Set the primarySwatch to Colors.grey as ThemeData doesn't have a black swatch.
        // You can define your own swatch if needed.
        primarySwatch: Colors.grey,
        brightness: Brightness.dark, // Set the brightness to dark
        primaryColor:
            Colors.grey.shade900, // Set the primary color to grey shade 800
        scaffoldBackgroundColor: Colors.grey
            .shade900, // Set the scaffold background color to grey shade 800
        appBarTheme: AppBarTheme(
          color: Colors.grey.shade900, // Set the AppBar color to grey shade 800
          iconTheme: IconThemeData(
              color: Colors.white), // Set AppBar icons color to white
        ),
        textTheme: TextTheme(
          bodyText2: TextStyle(
              color: Colors.white), // Set the default body text color to white
        ),
        // You can customize additional theme attributes as needed
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
                    Navigator.pushReplacementNamed(newContext, '/bottom');
                  });
                }
                // Return a placeholder to handle the brief period before navigation.
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // Default loading state
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

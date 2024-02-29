import 'package:flutter/material.dart';
import 'package:hiddensig/view/login_view.dart';
import 'package:hiddensig/view/register_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiddenSig',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginView(),
        '/register': (context) => RegisterView(),
        // Add more routes as needed
      },
    );
  }
}

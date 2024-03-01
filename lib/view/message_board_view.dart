import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageBoardView extends StatefulWidget {
  const MessageBoardView({Key? key}) : super(key: key);

  @override
  State<MessageBoardView> createState() => _MessageBoardViewState();
}

class _MessageBoardViewState extends State<MessageBoardView> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Love is True'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Love is True',
          style: TextStyle(
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hiddensig/view/message_board_view.dart';
import 'package:hiddensig/view/message_board_view_global.dart';
import 'package:hiddensig/view/profile_edit_view.dart';
import 'package:hiddensig/view/message_creation_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Define your views here
  final List<Widget> _widgetOptions = <Widget>[
    const MessageBoardView(),
    const MessageBoardViewGlobal(),
    const MessageCreationPage(),
    const EditProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Your Board',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Global Board',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create_outlined),
            label: 'Write Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Edit Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            Colors.white, // Change the color of the selected item
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

void main() {
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}

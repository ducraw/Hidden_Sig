import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiddensig/view/message_board_view.dart';
import 'package:hiddensig/view/message_board_view_global.dart';
import 'package:hiddensig/view/profile_edit_view.dart';
import 'package:hiddensig/view/message_creation_page.dart';
import 'package:hiddensig/view/payment.dart';

void main() {
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  final List<Widget> _widgetOptions = <Widget>[
    const MessageBoardView(),
    const MessageBoardViewGlobal(),
    const MessageCreationPage(),
    const EditProfileView(),
    const PaymentPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Payment',
          ),
        ],
        currentIndex: _selectedIndex,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 2) {
        _checkInvoice();
      } else {
        _selectedIndex = index;
      }
    });
  }

  Future<void> _checkInvoice() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/get_invoice/${_user!.uid}'),
      );

      if (response.statusCode == 200) {
        final invoices = jsonDecode(response.body) as List<dynamic>;
        if (invoices.isNotEmpty) {
          setState(() {
            _selectedIndex = 2; // Navigate to MessageCreationPage
          });
        } else {
          _showSnackbar('You need to have an invoice to access this page');
        }
      } else {
        print('Failed to load invoice information');
        _showSnackbar('Failed to load invoice information');
      }
    } catch (error) {
      print('Failed to load invoice information: $error');
      _showSnackbar('Failed to load invoice information');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

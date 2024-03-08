import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_creation_page.dart';

class MessageBoardView extends StatefulWidget {
  const MessageBoardView({Key? key}) : super(key: key);

  @override
  State<MessageBoardView> createState() => _MessageBoardViewState();
}

class _MessageBoardViewState extends State<MessageBoardView> {
  late User? _user;
  late CollectionReference _messagesCollection;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _messagesCollection = FirebaseFirestore.instance.collection('messages');
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _removeMessage(String messageId) async {
    await _messagesCollection.doc(messageId).delete();
  }

  Future<void> _updateClicksRemain(
      String messageId, List<dynamic> hiddenTextInfo, int infoIndex) async {
    print(infoIndex);
    try {
      // Reduce clicksRemain by 1
      hiddenTextInfo[infoIndex]['clicksRemain'] -= 1;

      await _messagesCollection.doc(messageId).update({
        'hiddenTextInfo': hiddenTextInfo,
      });
      print('TotalClicksRemain updated successfully in the database');
    } catch (e) {
      print('Error updating totalClicksRemain in the database: $e');
    }
  }

  Future<void> _updateTotalClicksRemainInDatabase(
      String messageId, int newTotalClicksRemain) async {
    try {
      await _messagesCollection.doc(messageId).update({
        'totalClicksRemain': newTotalClicksRemain,
      });
      print('TotalClicksRemain updated successfully in the database');
    } catch (e) {
      print('Error updating totalClicksRemain in the database: $e');
    }
  }

  Future<void> _updateHiddenInputTextInDatabase(
      String messageId, String updatedHiddenInputText) async {
    try {
      await _messagesCollection.doc(messageId).update({
        'hiddenInputTextUpdate': updatedHiddenInputText,
      });
      print('HiddenInputText updated successfully in the database');
    } catch (e) {
      print('Error updating hiddenInputText in the database: $e');
    }
  }

  Widget _buildHiddenInputButtons(
    List<dynamic> hiddenTextInfo,
    String messageId,
    List<String> hiddenInputText,
    List<String> inputTextFromDatabase,
    int totalClicksRemain, // Define totalClicksRemain here
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List.generate(hiddenInputText.length, (index) {
        if (hiddenInputText[index].trim().isNotEmpty) {
          final isHidden =
              inputTextFromDatabase.contains(hiddenInputText[index]);
          return ElevatedButton(
            onPressed: isHidden
                ? null
                : () {
                    setState(() {
                      int currentLocation = index + 1;
                      int infoIndex = hiddenTextInfo.indexWhere(
                        (info) => info['location'] == currentLocation,
                      );

                      if (infoIndex != -1) {
                        _updateClicksRemain(
                            messageId, hiddenTextInfo, infoIndex);
                        // Update totalClicksRemain in firestore
                        _updateTotalClicksRemainInDatabase(
                            messageId, totalClicksRemain - 1);

                        // If clicksRemain reaches 0, do the normal onPressed event
                        if (hiddenTextInfo[infoIndex]['clicksRemain'] == 0) {
                          hiddenInputText[index] =
                              hiddenTextInfo[infoIndex]['word'];
                          _updateHiddenInputTextInDatabase(
                              messageId, hiddenInputText.join(' '));
                        }
                      }
                    });
                  },
            child: Text(hiddenInputText[index]),
          );
        } else {
          return SizedBox.shrink();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _messagesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageData = message.data() as Map<String, dynamic>;
              final List<dynamic> hiddenTextInfo =
                  messageData['hiddenTextInfo'] ?? [];
              final List<String> hiddenInputText =
                  (messageData['hiddenInputTextUpdate'] as String).split(' ');
              final List<String> inputTextFromDatabase =
                  (messageData['inputText'] as String).split(' ');
              final int totalClicksRemain =
                  messageData['totalClicksRemain'] ?? 0; // Fetch from database

              return Container(
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Message ${index + 1}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _removeMessage(message.id);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildHiddenInputButtons(
                        hiddenTextInfo,
                        message.id,
                        hiddenInputText,
                        inputTextFromDatabase,
                        totalClicksRemain, // Pass totalClicksRemain here
                      ),
                    ),
                    Divider(color: Colors.grey),
                    Text(
                        'totalClicksRemain: $totalClicksRemain'), // Show totalClicksRemain
                    Text(
                        'Hidden Text Count: ${messageData['hiddenTextCount']}'),
                    Text(
                        'Remain Hidden Text Count: ${messageData['remainHiddenTextCount']}'),
                    Text('Hidden Text Info: ${hiddenTextInfo.toString()}'),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MessageCreationPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

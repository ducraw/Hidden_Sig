import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'all_comments_page.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class MessageBoardViewGlobal extends StatefulWidget {
  const MessageBoardViewGlobal({Key? key}) : super(key: key);

  @override
  State<MessageBoardViewGlobal> createState() => _MessageBoardViewGlobalState();
}

class _MessageBoardViewGlobalState extends State<MessageBoardViewGlobal> {
  //late final CollectionReference<Map<String, dynamic>> _messagesCollection;
  //late final CollectionReference<Map<String, dynamic>> _userInfoCollection;
  final Map<String, TextEditingController> _commentControllers = {};
  final ScrollController _scrollController = ScrollController();
  double _savedScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    //_messagesCollection = FirebaseFirestore.instance.collection('messages');
    //_userInfoCollection = FirebaseFirestore.instance.collection('userInfo');
    _scrollController.addListener(_saveScrollPosition);
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/api/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load user information');
      }
    } catch (error) {
      throw Exception('Failed to load user information: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessageInfo() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/api/messages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> messages =
            List<Map<String, dynamic>>.from(data);
        return messages;
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (error) {
      throw Exception('Failed to load messages: $error');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    _savedScrollOffset = _scrollController.offset;
  }

  Future<void> _signOut(NavigatorState navigatorState) async {
    await FirebaseAuth.instance.signOut();
    navigatorState.pushReplacementNamed('/login');
  }

  Future<void> _removeMessage(String messageId, String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.uid == userId) {
        //final token = await currentUser.getIdToken();

        final response = await http.delete(
          Uri.parse('http://10.0.2.2:3000/api/messages/$messageId/$userId'),
        );
        int a = response.statusCode;
        String b = currentUser.uid;
        String c = userId;
        if (response.statusCode == 200) {
          // Message deleted successfully
        } else {
          developer.log('Error deleting message: $a');
          developer.log('Error deleting message: $b , $c');
        }
      } else {
        developer.log('Error  message');
      }
    } catch (e) {
      developer.log('Error deleting message: $e');
    }
  }

  Future<void> _likeComment(String messageId, int commentIndex) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:3000/api/messages/$messageId/comments/$commentIndex/like'),
      );
      if (response.statusCode == 200) {
        // Comment liked successfully
      } else {
        // Handle error
      }
    } catch (e) {
      print('Error liking comment: $e');
    }
  }

  Future<void> _addComment(String messageId, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/messages/$messageId/comments'),
        body: jsonEncode({'text': comment, 'likes': 0}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 201) {
        // Comment added successfully
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle network error
    }
  }

  Future<void> _updateClicksRemain(
      String messageId, List<dynamic> hiddenTextInfo, int infoIndex) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:3000/api/messages/$messageId/updateClicksRemain'),
        body: jsonEncode({
          'hiddenTextInfo': hiddenTextInfo,
          'infoIndex': infoIndex,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        // Clicks remain updated successfully
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _updateHiddenInputTextInDatabase(
      String messageId, String updatedHiddenInputText) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:3000/api/messages/$messageId/updateHiddenInputText'),
        body: jsonEncode({
          'updatedHiddenInputText': updatedHiddenInputText,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('Hidden input text updated successfully');
      } else {
        print('Failed to update hidden input text');
      }
    } catch (e) {
      print('Error updating hidden input text: $e');
    }
  }

  Future<void> _updateTotalClicksRemainInDatabase(
      String messageId, int newTotalClicksRemain) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:3000/api/messages/$messageId/updateTotalClicksRemain'),
        body: jsonEncode({
          'newTotalClicksRemain': newTotalClicksRemain,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('Total clicks remain updated successfully');
      } else {
        print('Failed to update total clicks remain');
      }
    } catch (e) {
      print('Error updating total clicks remain: $e');
    }
  }

  Widget _buildHiddenInputButtons(
    List<dynamic> hiddenTextInfo,
    String messageId,
    List<String> hiddenInputText,
    List<String> inputTextFromDatabase,
    int totalClicksRemain,
  ) {
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: List.generate(hiddenInputText.length, (index) {
        if (hiddenInputText[index].trim().isNotEmpty) {
          final isHidden =
              inputTextFromDatabase.contains(hiddenInputText[index]);

          final textPainter = TextPainter(
            text: TextSpan(
              text: hiddenInputText[index],
              style: const TextStyle(fontSize: 16.0),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final infoIndex = hiddenTextInfo
              .indexWhere((info) => info['location'] == index + 1);

          return SizedBox(
            width: textPainter.width + 1.5,
            height: 25,
            child: InkWell(
              onTap: isHidden
                  ? null
                  : () {
                      {
                        if (infoIndex != -1) {
                          _updateClicksRemain(
                              messageId, hiddenTextInfo, infoIndex);
                          _updateTotalClicksRemainInDatabase(
                              messageId, totalClicksRemain - 1);
                          if (hiddenTextInfo[infoIndex]['clicksRemain'] <= 1) {
                            hiddenInputText[index] =
                                hiddenTextInfo[infoIndex]['word'];
                            _updateHiddenInputTextInDatabase(
                                messageId, hiddenInputText.join(' '));
                          }
                        }
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Stack(
                  children: [
                    Text(
                      hiddenInputText[index],
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    if (!isHidden && infoIndex != -1)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: Text(
                          '${hiddenTextInfo[infoIndex]['clicksRemain']}',
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Message Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Trigger refresh logic here
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _signOut(Navigator.of(context));
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: fetchMessageInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final messages = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(_savedScrollOffset);
          });

          return ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageData = message;

              final messageId = message['docId'];
              final List<dynamic> hiddenTextInfo =
                  messageData['hiddenTextInfo'] ?? [];
              final List<String> hiddenInputText =
                  (messageData['hiddenInputTextUpdate'] as String).split(' ');
              final List<String> inputTextFromDatabase =
                  (messageData['inputText'] as String).split(' ');
              final int totalClicksRemain =
                  messageData['totalClicksRemain'] ?? 0;

              if (!_commentControllers.containsKey(messageId)) {
                _commentControllers[messageId] = TextEditingController();
              }

              final TextEditingController commentController =
                  _commentControllers[messageId]!;

              List<Map<String, dynamic>> comments = [];

              if (messageData['comments'] != null) {
                comments = (messageData['comments'] as List)
                    .cast<Map<String, dynamic>>();
              }

              comments.sort(
                  (a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

              final limitedComments =
                  comments.length > 3 ? comments.sublist(0, 3) : comments;
              return FutureBuilder(
                future: fetchUserInfo(messageData['userId']),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }

                  final userData = userSnapshot.data!;
                  final profileImageUrl = userData['imageUrl'] as String;
                  final displayName = userData['displayName'] as String;
                  final currentUser = FirebaseAuth.instance.currentUser;

                  bool isUploader = currentUser != null &&
                      currentUser.uid == messageData['userId'];

                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(displayName),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl),
                          ),
                          trailing: isUploader
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _removeMessage(
                                        messageId, messageData['userId']);
                                    setState(() {});
                                  },
                                )
                              : const SizedBox(),
                        ),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildHiddenInputButtons(
                              hiddenTextInfo,
                              messageId,
                              hiddenInputText,
                              inputTextFromDatabase,
                              totalClicksRemain,
                            )),
                        if (limitedComments.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Comments:'),
                              for (int i = 0; i < limitedComments.length; i++)
                                ListTile(
                                  title: Text(limitedComments[i]['text']),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                          'Likes: ${limitedComments[i]['likes']}'),
                                      IconButton(
                                        icon: const Icon(Icons.thumb_up),
                                        onPressed: () {
                                          _likeComment(messageId, i);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        if (comments.length > 3)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllCommentsPage(
                                    comments: comments,
                                    messageId: messageId,
                                  ),
                                ),
                              );
                            },
                            child: const Text('View all comments'),
                          ),
                        const Divider(color: Colors.grey),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                if (commentController.text.isNotEmpty) {
                                  _addComment(
                                      messageId, commentController.text);
                                  commentController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

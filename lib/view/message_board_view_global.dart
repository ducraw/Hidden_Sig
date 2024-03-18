import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'message_creation_page.dart';
import 'all_comments_page.dart';

class MessageBoardViewGlobal extends StatefulWidget {
  const MessageBoardViewGlobal({Key? key}) : super(key: key);

  @override
  State<MessageBoardViewGlobal> createState() => _MessageBoardViewGlobalState();
}

class _MessageBoardViewGlobalState extends State<MessageBoardViewGlobal> {
  late CollectionReference _messagesCollection;
  late CollectionReference _userInfoCollection;
  final Map<String, TextEditingController> _commentControllers = {};
  final ScrollController _scrollController = ScrollController();
  double _savedScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _messagesCollection = FirebaseFirestore.instance.collection('messages');
    _userInfoCollection = FirebaseFirestore.instance.collection('userInfo');
    _scrollController.addListener(_saveScrollPosition);
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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _removeMessage(String messageId, String userId) async {
    try {
      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Check if the current user is the uploader of the message
      if (currentUser != null && currentUser.uid == userId) {
        await _messagesCollection.doc(messageId).delete();
        //print('Message deleted successfully');
      } else {
        //print('You are not authorized to delete this message.');
        // You can show a snackbar or dialog indicating the user is not authorized
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Future<void> _likeComment(String messageId, int commentIndex) async {
    try {
      // Get the current message data
      var messageSnapshot = await _messagesCollection.doc(messageId).get();
      var messageData = messageSnapshot.data() as Map<String, dynamic>;
      var comments = messageData['comments'];

      if (comments != null &&
          commentIndex < (comments as List<dynamic>).length) {
        var comment = (comments as List<dynamic>)[commentIndex];

        // Ensure comment is a Map before accessing properties
        if (comment is Map<String, dynamic>) {
          var likes = (comment['likes'] ?? 0) + 1; // Increment likes
          comment['likes'] = likes;

          // Update the comment data in Firestore
          (comments as List<dynamic>)[commentIndex] = comment;

          // Sort comments based on likes count
          (comments as List<dynamic>)
              .sort((a, b) => b['likes'].compareTo(a['likes']));

          // Update sorted comments in Firestore
          await _messagesCollection
              .doc(messageId)
              .update({'comments': comments});

          print('Comment liked successfully');
        }
      }
    } catch (e) {
      print('Error liking comment: $e');
    }
  }

  Future<void> _addComment(String messageId, String comment) async {
    try {
      await _messagesCollection.doc(messageId).update({
        'comments': FieldValue.arrayUnion([
          {
            'text': comment,
            'likes': 0,
          }
        ]),
      });
      print('Comment added successfully in the database');
    } catch (e) {
      print('Error adding comment in the database: $e');
    }
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
              style: TextStyle(fontSize: 16.0),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          // Declare infoIndex here
          int infoIndex = hiddenTextInfo.indexWhere(
            (info) => info['location'] == index + 1,
          );

          return SizedBox(
            width: textPainter.width + 1.5, // Adjust padding as needed
            height: 25, // Adjust height as needed
            child: InkWell(
              onTap: isHidden
                  ? null
                  : () {
                      setState(() {
                        if (infoIndex != -1) {
                          _updateClicksRemain(
                              messageId, hiddenTextInfo, infoIndex);
                          // Update totalClicksRemain in firestore
                          _updateTotalClicksRemainInDatabase(
                              messageId, totalClicksRemain - 1);

                          // If clicksRemain reaches 0, do the normal onTap event
                          if (hiddenTextInfo[infoIndex]['clicksRemain'] == 0) {
                            hiddenInputText[index] =
                                hiddenTextInfo[infoIndex]['word'];
                            _updateHiddenInputTextInDatabase(
                                messageId, hiddenInputText.join(' '));
                          }
                        }
                      });
                    },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 0, vertical: 0), // Adjust padding as needed
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Stack(
                  children: [
                    Text(
                      hiddenInputText[index],
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    if (!isHidden &&
                        infoIndex !=
                            -1) // Render "Clicks Remain" only when isHidden is true and infoIndex exists
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: Text(
                          "${hiddenTextInfo[infoIndex]['clicksRemain']}",
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black, // Adjust color as needed
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
          return SizedBox.shrink();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Global Message Board'),
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

          // Restore the scroll position when the widget is rebuilt
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(_savedScrollOffset);
          });

          return ListView.builder(
            controller: _scrollController,
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
                  messageData['totalClicksRemain'] ?? 0;

              // Check if controller already exists for this message
              if (!_commentControllers.containsKey(message.id)) {
                // If not, create a new controller
                _commentControllers[message.id] = TextEditingController();
              }

              // Retrieve the controller for this message
              TextEditingController commentController =
                  _commentControllers[message.id]!;

              // Get comments
              List<Map<String, dynamic>> comments = [];

              if (messageData['comments'] != null) {
                comments = (messageData['comments'] as List<dynamic>)
                    .cast<Map<String, dynamic>>();
              }

              // Sort comments based on likes
              comments.sort(
                  (a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

              // Limit comments to 3
              final limitedComments =
                  comments.length > 3 ? comments.sublist(0, 3) : comments;

              return StreamBuilder<QuerySnapshot>(
                stream: _userInfoCollection
                    .where('userId', isEqualTo: messageData['userId'])
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }

                  var userData = userSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                  var profileImageUrl = userData['imageUrl'];
                  var displayName = userData['displayName'];
                  User? currentUser = FirebaseAuth.instance.currentUser;

                  // Check if the current user is the uploader
                  bool isUploader = currentUser != null &&
                      currentUser.uid == messageData['userId'];

                  return Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
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
                          title: Text(displayName),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl),
                          ),
                          trailing: isUploader
                              ? IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _removeMessage(
                                        message.id, messageData['userId']);
                                  },
                                )
                              : SizedBox(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildHiddenInputButtons(
                            hiddenTextInfo,
                            message.id,
                            hiddenInputText,
                            inputTextFromDatabase,
                            totalClicksRemain,
                          ),
                        ),
                        // Display limited comments
                        if (limitedComments.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Comments:'),
                              for (int i = 0; i < limitedComments.length; i++)
                                ListTile(
                                  title: Text(limitedComments[i]['text']),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                          'Likes: ${limitedComments[i]['likes']}'),
                                      IconButton(
                                        icon: Icon(Icons.thumb_up),
                                        onPressed: () {
                                          _likeComment(message.id, i);
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
                              // Navigate to a new page to display all comments
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllCommentsPage(
                                    comments: comments,
                                    messageId: message.id,
                                  ),
                                ),
                              );
                            },
                            child: Text('View all comments'),
                          ),
                        Divider(color: Colors.grey),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () {
                                if (commentController.text.isNotEmpty) {
                                  _addComment(
                                      message.id, commentController.text);
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

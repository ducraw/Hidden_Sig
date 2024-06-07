import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllCommentsPage extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final String messageId;

  const AllCommentsPage({
    Key? key,
    required this.comments,
    required this.messageId,
  }) : super(key: key);

  @override
  State<AllCommentsPage> createState() => _AllCommentsPageState();
}

class _AllCommentsPageState extends State<AllCommentsPage> {
  late CollectionReference _messagesCollection;

  @override
  void initState() {
    super.initState();
    _messagesCollection = FirebaseFirestore.instance.collection('messages');
  }

  Future<void> _likeComment(int commentIndex) async {
    try {
      var messageSnapshot =
          await _messagesCollection.doc(widget.messageId).get();
      var messageData = messageSnapshot.data() as Map<String, dynamic>;
      var comments = messageData['comments'];
      if (comments != null && commentIndex < comments.length) {
        var comment = comments[commentIndex];

        if (comment is Map<String, dynamic>) {
          var likes = (comment['likes'] ?? 0) + 1;
          comment['likes'] = likes;

          comments[commentIndex] = comment;
          await _messagesCollection
              .doc(widget.messageId)
              .update({'comments': comments});

          setState(() {
            widget.comments[commentIndex]['likes'] = likes;
          });
        }
      }
    } catch (e) {
      //print('Error liking comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Comments'),
      ),
      body: ListView.builder(
        itemCount: widget.comments.length,
        itemBuilder: (context, index) {
          final comment = widget.comments[index];
          const Text('Comments:');
          return ListTile(
            title: Text(comment['text']),
            subtitle: Row(
              children: [
                Text('Likes: ${comment['likes']}'),
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    _likeComment(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

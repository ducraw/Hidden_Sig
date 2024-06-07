import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiddensig/custom_bottom_navigation_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageCreationPage extends StatefulWidget {
  const MessageCreationPage({Key? key}) : super(key: key);

  @override
  State<MessageCreationPage> createState() => _MessageCreationPageState();
}

class _MessageCreationPageState extends State<MessageCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final List<String> _convertedMessage = [];
  final List<bool> _letterTapped = [];
  int _clicksToUnlock = 1;

  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _messageController.addListener(_onMessageChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageChange() {
    setState(() {
      _convertMessage();
    });
  }

  void _convertMessage() {
    var words = _messageController.text.split(' ');

    _convertedMessage.clear();
    _letterTapped.clear();

    bool isFirstWord = true;
    for (var word in words) {
      if (!isFirstWord) {
        _convertedMessage.add("");
        _letterTapped.add(false);
      } else {
        isFirstWord = false;
      }

      if (word.length > 44) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Warning'),
              content: Text('Word "$word" exceeds the limit of 44 characters.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      List<String> letters = word.split('');
      List<String> connectedLetters = [];

      for (var letter in letters) {
        if (letter.trim().isEmpty && connectedLetters.isNotEmpty) {
          _convertedMessage.add(connectedLetters.join(""));
          _letterTapped.addAll(List.filled(connectedLetters.length, false));
          connectedLetters.clear();
          _convertedMessage.add("");
          _letterTapped.add(false);
        } else {
          connectedLetters.add(letter);
        }
      }

      if (connectedLetters.isNotEmpty) {
        _convertedMessage.add(connectedLetters.join(""));
        _letterTapped.addAll(List.filled(connectedLetters.length, false));
      }
    }
  }

  Future<void> _uploadToFirestore() async {
    try {
      if (_user == null) {
        developer.log('data:222');
        return;
      }

      List<Map<String, dynamic>> hiddenTextInfo = _letterTapped
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) {
        return {
          'word': _convertedMessage[entry.key],
          'location': entry.key + 1,
          'clicksToUnlock': _clicksToUnlock,
          'clicksRemain': _clicksToUnlock,
          'wordLength': _convertedMessage[entry.key].length,
        };
      }).toList();

      int hiddenTextCount = _letterTapped.where((tapped) => tapped).length;

      // Replace hidden words in _convertedMessage with *
      List<String> hiddenInputWords = List<String>.from(_convertedMessage);
      for (int i = 0; i < _letterTapped.length; i++) {
        if (_letterTapped[i]) {
          hiddenInputWords[i] = '*' * _convertedMessage[i].length;
        }
      }
      String hiddenInputText = hiddenInputWords.join(' ');
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:3000/api/messages'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, dynamic>{
              'userId': _user!.uid,
              'inputText': _messageController.text,
              'hiddenInputText': hiddenInputText,
              'hiddenTextInfo': hiddenTextInfo,
              '_clicksToUnlock': _clicksToUnlock,
              'hiddenTextCount': hiddenTextCount,
            }),
          )
          .timeout(const Duration(seconds: 5));

      developer.log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        developer.log('data:22');
      } else {
        developer.log('data:1');
      }

      developer.log('Response status code: ${response.statusCode}');
    } catch (e) {
      developer.log('Response status code: $e');
      //print('Error uploading to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int hiddenTextCount = _letterTapped.where((tapped) => tapped).length;
    List<String> hiddenWords = [];
    List<int> hiddenTextIndices = [];

    for (int i = 0; i < _convertedMessage.length; i++) {
      if (_letterTapped.length > i && _letterTapped[i]) {
        hiddenWords.add(_convertedMessage[i]);
        hiddenTextIndices.add(i);
      }
    }

    String hiddenTextLocations =
        hiddenTextIndices.map((index) => (index + 1).toString()).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message Text'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter message text';
                  }
                  return null;
                },
                maxLines: null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (value) {
                  _convertMessage();
                },
                maxLength: 400,
                buildCounter: (BuildContext context,
                    {int? currentLength, int? maxLength, bool? isFocused}) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      '${currentLength ?? 0}/$maxLength',
                      style: TextStyle(
                        color: currentLength! <= maxLength!
                            ? Colors.grey
                            : Colors.red,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_convertedMessage.isNotEmpty)
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 1.0,
                    runSpacing: 1.0,
                    children: List.generate(
                      _convertedMessage.length,
                      (index) {
                        final letter = _convertedMessage[index];
                        if (letter.isNotEmpty) {
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: letter,
                              style: TextStyle(
                                fontSize: 14,
                                color: _letterTapped[index]
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          return SizedBox(
                            width: textPainter.width + 4.0,
                            height: 15,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _letterTapped[index] = !_letterTapped[index];
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _letterTapped[index]
                                    ? Colors.white
                                    : Colors.black,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: _letterTapped[index]
                                      ? Colors.white
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Clicks to Unlock: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 0,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _clicksToUnlock = int.tryParse(value) ?? 1;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid integer';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Hidden Text Count: $hiddenTextCount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hidden Words: ${hiddenWords.join(", ")}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Hidden Text Locations: $hiddenTextLocations',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () {
                  _uploadToFirestore();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

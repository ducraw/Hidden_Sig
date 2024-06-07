import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum FieldValidationState { initial, valid, invalid }

class ProfileCreationView extends StatefulWidget {
  const ProfileCreationView({Key? key}) : super(key: key);

  @override
  State<ProfileCreationView> createState() => _ProfileCreationViewState();
}

class _ProfileCreationViewState extends State<ProfileCreationView> {
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late String? _userId;
  File? _imageFile;
  Offset _imagePosition = Offset.zero;
  String _imageUrl = '';
  FieldValidationState _usernameValidationState = FieldValidationState.initial;
  FieldValidationState _displayNameValidationState =
      FieldValidationState.initial;
  bool _isLoading = true;

  @override
  void initState() {
    _usernameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _setDefaultImageUrl();
    _getCurrentUser();
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  void _setDefaultImageUrl() async {
    firebase_storage.Reference defaultImageRef = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('default_profile_images')
        .child('default_pic.jpg');

    _imageUrl = await defaultImageRef.getDownloadURL();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut(NavigatorState navigatorState) async {
    await FirebaseAuth.instance.signOut();
    navigatorState.pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _signOut(Navigator.of(context));
              })
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: _getUsernameErrorText(),
                ),
                onChanged: (value) {
                  setState(() {
                    _usernameValidationState = _validateUsername(value.trim());
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  errorText: _getDisplayNameErrorText(),
                ),
                onChanged: (value) {
                  setState(() {
                    _displayNameValidationState =
                        _validateDisplayName(value.trim());
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3, // Limiting to 3 lines
                maxLength: 400,
                decoration: const InputDecoration(
                  labelText: 'Bio (Optional)',
                  hintText: 'Tell something about yourself',
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.width * 0.4,
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          _imageFile == null
                              ? Image.network(
                                  _imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _imagePosition += details.delta;
                                      _imagePosition = Offset(
                                        _imagePosition.dx.clamp(
                                            -MediaQuery.of(context).size.width *
                                                0.4 /
                                                2,
                                            MediaQuery.of(context).size.width *
                                                0.4 /
                                                2),
                                        _imagePosition.dy.clamp(
                                            -MediaQuery.of(context).size.width *
                                                0.4 /
                                                2,
                                            MediaQuery.of(context).size.width *
                                                0.4 /
                                                2),
                                      );
                                    });
                                  },
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center +
                                            Alignment(
                                                _imagePosition.dx /
                                                    (MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.4 /
                                                        2),
                                                _imagePosition.dy /
                                                    (MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.4 /
                                                        2)),
                                      ),
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _pickImage,
                              tooltip: 'Change Image',
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_userId != null &&
                        _usernameValidationState ==
                            FieldValidationState.valid &&
                        _displayNameValidationState ==
                            FieldValidationState.valid)
                    ? _saveProfile
                    : null,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  String? _getUsernameErrorText() {
    if (_usernameValidationState == FieldValidationState.invalid) {
      return 'Username: 6-14 characters, letters and numbers only.';
    }
    return null;
  }

  String? _getDisplayNameErrorText() {
    if (_displayNameValidationState == FieldValidationState.invalid) {
      return 'Display Name must be between 6 and 14 characters';
    }
    return null;
  }

  FieldValidationState _validateUsername(String value) {
    if (value.isEmpty ||
        value.length < 6 ||
        value.length > 14 ||
        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return FieldValidationState.invalid;
    }
    return FieldValidationState.valid;
  }

  FieldValidationState _validateDisplayName(String value) {
    if (value.isEmpty || value.length < 6 || value.length > 14) {
      return FieldValidationState.invalid;
    }
    return FieldValidationState.valid;
  }

  void _saveProfile() async {
    if (_userId == null) {
      return;
    }

    String username = _usernameController.text.trim();
    String displayName = _displayNameController.text.trim();
    String bio = _bioController.text.trim();
    String imageUrl = '';

    if (_imageFile != null) {
      if (_imageUrl.isNotEmpty &&
          !_imageUrl.contains('default_profile_images')) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(_imageUrl)
            .delete();
      }

      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .refFromURL('gs://hidden-sig.appspot.com')
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      firebase_storage.UploadTask uploadTask = ref.putFile(_imageFile!);

      await uploadTask.whenComplete(() async {
        try {
          imageUrl = await ref.getDownloadURL();

          setState(() {
            _imageUrl = imageUrl;
          });

          _saveProfileToFirestore(username, displayName, bio, imageUrl);
        } catch (error) {
          //print("Failed to upload image: $error");
        }
      });
    } else {
      _saveProfileToFirestore(username, displayName, bio, _imageUrl);
    }
  }

  Future<void> _saveProfileToFirestore(
      String username, String displayName, String bio, String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/user/saveProfile'),
        body: jsonEncode({
          'userId': _userId,
          'username': username,
          'displayName': displayName,
          'bio': bio,
          'imageUrl': imageUrl,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('User profile saved successfully');
        Navigator.pushReplacementNamed(context, '/bottom');
      } else {
        print('Failed to save user profile');
        // Handle error
      }
    } catch (e) {
      print('Error saving user profile: $e');
      // Handle error
    }
  }
}

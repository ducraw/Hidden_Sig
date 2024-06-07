import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

enum FieldValidationState { initial, valid, invalid }

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _ProfileCreationViewState();
}

class _ProfileCreationViewState extends State<EditProfileView> {
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late String? _userId;
  File? _imageFile; // Initialize _imageFile with null
  Offset _imagePosition =
      Offset.zero; // Initialize _imagePosition with Offset.zero
  String _imageUrl = '';
  FieldValidationState _usernameValidationState = FieldValidationState.initial;
  FieldValidationState _displayNameValidationState =
      FieldValidationState.initial;
  bool _isLoading =
      true; // Variable to track whether the image is loading or not

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
    // Get the default profile image URL from Firebase Storage
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

  void _saveProfileToFirestore(
      String username, String displayName, String bio, String imageUrl) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    QuerySnapshot<Map<String, dynamic>> existingUsernames =
        await FirebaseFirestore.instance
            .collection('userInfo')
            .where('username', isEqualTo: username)
            .get();

    if (existingUsernames.docs.isNotEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content:
              Text('Username already taken. Please choose a different one.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      QuerySnapshot<Map<String, dynamic>> existingDocs = await FirebaseFirestore
          .instance
          .collection('userInfo')
          .where('userId', isEqualTo: _userId)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        existingDocs.docs.first.reference.update({
          'username': username,
          'displayName': displayName,
          'bio': bio,
          'imageUrl': imageUrl,
        }).then((_) {
          Navigator.pushReplacementNamed(context, '/bottom');
        }).catchError((error) {
          //print("Failed to update user profile: $error");
        });
      } else {
        FirebaseFirestore.instance.collection('userInfo').add({
          'userId': _userId,
          'username': username,
          'displayName': displayName, // Add display name field
          'bio': bio,
          'imageUrl': imageUrl,
        }).then((DocumentReference document) {
          Navigator.pushReplacementNamed(context, '/bottom');
        }).catchError((error) {
          //print("Failed to add user: $error");
        });
      }
    }
  }
}

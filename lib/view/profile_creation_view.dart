import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

enum FieldValidationState { Initial, Valid, Invalid }

class ProfileCreationView extends StatefulWidget {
  const ProfileCreationView({Key? key}) : super(key: key);

  @override
  _ProfileCreationViewState createState() => _ProfileCreationViewState();
}

class _ProfileCreationViewState extends State<ProfileCreationView> {
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late String? _userId;
  File? _imageFile; // Initialize _imageFile with null
  Offset _imagePosition =
      Offset.zero; // Initialize _imagePosition with Offset.zero
  String _imageUrl = '';
  FieldValidationState _usernameValidationState = FieldValidationState.Initial;
  FieldValidationState _displayNameValidationState =
      FieldValidationState.Initial;
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

    // Update the state to reflect the default image URL
    setState(() {
      _isLoading = false; // Set loading state to false after image is loaded
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
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
              SizedBox(height: 16),
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
              SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3, // Limiting to 3 lines
                maxLength: 400,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  hintText: 'Tell something about yourself',
                ),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator() // Show CircularProgressIndicator while loading
                  : Container(
                      width: MediaQuery.of(context).size.width *
                          0.4, // Adjust width as needed
                      height: MediaQuery.of(context).size.width *
                          0.4, // Make the height same as width for a perfect circle
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          _imageFile == null
                              ? Image.network(
                                  _imageUrl, // Use the default image URL
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
                              icon: Icon(Icons.edit),
                              onPressed: _pickImage,
                              tooltip: 'Change Image',
                            ),
                          ),
                        ],
                      ),
                    ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_userId != null &&
                        _usernameValidationState ==
                            FieldValidationState.Valid &&
                        _displayNameValidationState ==
                            FieldValidationState.Valid)
                    ? _saveProfile
                    : null,
                child: Text('Save Profile'),
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
    if (_usernameValidationState == FieldValidationState.Invalid) {
      return 'Username: 6-14 characters, letters and numbers only.';
    }
    return null;
  }

  String? _getDisplayNameErrorText() {
    if (_displayNameValidationState == FieldValidationState.Invalid) {
      return 'Display Name must be between 6 and 14 characters';
    }
    return null;
  }

  FieldValidationState _validateUsername(String value) {
    if (value.isEmpty ||
        value.length < 6 ||
        value.length > 14 ||
        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return FieldValidationState.Invalid;
    }
    return FieldValidationState.Valid;
  }

  FieldValidationState _validateDisplayName(String value) {
    if (value.isEmpty || value.length < 6 || value.length > 14) {
      return FieldValidationState.Invalid;
    }
    return FieldValidationState.Valid;
  }

  void _saveProfile() async {
    if (_userId == null) {
      // User is not authenticated, handle this case accordingly
      return;
    }

    String username = _usernameController.text.trim();
    String displayName = _displayNameController.text.trim();
    String bio = _bioController.text.trim();
    String imageUrl = ''; // Default or blank image URL

    if (_imageFile != null) {
      // Delete the previous image if it exists
      if (_imageUrl.isNotEmpty &&
          !_imageUrl.contains('default_profile_images')) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(_imageUrl)
            .delete();
      }

      // Upload the new image file to Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .refFromURL('gs://hidden-sig.appspot.com')
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file to Firebase Storage
      firebase_storage.UploadTask uploadTask = ref.putFile(_imageFile!);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        try {
          // Get the download URL for the uploaded image
          imageUrl = await ref.getDownloadURL();

          // Save the imageUrl for future reference
          setState(() {
            _imageUrl = imageUrl;
          });

          // Save profile information along with the image URL to Firestore
          _saveProfileToFirestore(username, displayName, bio, imageUrl);
        } catch (error) {
          // Handle any errors that occur during the upload
          //print("Failed to upload image: $error");
        }
      });
    } else {
      // No image selected
      _saveProfileToFirestore(
          username, displayName, bio, _imageUrl); // Pass _imageUrl here
    }
  }

  void _saveProfileToFirestore(
      String username, String displayName, String bio, String imageUrl) async {
    // Check if the username is already taken
    QuerySnapshot<Map<String, dynamic>> existingUsernames =
        await FirebaseFirestore.instance
            .collection('userInfo')
            .where('username', isEqualTo: username)
            .get();

    if (existingUsernames.docs.isNotEmpty) {
      // If the username is already taken, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Username already taken. Please choose a different one.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // If the username is available, proceed to save the profile
      // Check if a document with the same userId already exists
      QuerySnapshot<Map<String, dynamic>> existingDocs = await FirebaseFirestore
          .instance
          .collection('userInfo')
          .where('userId', isEqualTo: _userId)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        // If a document with the same userId exists, update its fields
        existingDocs.docs.first.reference.update({
          'username': username,
          'displayName': displayName, // Add display name field
          'bio': bio,
          'imageUrl': imageUrl,
          // Add other fields as needed
        }).then((_) {
          // Profile information updated successfully
          // Navigate the user to the message board
          Navigator.pushReplacementNamed(context, '/bottom');
        }).catchError((error) {
          // Handle any errors that occur during the operation
          print("Failed to update user profile: $error");
        });
      } else {
        // If no document with the same userId exists, add a new document
        FirebaseFirestore.instance.collection('userInfo').add({
          'userId': _userId,
          'username': username,
          'displayName': displayName, // Add display name field
          'bio': bio,
          'imageUrl': imageUrl,
          // Add other fields as needed
        }).then((DocumentReference document) {
          // Profile information saved successfully
          // Navigate the user to the message board
          Navigator.pushReplacementNamed(context, '/bottom');
        }).catchError((error) {
          // Handle any errors that occur during the operation
          print("Failed to add user: $error");
        });
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  _EditProfileViewState createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late String? _userId;
  String _imageUrl = '';
  File? _imageFile;
  Offset _imagePosition = Offset.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _getDefaultProfileData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _getDefaultProfileData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('userInfo')
          .doc(_userId)
          .get();

      if (userData.exists) {
        Map<String, dynamic> data = userData.data()!;
        _displayNameController.text = data['displayName'];
        _bioController.text = data['bio'];
        _imageUrl = data['imageUrl'];
      }
    }

    setState(() {
      _isLoading = false; // Set loading state to false after data is fetched
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
        title: const Text('Edit Profile'),
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
                controller: TextEditingController()..text = _userId ?? '',
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                enabled: false,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                ),
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
                onPressed: _saveProfile,
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

  void _saveProfile() async {
    if (_userId == null) {
      // User is not authenticated, handle this case accordingly
      return;
    }

    String displayName = _displayNameController.text.trim();
    String bio = _bioController.text.trim();
    String imageUrl = ''; // Default or blank image URL

    // Handle image upload if an image is selected
    if (_imageFile != null) {
      // Delete the previous image if it exists
      if (_imageUrl.isNotEmpty) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(_imageUrl)
            .delete();
      }

      // Upload the new image file to Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$_userId.jpg'); // Use userId as image name

      // Upload the file to Firebase Storage
      firebase_storage.UploadTask uploadTask = ref.putFile(_imageFile!);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        // Get the download URL for the uploaded image
        imageUrl = await ref.getDownloadURL();

        // Save the imageUrl for future reference
        setState(() {
          _imageUrl = imageUrl;
        });

        // Save profile information along with the image URL to Firestore
        await _saveProfileToFirestore(displayName, bio, imageUrl);
      }).catchError((error) {
        // Handle any errors that occur during the upload
        print("Failed to upload image: $error");
      });
    } else {
      // If no new image is selected, just save the other profile data
      await _saveProfileToFirestore(displayName, bio, _imageUrl);
    }
  }

  Future<void> _saveProfileToFirestore(
      String displayName, String bio, String imageUrl) async {
    await FirebaseFirestore.instance
        .collection('userInfo')
        .doc(_userId)
        .update({
      'displayName': displayName,
      'bio': bio,
      'imageUrl': imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

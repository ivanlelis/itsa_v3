import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const ProfileView({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedIndex = 3; // Set the default to Profile (index 3)
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    // Fetch user data when the ProfileView is initialized
    _fetchUserData(context);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CustomerMainHome(
              userName: widget.userName,
              email: widget.email,
              imageUrl: widget.imageUrl,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Menu
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Menu(
              userName: widget.userName,
              email: widget.email,
              imageUrl: widget.imageUrl,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Favorites
        // Navigate to the Favorites screen (replace with your actual screen)
        break;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImageAndSaveUrl(BuildContext context) async {
    if (_pickedImage == null) return;

    try {
      // Access the UserProvider to get the current user
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      // Check if the current user is available
      if (currentUser == null) return;

      // Upload image to Firebase Storage directly under 'user_image'
      final storageRef = FirebaseStorage.instance.ref(
          'user_image/${currentUser.userName}.jpg'); // Directly reference the file path

      await storageRef.putFile(_pickedImage!);

      // Get the download URL
      final imageUrl = await storageRef.getDownloadURL();

      // Update the Firestore document with the image URL
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(currentUser.userName) // Use userName as the document ID
          .update({'imageUrl': imageUrl}).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully!')),
        );
      }).catchError((error) {
        print('Failed to update document: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image.')),
        );
      });
    } catch (e) {
      print('Failed to upload image and save URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile image.')),
      );
    }
  }

  Future<void> _fetchUserData(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchCurrentUser(); // Fetch the current user data

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF4D331F), // Brown color
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _fetchUserData(context), // Refresh data on press
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : NetworkImage(currentUser?.imageUrl ?? widget.imageUrl)
                            as ImageProvider,
                  ),
                  Positioned(
                    bottom:
                        -10, // Adjusted to place the icon outside the circle
                    right: -30, // Adjusted to place the icon outside the circle
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.black),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),
              Text(
                widget.userName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.email,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              _buildEditableField('Name', widget.userName, context),
              _buildEditableField('Email', widget.email, context),
              _buildEditableField('Mobile Number', '0912345678',
                  context), // Replace with actual mobile number if available
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _uploadImageAndSaveUrl(
                      context); // Call the upload method
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen, // Light green color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Update',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildEditableField(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  // Handle edit action
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

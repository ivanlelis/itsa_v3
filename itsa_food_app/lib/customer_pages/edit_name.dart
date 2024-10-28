import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:itsa_food_app/user_model/user_model.dart';

class EditName extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;

  const EditName({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.imageUrl,
    required this.uid,
  });

  @override
  _EditNameState createState() => _EditNameState();
}

class _EditNameState extends State<EditName> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
    }
  }

  void _saveChanges() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return; // Ensure user is not null

    // Query Firestore for the document with the matching emailAddress
    final querySnapshot = await _firestore
        .collection('customer')
        .where('emailAddress', isEqualTo: user.emailAddress)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // If a document is found, update it
      final documentId = querySnapshot.docs.first.id; // Get the document ID

      await _firestore.collection('customer').doc(documentId).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'userName': '${_firstNameController.text} ${_lastNameController.text}',
      });

      // Update the user in your UserProvider using a new method
      userProvider.updateCurrentUser(
        UserModel(
          uid: widget.uid,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          userName: '${_firstNameController.text} ${_lastNameController.text}',
          emailAddress: widget.emailAddress,
          imageUrl: widget.imageUrl,
          email: widget.email,
        ),
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully!')),
      );
    } else {
      // Handle case when no document is found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user found with that email address.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Name')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}

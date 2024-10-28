import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Ensure you have the provider package imported
import 'package:itsa_food_app/user_provider/user_provider.dart';

class EditEmail extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String imageUrl;
  final String uid;

  EditEmail({
    required this.userName,
    required this.emailAddress,
    required this.imageUrl,
    required this.uid,
  });

  @override
  _EditEmailState createState() => _EditEmailState();
}

class _EditEmailState extends State<EditEmail> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isVerifying = false;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _emailController.text =
          user.emailAddress; // Initialize the email controller
    }
  }

  Future<void> _verifyAndUpdateEmail() async {
    String newEmail = _emailController.text.trim();
    User? user = _auth.currentUser;

    if (user != null && newEmail.isNotEmpty) {
      setState(() {
        isVerifying = true;
        statusMessage = "Verifying email...";
      });

      try {
        // Create a Future that sends the verification email
        Future<void> sendVerificationEmail =
            user.verifyBeforeUpdateEmail(newEmail);

        // Create a Future that updates the user's emailAddress in Firestore
        Future<void> updateEmailInFirestore =
            _updateUserEmailInFirestore(newEmail, user.uid);

        // Wait for both operations to complete
        await Future.wait([sendVerificationEmail, updateEmailInFirestore]);

        // Update the UserProvider to reflect changes
        Provider.of<UserProvider>(context, listen: false)
            .updateUserEmail(newEmail);

        setState(() => statusMessage =
            "Verification email sent. Please check your inbox.");

        // Listen for the user's email change
        _auth.userChanges().listen((updatedUser) {
          if (updatedUser?.email == newEmail) {
            setState(() => statusMessage = "Email successfully updated.");
          }
        });
      } catch (e) {
        setState(
            () => statusMessage = "Failed to verify email: ${e.toString()}");
      } finally {
        setState(() => isVerifying = false);
      }
    } else {
      setState(() => statusMessage = "Please enter a valid email.");
    }
  }

  Future<void> _updateUserEmailInFirestore(String newEmail, String uid) async {
    // Query Firestore for the document with the matching uid
    final querySnapshot = await _firestore
        .collection('customer')
        .where('uid', isEqualTo: uid)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // If a document is found, update it
      final documentId = querySnapshot.docs.first.id; // Get the document ID

      await _firestore.collection('customer').doc(documentId).update({
        'emailAddress': newEmail,
      });
    } else {
      throw Exception("No user document found matching the current UID.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID
    String? currentUserUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Edit Email")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Enter new email address"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isVerifying ? null : _verifyAndUpdateEmail,
              child: Text("Verify Email"),
            ),
            SizedBox(height: 10),
            Text(
              "Your email can only be changed once every 30 days",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 10),
            if (statusMessage.isNotEmpty)
              Text(
                statusMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            // Display the UID of the current logged-in user
            if (currentUserUid != null)
              Text(
                "Your UID: $currentUserUid",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

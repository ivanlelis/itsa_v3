import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/user_model/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  String? _adminEmail; // This will store admin email

  UserModel? get currentUser => _currentUser;
  String? get adminEmail => _adminEmail; // Getter for admin email

  // Update user's email and notify listeners
  void updateUserEmail(String newEmail) {
    if (_currentUser != null) {
      _currentUser!.emailAddress = newEmail; // Use null check operator (!)
      notifyListeners(); // Notify listeners of the change
    }
  }

  Future<void> fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetching user document based on the UID
      final userDoc = await FirebaseFirestore.instance
          .collection(
              'customer') // Change to 'customer' if that's where the users are stored
          .doc(user.uid) // Fetch by UID for better accuracy
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!; // Get the document data
        _currentUser = UserModel(
          uid: data['uid'] ?? '',
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          userName: data['userName'] ?? '',
          emailAddress: data['emailAddress'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          email: data['email'] ?? '',
        );
        _adminEmail = data['email']; // Set admin email from the fetched data
        notifyListeners();
      } else {
        print("No user document found for UID: ${user.uid}");
      }
    } else {
      print("No user is currently logged in.");
    }
  }

  void setAdminEmail(String email) {
    _adminEmail = email; // Set the admin email
    notifyListeners();
  }

  void updateCurrentUser(UserModel updatedUser) {
    _currentUser = updatedUser; // Update the current user
    notifyListeners();
  }

  // New method to fetch user data directly from Firestore using UID
  Future<void> updateUserInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUser != null) {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(user.uid)
          .update({
        'emailAddress': _currentUser!.emailAddress,
        'firstName': _currentUser!.firstName,
        'lastName': _currentUser!.lastName,
        'userName': _currentUser!.userName,
        'imageUrl': _currentUser!.imageUrl,
      });
    }
  }
}

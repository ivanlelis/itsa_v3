import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/user_model/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  String? _adminEmail; // This will store admin email

  UserModel? get currentUser => _currentUser;
  String? get adminEmail => _adminEmail; // Getter for admin email

  Future<void> fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetching user document based on the email (or UID)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email) // Use user.email or user.uid as the document ID
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          // Ensure data is not null before accessing fields
          _currentUser = UserModel(
            userName: data['userName'] ?? '', // Access fields safely
            emailAddress: data['emailAddress'] ?? '',
            email: data['email'] ?? '',
          );
          _adminEmail = data['email']; // Set admin email from the fetched data
          notifyListeners();
        }
      }
    }
  }

  void setAdminEmail(String email) {
    _adminEmail = email; // Set the admin email
    notifyListeners();
  }
}

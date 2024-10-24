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
          .collection(
              'customer') // Change to 'customer' if that's where the users are stored
          .where('emailAddress', isEqualTo: user.email) // Fetch based on email
          .get();

      if (userDoc.docs.isNotEmpty) {
        final data = userDoc.docs.first.data(); // Get the first document
        _currentUser = UserModel(
          userName: data['userName'] ?? '',
          emailAddress: data['emailAddress'] ?? '',
          email: user.email ?? '',
        );
        _adminEmail = data['email']; // Set admin email from the fetched data
        notifyListeners();
      } else {
        print("No user document found for email: ${user.email}");
      }
    } else {
      print("No user is currently logged in.");
    }
  }

  void setAdminEmail(String email) {
    _adminEmail = email; // Set the admin email
    notifyListeners();
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/user_model/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  String? _adminEmail; // This will store the admin email

  UserModel? get currentUser => _currentUser;
  String? get adminEmail => _adminEmail; // Getter for admin email

  // Method to fetch the current user from Firestore
  Future<void> fetchCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user document using the UID for accuracy
        final userDoc = await FirebaseFirestore.instance
            .collection('customer') // Ensure correct collection is used
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _currentUser = UserModel(
            uid: data['uid'] ?? '',
            firstName: data['firstName'] ?? '',
            lastName: data['lastName'] ?? '',
            userName: data['userName'] ?? '',
            emailAddress: data['emailAddress'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            email: data['email'] ?? '',
            userAddress: data['userAddress'] ?? '',
            latitude: data['userCoordinates']?['latitude'] ??
                0.0, // Safely extract latitude
            longitude: data['userCoordinates']?['longitude'] ??
                0.0, // Safely extract longitude
          );

          _adminEmail = data['email'];
          notifyListeners();
          print("User data fetched successfully: ${_currentUser?.userName}");
        } else {
          print("No user document found for UID: ${user.uid}");
        }
      } else {
        print("No user is currently logged in.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Method to update the user's email and notify listeners
  void updateUserEmail(String newEmail) {
    if (_currentUser != null) {
      _currentUser!.emailAddress = newEmail;
      notifyListeners();
    }
  }

  // Method to update the current user data in Firestore
  Future<void> updateUserInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('customer')
            .doc(user.uid)
            .update({
          'emailAddress': _currentUser!.emailAddress,
          'firstName': _currentUser!.firstName,
          'lastName': _currentUser!.lastName,
          'userName': _currentUser!.userName,
          'imageUrl': _currentUser!.imageUrl,
          'userCoordinates': {
            'latitude': _currentUser!.latitude,
            'longitude': _currentUser!.longitude,
          },
        });
        print("User data updated in Firestore successfully.");
      } catch (e) {
        print("Error updating user data in Firestore: $e");
      }
    } else {
      print("No current user available to update.");
    }
  }

  // Method to set the admin email
  void setAdminEmail(String email) {
    _adminEmail = email;
    notifyListeners();
  }

  // Method to update the current user locally
  void updateCurrentUser(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}

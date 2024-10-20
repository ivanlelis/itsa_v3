// user_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/user_model/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.displayName)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _currentUser = UserModel(
          userName: data?['userName'] ?? '',
          emailAddress: data?['emailAddress'] ?? '',
        );
        notifyListeners();
      }
    }
  }
}

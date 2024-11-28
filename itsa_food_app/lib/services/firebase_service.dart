// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/firebase_options.dart';
import 'dart:math';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static bool _isInitialized = false;

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  // Helper method to access collections
  CollectionReference getCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';

      // Check the 'customer' collection for the user's document
      QuerySnapshot customerSnapshot = await getCollection('customer')
          .where('emailAddress', isEqualTo: userEmail)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        return customerSnapshot.docs.first.data() as Map<String, dynamic>?;
      }

      // If not found in 'customer', check the 'rider' collection
      QuerySnapshot riderSnapshot = await getCollection('rider')
          .where('emailAddress', isEqualTo: userEmail)
          .get();

      if (riderSnapshot.docs.isNotEmpty) {
        return riderSnapshot.docs.first.data() as Map<String, dynamic>?;
      }

      // If the user is not found in either collection
      print("No user document found for email: $userEmail");
    } else {
      print("No user is currently logged in.");
    }
    return null;
  }


  Future<Map<String, dynamic>?> getAdminInfo(String email) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('admin').doc('admin_1').get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      if (data != null && data['email'] == email) {
        return data; // Return admin data if email matches
      }
    } catch (e) {
      print("Error fetching admin info: $e");
    }
    return null; // Return null if no matching admin found
  }

  Future<Map<String, dynamic>?> getSuperAdInfo(String email) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('super_ad').doc('super_ad_1').get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      if (data != null && data['email'] == email) {
        return data; // Return admin data if email matches
      }
    } catch (e) {
      print("Error fetching super admin info: $e");
    }
    return null; // Return null if no matching admin found
  }

  Future<void> initializeFirebase() async {
    if (_isInitialized) {
      return; // Prevent multiple initializations
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      print("Firebase initialized");
    } catch (e) {
      print("Error initializing Firebase: $e");
      throw Exception("Failed to connect to Firebase: $e");
    }
  }

  bool get isInitialized => _isInitialized;

  String generateCustomerID() {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    String randomString = List.generate(
        5, (index) => characters[random.nextInt(characters.length)]).join();
    return 'ITSA$randomString'; // Prefix with 'ITSA'
  }

  String generateRiderID() {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    String randomString = List.generate(
        5, (index) => characters[random.nextInt(characters.length)]).join();
    return 'ITSA$randomString'; // Prefix with 'ITSA' for riderID too
  }

  Future<void> signUpWithEmail(
    String firstName,
    String lastName,
    String email,
    String mobileNumber,
    String password, {
    required String userType, // Field to distinguish between customer and rider
    Map<String, dynamic>?
        additionalData, // Extra info like vehicle details for riders
  }) async {
    if (!_isInitialized) {
      throw Exception("Firebase is not initialized.");
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure userCredential and user are non-null
      User? user = userCredential.user;
      if (user == null) {
        throw Exception("User credential is null; UID could not be obtained.");
      }

      String userName = '${firstName.trim()} ${lastName.trim()}';
      String uid = user.uid; // Get the user's UID

      // Generate ID based on user type
      String id;
      if (userType == 'rider') {
        id = generateRiderID(); // Generate riderID
      } else {
        id = generateCustomerID(); // Generate customerID
      }

      // Determine the collection (customer or rider) based on userType
      String collection = userType == 'rider' ? 'rider' : 'customer';

      // Use the UID as the document ID and add fields in the document data
      await _firestore.collection(collection).doc(uid).set({
        'uid': uid, // Add UID field to the document
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'emailAddress': email,
        'mobileNumber': mobileNumber,
        'userType': userType, // Store user type (customer or rider)
        'customerID': userType == 'customer'
            ? id
            : null, // Set customerID if userType is customer
        'riderID':
            userType == 'rider' ? id : null, // Set riderID if userType is rider
        ...?additionalData, // Additional data for riders (e.g., vehicle details)
      });

      // Send verification email
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
}

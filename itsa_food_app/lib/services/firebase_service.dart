import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static bool _isInitialized = false;

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Use the user's email to retrieve their document from Firestore
      String userEmail = user.email ?? '';

      // Query the Firestore users collection to find the document with the user's email
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('emailAddress', isEqualTo: userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // If a document is found, return its data
        return snapshot.docs.first.data() as Map<String, dynamic>?;
      } else {
        print("No user document found for email: $userEmail");
      }
    } else {
      print("No user is currently logged in.");
    }
    return null;
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

  Future<void> signUpWithEmail(String firstName, String lastName, String email,
      String mobileNumber, String password) async {
    if (!_isInitialized) {
      throw Exception("Firebase is not initialized.");
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userName = '${firstName.trim()} ${lastName.trim()}';

      await _firestore.collection('users').doc(userName).set({
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'emailAddress': email,
        'mobileNumber': mobileNumber,
        'imageUrl': '', // Initialize imageUrl if needed
      });

      await userCredential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
}

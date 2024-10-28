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
      String userEmail = user.email ?? '';

      // Check the 'customer' collection for the user's document
      QuerySnapshot customerSnapshot = await _firestore
          .collection('customer')
          .where('emailAddress', isEqualTo: userEmail)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        return customerSnapshot.docs.first.data() as Map<String, dynamic>?;
      }

      // If not found in 'customer', check the 'rider' collection
      QuerySnapshot riderSnapshot = await _firestore
          .collection('rider')
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

      // Compute the user's name
      String userName = '${firstName.trim()} ${lastName.trim()}';

      // Determine the collection (customer or rider) based on userType
      String collection = userType == 'rider' ? 'rider' : 'customer';

      // Create a new document with a unique ID
      await _firestore.collection(collection).add({
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'emailAddress': email,
        'mobileNumber': mobileNumber,
        'userType': userType, // Store user type (customer or rider)
        ...?additionalData, // Additional data for riders (e.g., vehicle details)
      });

      // Send verification email
      await userCredential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
}

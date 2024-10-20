import 'package:firebase_core/firebase_core.dart';
import 'package:itsa_food_app/firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static bool _isInitialized = false;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  Future<void> initializeFirebase() async {
    if (_isInitialized) {
      return; // Prevent multiple initializations
    }

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      _isInitialized = true;
    } catch (e) {
      throw Exception("Failed to connect to Firebase: $e");
    }
  }

  bool get isInitialized => _isInitialized;
}

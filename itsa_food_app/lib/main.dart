import 'package:flutter/material.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/home/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FirebaseService
  final firebaseService = FirebaseService();

  try {
    await firebaseService.initializeFirebase();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // You can choose to return or exit the app if Firebase fails to initialize
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Firebase Connection Status'),
    );
  }
}

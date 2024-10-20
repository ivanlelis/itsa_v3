import 'package:flutter/material.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/home/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FirebaseService
  final firebaseService = FirebaseService();
  try {
    await firebaseService.initializeFirebase();
  } catch (e) {
    print(e); // You can handle this more gracefully in a production app
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
      home: const HomePage(
          title: 'Firebase Connection Status'), // Update to HomePage
    );
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:itsa_food_app/pre_sign_up/segmentation.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/login/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _connectionStatus = "Connecting..."; // Default status
  final FirebaseService firebaseService = FirebaseService(); // Create instance

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      if (firebaseService.isInitialized) {
        setState(() {
          _connectionStatus = "Online";
        });
      } else {
        setState(() {
          _connectionStatus = "Failed to connect to Firebase.";
        });
      }
    } catch (e) {
      print('Error checking Firebase connection: $e');
      setState(() {
        _connectionStatus = "Error checking connection.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Sample Landing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              _connectionStatus,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _connectionStatus.contains("Failed")
                        ? Colors.red
                        : Colors.green,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PreSignUpSegmentationPage()),
                );
              },
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 20), // Add some space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LoginPage()), // Update to your LoginPage
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

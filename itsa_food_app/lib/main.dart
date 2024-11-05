// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/edit_address.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/home/home.dart';
import 'package:itsa_food_app/login/login.dart'; // Import your LoginPage
import 'package:itsa_food_app/user_provider/user_provider.dart'; // Import your UserProvider
import 'package:provider/provider.dart'; // Import provider package
import 'package:itsa_food_app/customer_pages/menu.dart'; // Import Menu page

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

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // Create an instance of UserProvider
      child: const MyApp(),
    ),
  );
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
      initialRoute: '/home', // Set the initial route
      routes: {
        '/home': (context) => const HomePage(
            title: 'Firebase Connection Status'), // Define the home route
        '/login': (context) => const LoginPage(), // Define the login route
        '/address': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return EditAddress(
            userName:
                args?['userName'] ?? '', // Default to an empty string if null
            emailAddress: args?['emailAddress'] ??
                '', // Default to an empty string if null
            email: args?['email'] ?? '', // Default to an empty string if null
            uid: args?['uid'] ?? '', // Default to an empty string if null
            userAddress: args?['userAddress'] ??
                '', // Default to an empty string if null
            latitude: args?['latitude'] ?? 0.0, // Default to 0.0 if null
            longitude: args?['longitude'] ?? 0.0, // Default to 0.0 if null
          );
        },
        '/menu': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return Menu(
            userName: args?['userName'] ?? '',
            emailAddress: args?['emailAddress'] ?? '',
            email: args?['email'] ?? '',
            uid: args?['uid'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
            imageUrl:
                args?['imageUrl'] ?? '', // Provide a default value if necessary
          );
        }, // Define the menu route
      },
      // Optional: Define the onUnknownRoute to handle undefined routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomePage(
              title:
                  'Firebase Connection Status'), // Redirect to Home or another page
        );
      },
    );
  }
}

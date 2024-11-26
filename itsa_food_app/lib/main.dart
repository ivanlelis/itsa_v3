import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/edit_address.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/home/home.dart';
import 'package:itsa_food_app/login/login.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/customer_pages/order_history.dart'; // Import OrderHistory
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/customer_pages/claim_vouchers.dart';

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
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/address': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return EditAddress(
            userName: args?['userName'] ?? '',
            emailAddress: args?['emailAddress'] ?? '',
            email: args?['email'] ?? '',
            uid: args?['uid'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
          );
        },
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ProfileView(
            userName: args?['userName'] ?? '',
            emailAddress: args?['emailAddress'] ?? '',
            email: args?['email'] ?? '',
            uid: args?['uid'] ?? '',
            userAddress: args?['userAddress'] ?? '',
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
            imageUrl: args?['imageUrl'] ?? '',
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
            imageUrl: args?['imageUrl'] ?? '',
          );
        },
        '/orderHistory': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return OrderHistory(
            emailAddress: args?['emailAddress'] ?? '',
            userName: args?['userName'] ?? '',
            uid: args?['uid'] ?? '',
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
          );
        },
        '/vouchers': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ClaimVouchers(
            emailAddress: args?['emailAddress'] ?? '',
            userName: args?['userName'] ?? '',
            uid: args?['uid'] ?? '',
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
          );
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );
      },
    );
  }
}

class LoginChecker extends StatefulWidget {
  const LoginChecker({super.key});

  @override
  _LoginCheckerState createState() => _LoginCheckerState();
}

class _LoginCheckerState extends State<LoginChecker> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check login status and last login time
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt('lastLoginTime');

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // If the user is logged in
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If more than 30 minutes have passed since the last login, log the user out
      if (lastLoginTime == null ||
          currentTime - lastLoginTime > 30 * 60 * 1000) {
        FirebaseAuth.instance.signOut(); // Log the user out
        prefs.remove('lastLoginTime'); // Remove the saved login time
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // User is logged in and within 30 minutes, navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      // If no user is logged in, navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

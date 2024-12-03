import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/edit_address.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';
import 'package:itsa_food_app/onboarding/onboarding.dart';
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
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/main_home/rider_home.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:itsa_food_app/stripe/const.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe and Firebase
  await _setup();

  // Start the Flutter app
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _setup() async {
  // Set Stripe Publishable Key
  Stripe.publishableKey = stripePublishableKey;

  // Initialize Firebase
  final firebaseService = FirebaseService();
  try {
    await firebaseService.initializeFirebase();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Change _initialScreen to be nullable to avoid LateInitializationError
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the onboarding has been completed
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!onboardingComplete) {
      // If onboarding is not complete, show the onboarding screen
      setState(() {
        _initialScreen = const OnboardingScreen();
      });
    } else if (user == null) {
      // If no user is logged in, navigate directly to login page (show Onboarding if necessary)
      setState(() {
        _initialScreen = const HomePage();
      });
    } else {
      // If user is logged in, check their onboarding status
      String userType = prefs.getString('userType') ??
          ''; // Retrieve user type from SharedPreferences

      // Retrieve user details from SharedPreferences (or wherever they are stored)
      String userName = prefs.getString('userName') ?? '';
      String emailAddress = prefs.getString('emailAddress') ?? '';
      String email = prefs.getString('email') ?? '';
      String imageUrl = prefs.getString('imageUrl') ?? '';
      String uid = user.uid; // Firebase user UID
      String userAddress = prefs.getString('userAddress') ?? '';
      double latitude = prefs.getDouble('latitude') ?? 0.0;
      double longitude = prefs.getDouble('longitude') ?? 0.0;
      String branchID = prefs.getString('branchID') ?? '';

      if (userType == 'customer') {
        // Redirect to CustomerMainHome if customer
        setState(() {
          _initialScreen = CustomerMainHome(
            userName: userName,
            emailAddress: emailAddress,
            email: email,
            imageUrl: imageUrl,
            uid: uid,
            userAddress: userAddress,
            latitude: latitude,
            longitude: longitude,
            branchID: branchID,
          );
        });
      } else if (userType == 'rider') {
        // Redirect to RiderDashboard if rider
        setState(() {
          _initialScreen = RiderDashboard(
            userName: userName,
            email: email,
            imageUrl: imageUrl,
          );
        });
      } else {
        // If user type is unknown, show a default screen or handle it
        setState(() {
          _initialScreen = const HomePage();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // If _initialScreen is null, fallback to a default screen
      home: _initialScreen ??
          const OnboardingScreen(), // Fallback to OnboardingScreen
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
            branchID: args?['branchID'] ?? '',
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
            branchID: args?['branchID'] ?? '',
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

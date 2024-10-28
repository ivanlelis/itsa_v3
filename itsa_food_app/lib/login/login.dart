// Your existing imports
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/main_home/rider_home.dart';
import 'package:itsa_food_app/main_home/admin_home.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService firebaseService = FirebaseService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Input validation
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Sign in the user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified
      if (userCredential.user!.emailVerified) {
        // Fetch user info from Firestore (for non-admin users)
        Map<String, dynamic>? userInfo =
            await firebaseService.getCurrentUserInfo();

        // Check user type and navigate accordingly
        if (userInfo != null && userInfo.isNotEmpty) {
          String userType = userInfo['userType'];
          if (userType == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerMainHome(
                  userName: userInfo['userName'] ?? "Guest User",
                  emailAddress: userInfo['emailAddress'] ?? "No Email Provided",
                  imageUrl: userInfo['imageUrl'] ?? "",
                  uid: userInfo['uid'] ?? "",
                  email: userInfo['email'] ?? "",
                ),
              ),
            );
          } else if (userType == 'rider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RiderMainHome(
                  userName: userInfo['userName'] ?? "Guest User",
                  email: userInfo['emailAddress'] ?? "No Email Provided",
                  imageUrl: userInfo['imageUrl'] ?? "",
                ),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = "User information not found.";
            _isLoading = false;
          });
        }
      } else {
        // Admin login check
        Map<String, dynamic>? adminInfo =
            await firebaseService.getAdminInfo(email);

        if (adminInfo != null) {
          // Access the email from the adminInfo map
          String adminEmail = adminInfo['email']; // Use the correct key here

          // Save the admin email in UserProvider
          Provider.of<UserProvider>(context, listen: false)
              .setAdminEmail(adminEmail);

          // Navigate to the Admin Home Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHome(
                userName:
                    "Admin", // Set default name or get from adminInfo if applicable
                email: adminEmail, // Use the admin email
                imageUrl: "", // Placeholder for admin image
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = "Admin credentials incorrect or not found.";
            _isLoading = false;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message; // Display error message
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

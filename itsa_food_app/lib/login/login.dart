import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/main_home/main_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseService firebaseService = FirebaseService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
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
      if (!userCredential.user!.emailVerified) {
        setState(() {
          _errorMessage = "Please verify your email before logging in.";
          _isLoading = false;
        });
        return;
      }

      // Fetch the current user's info from Firestore
      Map<String, dynamic>? userInfo =
          await firebaseService.getCurrentUserInfo();

      // Check if userInfo is null or empty
      if (userInfo == null || userInfo.isEmpty) {
        setState(() {
          _errorMessage = "User information not found.";
          _isLoading = false;
        });
        return;
      }

      // Navigate to main_home.dart upon successful login, passing user info
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainHome(
            userName:
                userInfo['userName'] ?? "Guest User", // Provide default value
            email: userInfo['emailAddress'] ??
                "No Email Provided", // Use correct field
            imageUrl:
                userInfo['imageUrl'] ?? "", // Use placeholder later if empty
          ),
        ),
      );
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

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:itsa_food_app/services/firebase_service.dart';

class RiderSignUp extends StatefulWidget {
  const RiderSignUp({super.key});

  @override
  State<RiderSignUp> createState() => _RiderSignUpState();
}

class _RiderSignUpState extends State<RiderSignUp> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleInfoController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  String? _errorMessage;

  void _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String mobileNumber = _mobileNumberController.text.trim();
    String password = _passwordController.text.trim();
    String vehicleInfo = _vehicleInfoController.text.trim();

    // Basic input validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        mobileNumber.isEmpty ||
        password.isEmpty ||
        vehicleInfo.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Sign up rider using FirebaseService
      await _firebaseService.signUpWithEmail(
        firstName,
        lastName,
        email,
        mobileNumber,
        password,
        userType: 'rider', // Indicating it's a rider
        additionalData: {'vehicleInfo': vehicleInfo}, // Adding vehicle info
      );

      setState(() {
        _isLoading = false;
      });

      // Display success message and navigate away if needed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Successful'),
          content: const Text('Your account has been created successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email Address"),
              ),
              TextField(
                controller: _mobileNumberController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              TextField(
                controller: _vehicleInfoController,
                decoration:
                    const InputDecoration(labelText: "Vehicle Information"),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up as Rider"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

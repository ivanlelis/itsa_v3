import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _firebaseConnected = false;
  String _connectionMessage = 'Checking Firebase connection...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      await Firebase.initializeApp();
      // Optional: Test a simple read to check connection
      await FirebaseFirestore.instance.collection('test').get();
      setState(() {
        _firebaseConnected = true;
        _connectionMessage = 'Firebase is connected successfully.';
      });
    } catch (e) {
      setState(() {
        _firebaseConnected = false;
        _connectionMessage = 'Failed to connect to Firebase: $e';
      });
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            _firebaseConnected
                ? Text(
                    _connectionMessage,
                    style: TextStyle(color: Colors.green),
                  )
                : Text(
                    _connectionMessage,
                    style: TextStyle(color: Colors.red),
                  ),
          ],
        ),
      ),
    );
  }
}

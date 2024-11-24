// Your existing imports
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/pre_sign_up/segmentation.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/main_home/rider_home.dart';
import 'package:itsa_food_app/main_home/admin_home.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:itsa_food_app/main_home/superad_home.dart';

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

  bool get _hasError => _errorMessage != null;

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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null && userCredential.user!.emailVerified) {
        Map<String, dynamic>? userInfo =
            await firebaseService.getCurrentUserInfo();

        if (userInfo != null && userInfo.isNotEmpty) {
          String userType = userInfo['userType'] ?? "unknown";
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
                  userAddress: userInfo['userAddress'] ?? "",
                  latitude: userInfo['userCoordinates']?['latitude'] ?? 0.0,
                  longitude: userInfo['userCoordinates']?['longitude'] ?? 0.0,
                ),
              ),
            );
          } else if (userType == 'rider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RiderDashboard(
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
        Map<String, dynamic>? adminInfo =
            await firebaseService.getAdminInfo(email);

        if (adminInfo != null && adminInfo.isNotEmpty) {
          String adminEmail = adminInfo['email'] ?? "No Email Provided";

          Provider.of<UserProvider>(context, listen: false)
              .setAdminEmail(adminEmail);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHome(
                userName: "Admin",
                email: adminEmail,
                imageUrl: "",
              ),
            ),
          );
        } else {
          Map<String, dynamic>? superadInfo =
              await firebaseService.getSuperAdInfo(email);

          if (superadInfo != null && superadInfo.isNotEmpty) {
            String superadEmail = superadInfo['email'] ?? "No Email Provided";

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SuperAdminHome(
                  userName: "Super Admin",
                  email: superadEmail,
                  imageUrl: "",
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = "User information not found.";
              _isLoading = false;
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevents resizing when the keyboard appears
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/boba_tea_new_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.only(
                bottom: keyboardHeight > 0 ? keyboardHeight : 0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 250,
                            height: 250,
                          ),
                          const SizedBox(height: 20),
                          // Email Field
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: "Email",
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _hasError
                                  ? Icon(Icons.error, color: Colors.red)
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _hasError
                                  ? Icon(Icons.error, color: Colors.red)
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            obscureText: true,
                            onChanged: (value) {
                              if (_hasError) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                    color: Colors.redAccent, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 18),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF291C0E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the registration screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreSignUpSegmentationPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E473B), // New color
                      foregroundColor: Colors.white, // White text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/pre_sign_up/segmentation.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/main_home/admin_home.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:itsa_food_app/main_home/superad_home.dart';
import 'package:itsa_food_app/otp/Customer_OTPPage.dart';
import 'package:itsa_food_app/otp/Rider_OTPPage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:math';

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

  // SMTP details
  final String smtpUsername =
      'themostnefarious@gmail.com'; // Replace with your email
  final String smtpPassword =
      'gtjf grii bxkl cpjr'; // Use App Password (not your Gmail password)

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

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
        // Fetch user info from FirebaseService
        Map<String, dynamic>? userInfo =
            await firebaseService.getCurrentUserInfo();

        if (userInfo != null) {
          // Generate OTP and send email
          String otp = _generateOTP();
          await _sendOTPEmail(email, otp);

          if (userInfo.containsKey('userName') &&
              userInfo['emailAddress'] == email) {
            // User is a customer
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerOTPPage(
                  userName: userInfo['userName'] ?? "Guest User",
                  emailAddress: userInfo['emailAddress'] ?? "No Email Provided",
                  imageUrl: userInfo['imageUrl'] ?? "",
                  uid: userInfo['uid'] ?? "",
                  email: userInfo['email'] ?? "",
                  userAddress: userInfo['userAddress'] ?? "",
                  latitude: userInfo['userCoordinates']?['latitude'] ?? 0.0,
                  longitude: userInfo['userCoordinates']?['longitude'] ?? 0.0,
                  otp: otp,
                ),
              ),
            );
          } else if (userInfo.containsKey('mobileNumber')) {
            // User is a rider
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RiderOTPPage(
                  email: email,
                  otp: otp,
                  mobileNumber: userInfo['mobileNumber'],
                ),
              ),
            );
          } else {
            // User might be an admin or super admin, check for their info
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
              return;
            }

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
              return;
            }

            setState(() {
              _errorMessage = "User information not found.";
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _errorMessage = "User information not found.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Please verify your email before logging in.";
          _isLoading = false;
        });
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

  String _generateOTP() {
    Random random = Random();
    int otp = 100000 +
        random.nextInt(
            900000); // Generates a random number between 100000 and 999999
    return otp.toString();
  }

  Future<void> _sendOTPEmail(String toEmail, String otp) async {
    final smtpServer = gmail(smtpUsername,
        smtpPassword); // Use the gmail() function for SMTP configuration

    // Create the email message
    final message = Message()
      ..from = Address(smtpUsername, 'ITSA Superapp') // Sender's email address
      ..recipients.add(toEmail) // Recipient's email address
      ..subject = 'Your OTP Code' // Subject of the email
      ..text = 'Your OTP code is: $otp'; // Body of the email

    try {
      // Send the email
      await send(message, smtpServer);
    } catch (e) {
      print('Error sending OTP email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                                  const SizedBox(width: 10),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF291C0E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreSignUpSegmentationPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E473B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        fontSize: 16,
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

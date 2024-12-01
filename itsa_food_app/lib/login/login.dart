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
import 'package:itsa_food_app/login/forgot_pass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Attempt Firebase authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check for admin or super admin access
        Map<String, dynamic>? adminInfo =
            await firebaseService.getAdminInfo(email);
        Map<String, dynamic>? superadInfo =
            await firebaseService.getSuperAdInfo(email);

        if (adminInfo != null && adminInfo.isNotEmpty) {
          // Admin navigation
          String adminEmail = adminInfo['email'] ?? "No Email Provided";
          String branchName = ""; // Placeholder for branch name

          // Determine branch name based on admin email
          if (adminEmail == 'admin1@gmail.com') {
            branchName = "Main Branch Admin";
          } else if (adminEmail == 'admin2@gmail.com') {
            branchName = "Sta. Cruz II Admin";
          } else if (adminEmail == 'admin3@gmail.com') {
            branchName = "San Dionisio Admin";
          }

          // Update provider with admin email
          Provider.of<UserProvider>(context, listen: false)
              .setAdminEmail(adminEmail);

          // Navigate to AdminHome with specific branch name
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHome(
                userName: branchName, // Display branch-specific username
                email: adminEmail,
                imageUrl: "",
              ),
            ),
          );
          return;
        }

        if (superadInfo != null && superadInfo.isNotEmpty) {
          // Super admin navigation
          String superadEmail = superadInfo['email'] ?? "No Email Provided";

          // Pass "Super Admin" as userName
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuperAdminHome(
                userName: "Super Admin", // Super admin name
                email: superadEmail,
                imageUrl: "",
              ),
            ),
          );
          return;
        }

        // If the user is not admin/super admin, proceed with verification
        if (userCredential.user!.emailVerified) {
          // Fetch user info for customer/rider
          Map<String, dynamic>? userInfo =
              await firebaseService.getCurrentUserInfo();

          if (userInfo != null) {
            String userType = userInfo['userType'] ?? "";
            String otp = _generateOTP(); // Generate OTP once

            await _sendOTPEmail(email, otp);

            if (userType == "customer") {
              // Fetch the branchID from the "customer" collection in Firestore
              String? branchID;
              try {
                DocumentSnapshot customerDoc = await FirebaseFirestore.instance
                    .collection('customer')
                    .doc(userInfo['uid'])
                    .get();
                if (customerDoc.exists) {
                  branchID = customerDoc['branchID'] ??
                      ""; // Fetch branchID from Firestore
                }
              } catch (e) {
                setState(() {
                  _errorMessage = "Error fetching branch ID: $e";
                  _isLoading = false;
                });
                return;
              }

              // Navigate to CustomerOTPPage with branchID
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerOTPPage(
                    userName: userInfo['userName'] ?? "Guest User",
                    emailAddress: userInfo['emailAddress'] ?? email,
                    imageUrl: userInfo['imageUrl'] ?? "",
                    uid: userInfo['uid'] ?? "",
                    email: email,
                    userAddress: userInfo['userAddress'] ?? "",
                    latitude: userInfo['userCoordinates']?['latitude'] ?? 0.0,
                    longitude: userInfo['userCoordinates']?['longitude'] ?? 0.0,
                    otp: otp,
                    branchID: branchID ?? "", // Pass branchID
                  ),
                ),
              );
            } else if (userType == "rider") {
              // Rider navigation
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RiderOTPPage(
                    email: userInfo['emailAddress'] ?? email,
                    otp: otp,
                    userName: userInfo['userName'] ?? "Rider",
                    imageUrl: userInfo['imageUrl'] ?? "",
                  ),
                ),
              );
            } else {
              setState(() {
                _errorMessage = "User type is not recognized.";
                _isLoading = false;
              });
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
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Authentication failed.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserType(String email) async {
    try {
      // Check "customer" collection
      var customerSnapshot = await firebaseService
          .getCollection("customer")
          .where("emailAddress", isEqualTo: email)
          .get();
      if (customerSnapshot.docs.isNotEmpty) {
        var customerData =
            customerSnapshot.docs.first.data() as Map<String, dynamic>?;
        if (customerData != null) {
          return customerData[
              'userType']; // Accessing userType only if data() is not null
        }
      }

      // Check "rider" collection
      var riderSnapshot = await firebaseService
          .getCollection("rider")
          .where("emailAddress", isEqualTo: email)
          .get();
      if (riderSnapshot.docs.isNotEmpty) {
        var riderData =
            riderSnapshot.docs.first.data() as Map<String, dynamic>?;
        if (riderData != null) {
          return riderData[
              'userType']; // Accessing userType only if data() is not null
        }
      }

      return null; // No match found
    } catch (e) {
      print("Error fetching user type: $e");
      return null;
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPass(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                      0.6), // Semi-transparent black
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Forgot Password?",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

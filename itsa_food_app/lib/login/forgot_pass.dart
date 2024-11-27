import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/login/login.dart'; // Import LoginPage

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  _ForgotPassState createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final TextEditingController _emailController = TextEditingController();
  String? _feedbackMessage;

  Future<void> _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        _feedbackMessage =
            "Password reset email sent. Please check your inbox.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _feedbackMessage = e.message ?? "An error occurred. Please try again.";
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = "Unexpected error. Please try again later.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/boba_tea_new_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Centered Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with Outline Effect
                  Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 5,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Instruction Text
                  Text(
                    "Enter your email to receive password reset instructions.",
                    style: TextStyle(
                      fontSize: 20, // Slightly larger for readability
                      color: Colors.white
                          .withOpacity(0.9), // Softer than pure white
                      fontWeight:
                          FontWeight.w600, // Emphasize important instructions
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45, // Very light shadow
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  // Email Text Field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.black87),
                      filled: true,
                      fillColor: Colors.white.withOpacity(1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  // Reset Password Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF291C0E),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Send Reset Email",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Feedback Message
                  if (_feedbackMessage != null)
                    Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        color: Colors.lightGreenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 1),
                  // Go Back to Login Text
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Go back to Login",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 5,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:itsa_food_app/services/firebase_service.dart';
import 'package:itsa_food_app/login/login.dart';

class CustomerSignUp extends StatefulWidget {
  const CustomerSignUp({super.key});

  @override
  _CustomerSignUpState createState() => _CustomerSignUpState();
}

class _CustomerSignUpState extends State<CustomerSignUp> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _message; // Error message or notification

  final Map<String, bool> _errors = {
    "firstName": false,
    "lastName": false,
    "email": false,
    "mobileNumber": false,
    "password": false,
  };

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String mobileNumber = _mobileNumberController.text.trim();
    String password = _passwordController.text.trim();

    // Remove the +63 part from the mobile number before saving to Firestore
    if (mobileNumber.startsWith('+63')) {
      mobileNumber = mobileNumber.substring(3); // Strip "+63"
    }

    setState(() {
      // Validate fields
      _errors["firstName"] = firstName.isEmpty;
      _errors["lastName"] = lastName.isEmpty;
      _errors["email"] = email.isEmpty;
      _errors["mobileNumber"] = mobileNumber.isEmpty;
      _errors["password"] = password.isEmpty;

      // Clear the previous message
      _message = null;
    });

    // If any field is empty, show an error and stop
    if (_errors.values.any((error) => error)) {
      setState(() {
        _message = "All fields are required.";
      });
      return;
    }

    try {
      await _firebaseService.signUpWithEmail(
        firstName,
        lastName,
        email,
        mobileNumber,
        password,
        userType: 'customer',
      );
      setState(() {
        _message = "A verification link has been sent to your email.";
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/boba_tea_new_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 250,
                    width: 250,
                  ),
                  const SizedBox(height: 20),
                  // Input Fields
                  _buildTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                    hasError: _errors["firstName"]!,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _lastNameController,
                    hintText: 'Last Name',
                    hasError: _errors["lastName"]!,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    hasError: _errors["email"]!,
                  ),
                  const SizedBox(height: 10),
                  _buildMobileNumberField(),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    hasError: _errors["password"]!,
                  ),
                  const SizedBox(height: 10),
                  // Error Message Styling (below the last field)
                  if (_message != null)
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
                          color: _message!.contains("verification")
                              ? Colors
                                  .green // Green border for success messages
                              : Colors.redAccent, // Red border for errors
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _message!.contains("verification")
                                ? Icons
                                    .check_circle_outline // Green checkmark for success
                                : Icons
                                    .error_outline, // Red exclamation for errors
                            color: _message!.contains("verification")
                                ? Colors.green // Green icon for success
                                : Colors.redAccent, // Red icon for errors
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
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

                  const SizedBox(height: 20),
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity, // Full width
                    child: ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3E36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Go Back to Login Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Go back to Login",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 255, 255, 255),
                        decoration: TextDecoration.underline,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required bool hasError, // Indicates whether this field has an error
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withOpacity(1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 2) // Red outline
              : BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildMobileNumberField() {
    return TextField(
      controller: _mobileNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Mobile Number',
        prefixText: '+63 ', // Always show +63
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: _errors["mobileNumber"]!
              ? const BorderSide(color: Colors.red, width: 2) // Red outline
              : BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      onChanged: (value) {
        // Remove the +63 prefix and leading zero if present
        if (value.startsWith('+63')) {
          _mobileNumberController.text = value.substring(3); // Remove +63
        } else if (value.startsWith('0')) {
          // Remove the leading zero for local number input
          _mobileNumberController.text =
              value.substring(1); // Remove leading zero
        }

        // Keep the cursor at the end of the text
        _mobileNumberController.selection = TextSelection.fromPosition(
          TextPosition(offset: _mobileNumberController.text.length),
        );
      },
    );
  }
}

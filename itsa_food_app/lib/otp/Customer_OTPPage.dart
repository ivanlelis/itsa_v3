import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerOTPPage extends StatefulWidget {
  final String email;
  const CustomerOTPPage({super.key, required this.email});

  @override
  State<CustomerOTPPage> createState() => _CustomerOTPPageState();
}

class _CustomerOTPPageState extends State<CustomerOTPPage> {
  final _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _errorMessage;
  bool _isLoading = false;
  String? _verificationId;
  String? mobileNumber;

  bool get _hasError => _errorMessage != null;

  // Send OTP to the user's phone number
  void _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Query Firestore to find the document with the matching email
      var customerSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .where('emailAddress', isEqualTo: widget.email)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        // Retrieve the mobile number from the matching document
        mobileNumber = customerSnapshot.docs.first['mobileNumber'];

        if (mobileNumber == null) {
          setState(() {
            _errorMessage = "No mobile number found for this email.";
            _isLoading = false;
          });
          return;
        }

        // Debug: print the mobile number value for troubleshooting
        print("Mobile Number from Firestore: $mobileNumber");

        // Ensure no extra spaces in the mobile number string
        mobileNumber = mobileNumber!.trim();

        // Debug: check if the phone number has the correct format
        if (mobileNumber!.length == 13 && mobileNumber!.startsWith("+63")) {
          print("Phone number is in correct E.164 format: $mobileNumber");

          // Directly use the mobile number without modification
          await _auth.verifyPhoneNumber(
            phoneNumber: mobileNumber!,
            timeout: const Duration(seconds: 60),
            verificationCompleted: (PhoneAuthCredential credential) async {
              await _auth.signInWithCredential(credential);
              Fluttertoast.showToast(msg: "Phone number verified!");
              Navigator.pushReplacementNamed(context, '/home');
            },
            verificationFailed: (FirebaseAuthException e) {
              setState(() {
                _errorMessage = e.message;
                _isLoading = false;
              });
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _verificationId = verificationId;
                _isLoading = false;
              });
              Fluttertoast.showToast(msg: "OTP Sent!");
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              setState(() {
                _verificationId = verificationId;
                _isLoading = false;
              });
            },
          );
        } else {
          setState(() {
            _errorMessage =
                "The phone number is in an incorrect format. Please check the number.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "No customer found with this email address.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
        _isLoading = false;
      });
    }
  }

  // Verify OTP entered by the user
  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String otp = _otpController.text.trim();

    // Validate OTP
    if (otp.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the OTP.";
        _isLoading = false;
      });
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      Fluttertoast.showToast(msg: "Phone number verified!");
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _errorMessage = "Invalid OTP. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sendOTP(); // Automatically send OTP when the page loads
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevent resizing when the keyboard appears
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
                          // OTP Field
                          TextField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              hintText: "Enter OTP",
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
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
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
                    onPressed: _isLoading ? null : _verifyOTP,
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
                            "Verify OTP",
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
                      // Navigate back to login screen
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E473B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Back to Login",
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

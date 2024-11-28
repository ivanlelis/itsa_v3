import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:itsa_food_app/main_home/rider_home.dart';

class RiderOTPPage extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;
  final String otp;

  const RiderOTPPage({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
    required this.otp,
  });

  @override
  State<RiderOTPPage> createState() => _RiderOTPPageState();
}

class _RiderOTPPageState extends State<RiderOTPPage> {
  final _otpController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  bool get _hasError => _errorMessage != null;

  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the OTP.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if the entered OTP matches the one sent
      if (otp == widget.otp) {
        // OTP is correct, navigate to RiderDashboard
        Fluttertoast.showToast(msg: "OTP verified!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiderDashboard(
              userName: widget.userName,
              email: widget.email,
              imageUrl: widget.imageUrl,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Invalid OTP. Please try again.";
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

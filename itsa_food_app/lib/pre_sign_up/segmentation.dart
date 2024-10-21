import 'package:flutter/material.dart';
import 'package:itsa_food_app/sign_up/customer_sign_up.dart';
import 'package:itsa_food_app/sign_up/rider_sign_up.dart';

class PreSignUpSegmentationPage extends StatelessWidget {
  const PreSignUpSegmentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up as Customer or Rider"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to customer sign-up page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerSignUp(),
                  ),
                );
              },
              child: const Text("Sign Up as Customer"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to rider sign-up page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiderSignUp(),
                  ),
                );
              },
              child: const Text("Sign Up as Rider"),
            ),
          ],
        ),
      ),
    );
  }
}

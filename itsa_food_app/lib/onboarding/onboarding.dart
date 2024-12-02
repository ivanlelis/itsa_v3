import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itsa_food_app/home/home.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Function to mark onboarding as complete
  _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true); // Mark as true
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Our App!"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to our app! This is your first time here.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Mark onboarding complete and navigate to home
                await _markOnboardingComplete();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text("Start Using the App"),
            ),
          ],
        ),
      ),
    );
  }
}

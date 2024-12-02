import 'package:flutter/material.dart';
import 'package:itsa_food_app/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      body: PageView(
        children: [
          // Page 1
          _buildOnboardingPage(
            context,
            image: 'assets/images/ONBOARDING_1.png',
            title: 'Satisfy Your Cravings',
            description:
                'Indulge in the finest milk tea and takoyaki, delivered to your door!',
          ),
          // Page 2
          _buildOnboardingPage(
            context,
            image: 'assets/images/ONBOARDING_2.png',
            title: 'Order with Ease',
            description:
                'Browse through our delicious menu and place your order within seconds.',
          ),
          // Page 3
          _buildOnboardingPage(
            context,
            image: 'assets/images/ONBOARDING_3.png',
            title: 'Fast Delivery to You',
            description:
                'Get your favorite treats delivered fresh and hot, right to your doorstep.',
            isLastPage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context, {
    required String image,
    required String title,
    required String description,
    bool isLastPage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(image),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // Aligning the title text
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center, // Aligning the description text
          ),
          if (isLastPage) ...[
            const SizedBox(height: 40),
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MainHome extends StatelessWidget {
  const MainHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout logic here
              // For example, you might want to sign out the user and navigate back to login
              // FirebaseAuth.instance.signOut();
              Navigator.pop(
                  context); // Navigate back to the previous screen (login)
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Main Home!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement your functionality here
                // For example, navigate to another screen
              },
              child: const Text("Do Something"),
            ),
          ],
        ),
      ),
    );
  }
}

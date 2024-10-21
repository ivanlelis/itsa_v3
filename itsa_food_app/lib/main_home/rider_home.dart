import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/rider_sidebar.dart';

class RiderMainHome extends StatelessWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const RiderMainHome({
    Key? key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Home'),
      ),
      drawer: RiderDrawer(
        userName: userName,
        email: email,
        imageUrl: imageUrl,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const NetworkImage('https://example.com/placeholder.png'),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Email: $email',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to current deliveries or tasks page
              },
              icon: const Icon(Icons.delivery_dining),
              label: const Text('View Current Deliveries'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to delivery history page
              },
              icon: const Icon(Icons.history),
              label: const Text('View Delivery History'),
            ),
          ],
        ),
      ),
    );
  }
}

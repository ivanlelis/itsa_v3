import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Sidebar extends StatelessWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const Sidebar({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(userName),
          accountEmail: Text(email),
          currentAccountPicture: CircleAvatar(
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const NetworkImage(
                    'https://example.com/placeholder.png'), // Use your placeholder image URL
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Order History'),
          onTap: () {
            // Navigate to Order History page
            Navigator.pushNamed(context, '/orderHistory');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {
            // Navigate to Profile page
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Address'),
          onTap: () {
            // Navigate to Address page
            Navigator.pushNamed(context, '/address');
          },
        ),
        ListTile(
          leading: const Icon(Icons.card_giftcard),
          title: const Text('Vouchers'),
          onTap: () {
            // Navigate to Vouchers page
            Navigator.pushNamed(context, '/vouchers');
          },
        ),
        ListTile(
          leading: const Icon(Icons.contact_mail),
          title: const Text('Contact Us'),
          onTap: () {
            // Navigate to Contact Us page
            Navigator.pushNamed(context, '/contactUs');
          },
        ),
        const Divider(), // Adds a divider line between sections
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            // Navigate back to Login page
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
      ],
    );
  }
}

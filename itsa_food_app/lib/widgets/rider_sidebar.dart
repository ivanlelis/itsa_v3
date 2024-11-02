// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiderDrawer extends StatelessWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const RiderDrawer({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const NetworkImage('https://example.com/placeholder.png'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delivery_dining),
            title: const Text('Current Deliveries'),
            onTap: () {
              // Navigate to current deliveries page
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Delivery History'),
            onTap: () {
              // Navigate to delivery history page
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              // Navigate to profile page
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate back to Home page and clear all previous routes
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

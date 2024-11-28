// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:itsa_food_app/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/admin_pages/create_vouchers.dart';
import 'package:itsa_food_app/admin_pages/scratch&win.dart';

class AdminSidebar extends StatelessWidget {
  final VoidCallback onLogout; // Callback for logout action

  const AdminSidebar({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF6E473B), // Updated color
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Welcome, Admin!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.discount),
            title: const Text('Create Vouchers'),
            onTap: () {
              // Navigate to CreateVouchers screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Vouchers()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Mini Games'),
            onTap: () {
              // Navigate to CreateVouchers screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScratchCardGrid()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Menu Management'),
            onTap: () {
              // Navigate to Menu Management
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('User Management'),
            onTap: () {
              // Navigate to User Management
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Reports'),
            onTap: () {
              // Navigate to Reports
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to Settings
            },
          ),
          const Divider(), // A divider for visual separation
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              _showLogoutConfirmationDialog(
                  context); // Show confirmation dialog
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog if No
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _logout(context); // Pass context to the logout function
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Accept context as a parameter
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      // Navigate to Home page without a back button
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      // Handle logout errors if needed
      print("Error logging out: $e");
    }
  }
}

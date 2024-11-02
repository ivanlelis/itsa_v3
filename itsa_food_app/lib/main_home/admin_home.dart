// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart'; // Import the sidebar widget
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';

class AdminHome extends StatefulWidget {
  final String userName;
  final String email; // Add email here
  final String imageUrl;

  const AdminHome({
    super.key,
    this.userName = "Admin", // Default username for Admin
    required this.email, // Make email a required parameter
    this.imageUrl = '', // Default empty string for imageUrl
  });

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0; // Keep track of the selected index

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic based on index
  }

  void _logout() {
    // Implement your logout logic here
    // For example, FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/home'); // Navigate to home.dart
  }

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Non-const key

  @override
  Widget build(BuildContext context) {
    final adminEmail =
        Provider.of<UserProvider>(context).adminEmail; // Retrieve admin email

    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.imageUrl.isNotEmpty
                    ? NetworkImage(widget.imageUrl)
                    : const NetworkImage('https://example.com/placeholder.png'),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${widget.userName}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Email: $adminEmail', // Use email from UserProvider
                style: const TextStyle(fontSize: 16),
              ),
              // Other UI elements...
            ],
          ),
        ),
      ),
      drawer: AdminSidebar(onLogout: _logout),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/superad_navbar.dart'; // Your Bottom Nav Bar widget
import 'package:itsa_food_app/superad_pages/inv_mgmt.dart'; // Inventory Management screen
import 'package:itsa_food_app/widgets/superad_appbar.dart'; // Import the new AppBar widget

class SuperAdminHome extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const SuperAdminHome({
    super.key,
    this.userName = "Admin",
    required this.email,
    this.imageUrl = '',
  });

  @override
  _SuperAdminHomeState createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends State<SuperAdminHome> {
  int _selectedIndex = 0;

  // A list of widgets to display based on the selected index
  final List<Widget> _pages = [
    // Placeholder for the Home page
    Center(
      child: Text(
        'Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // Placeholder for the Analytics page
    Center(
      child: Text(
        'Analytics Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // Inventory Management page (no navbar included here)
    InvMgmt(),
    // Profile page
    Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SuperAdminAppBar(), // Use the SuperAdminAppBar widget here
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.brown,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Add other drawer items as needed
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar:
          _selectedIndex == 2 // Do not show BottomNavBar for InvMgmt
              ? null // Set null if the Inventory page is active
              : SuperAdNavBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
    );
  }
}

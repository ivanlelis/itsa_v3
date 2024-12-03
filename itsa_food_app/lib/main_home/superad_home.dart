import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/superad_navbar.dart'; // Your Bottom Nav Bar widget
import 'package:itsa_food_app/superad_pages/inv_mgmt.dart'; // Inventory Management screen
import 'package:itsa_food_app/widgets/superad_appbar.dart'; // Import the new AppBar widget
import 'package:itsa_food_app/superad_pages/dashboard.dart';
import 'package:itsa_food_app/widgets/superad_sidebar.dart'; // Import the new Sidebar widget

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

  late List<Widget> _pages; // Use `late` to initialize this later

  @override
  void initState() {
    super.initState();
    // Initialize _pages in initState where widget is accessible
    _pages = [
      SuperAdDashboard(
        userName: widget.userName,
        email: widget.email,
        imageUrl: widget.imageUrl,
      ),
      Center(
        child: Text(
          'Charts',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      InvMgmt(),
      Center(
        child: Text(
          'Profile Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SuperAdminAppBar(), // Use the SuperAdminAppBar widget here
      drawer: const SuperAdSidebar(), // Use the separate sidebar here
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

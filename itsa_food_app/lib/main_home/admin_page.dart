import 'package:flutter/material.dart';
import 'admin_home.dart'; // Import the AdminHome page
import 'package:itsa_food_app/admin_pages/menu_mgmt.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0; // Track the selected index

  // Create the pages only once
  final List<Widget> _pages = [
    AdminHome(email: "your_email@example.com"), // Home page
    Center(child: Text('Orders Page')), // Placeholder for Orders page
    MenuManagement(), // Menu Management page
    Center(child: Text('Users Page')), // Placeholder for Users page
  ];

  // AppBar widget
  AppBar get _appBar {
    return AppBar(
      title: const Text('Admin Dashboard'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar, // Fixed AppBar
      body: IndexedStack(
        index: _selectedIndex, // Maintain the selected page
        children: _pages, // List of pages to switch between
      ),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index
          });
        },
      ),
    );
  }
}

class AdminBottomNavBar extends StatelessWidget {
  final int selectedIndex; // Index of the currently selected icon
  final Function(int) onItemTapped; // Callback function when an icon is tapped

  const AdminBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Users',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index != selectedIndex) {
          // Only update if the index is different
          onItemTapped(
              index); // Call the onItemTapped function to update the index
        }
      },
      type: BottomNavigationBarType.fixed, // Keeps all items visible
    );
  }
}

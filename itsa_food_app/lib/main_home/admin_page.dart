import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package
import 'admin_home.dart'; // Import the AdminHome page
import 'package:itsa_food_app/admin_pages/menu_mgmt.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:itsa_food_app/home/home.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0; // Track the selected index
  String _adminEmail = "Loading..."; // Default email text

  // Create the pages only once
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _fetchAdminEmail(); // Fetch admin email when the page initializes
  }

  Future<void> _fetchAdminEmail() async {
    try {
      // Fetch admin document from Firestore
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin') // Update with your actual collection name
          .doc('admin_1') // Replace with the document ID of the admin
          .get();

      if (adminDoc.exists) {
        setState(() {
          _adminEmail =
              adminDoc['email']; // Get the email field from the document
        });
      } else {
        setState(() {
          _adminEmail =
              "Admin not found"; // Handle case where admin document doesn't exist
        });
      }
    } catch (e) {
      setState(() {
        _adminEmail = "Error fetching email"; // Handle errors
      });
      print("Error fetching admin email: $e");
    }
  }

  // Logout method
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      print("User signed out successfully."); // Debug statement
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) =>
                const HomePage(title: 'Firebase Connection Status')),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      // Handle logout errors if needed
      print("Error logging out: $e");
    }
  }

  // AppBar widget
  AppBar get _appBar {
    return AppBar(
      title: const Text('Admin Dashboard'),
    );
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      AdminHome(email: _adminEmail), // Home page with fetched email
      Center(child: Text('Orders Page')), // Placeholder for Orders page
      MenuManagement(), // Menu Management page
      Center(child: Text('Users Page')), // Placeholder for Users page
    ];

    return Scaffold(
      appBar: _appBar, // Fixed AppBar
      drawer: AdminSidebar(
          onLogout: _showLogoutConfirmationDialog), // Add AdminSidebar
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome, Admin!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge, // Changed to titleLarge
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _adminEmail, // Display the admin's email
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium, // Changed to bodyMedium
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex, // Maintain the selected page
              children: _pages, // List of pages to switch between
            ),
          ),
        ],
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

  void _showLogoutConfirmationDialog() {
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
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(); // Call the logout function
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
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

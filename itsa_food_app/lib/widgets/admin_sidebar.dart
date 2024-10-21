import 'package:flutter/material.dart';

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
              color: Colors.deepPurple,
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
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              // Navigate to Dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Order Management'),
            onTap: () {
              // Navigate to Order Management
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
            onTap: onLogout, // Call the logout function
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
// Import for SystemNavigator.pop to exit the app

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
      child: Container(
        color: Colors.deepOrangeAccent,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Sidebar Header (Optional)
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepOrangeAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the userName
                  Text(
                    'Hello, $userName', // Display the user's name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10), // Space between userName and 'Menu'
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Add your menu items here
            ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Handle navigation
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Handle navigation
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: Colors.white),
              title: Text('Help', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Handle navigation
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            // Log out option
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.white),
              title: Text('Log out', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Show the confirmation dialog before logging out
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for logging out
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog when "No" is pressed
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                // Perform log out action here, e.g., navigate to login screen
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacementNamed(
                    context, '/home'); // Navigate to login screen

                // Optionally, clear user session data (if any)
                // Example: SharedPreferences.clear(), etc.
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}

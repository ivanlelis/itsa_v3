import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey; // Key for accessing Scaffold

  const AdminAppBar({
    super.key,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple, // Change as needed
      toolbarHeight: 80, // Adjust height if needed
      leading: IconButton(
        icon: const Icon(Icons.menu,
            color: Colors.white), // Set burger icon color to white
        onPressed: () {
          scaffoldKey.currentState?.openDrawer(); // Open the drawer (sidebar)
        },
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications,
              color: Colors.white), // Set notification icon color to white
          onPressed: () {
            // Handle notification button press
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
        const SizedBox(
            width: 16), // Add some space between the button and the edge
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80); // Set preferred height
}

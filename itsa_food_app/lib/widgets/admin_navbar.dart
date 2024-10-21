import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/menu_mgmt.dart'; // Import the MenuManagement page
import 'package:itsa_food_app/main_home/admin_home.dart'; // Import the AdminHome page

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
        if (index == selectedIndex) {
          // If the tapped index is the same as the current index, do nothing
          return;
        }

        if (index == 0) {
          // If the home item is tapped, navigate to AdminHome
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => AdminHome(
                    email:
                        "your_email@example.com")), // Replace with actual email
          );
        } else if (index == 2) {
          // If the menu item is tapped, navigate to MenuManagement
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuManagement()),
          );
        } else {
          // For other items, call the provided function
          onItemTapped(index);
        }
      },
      type: BottomNavigationBarType.fixed, // Keeps all items visible
    );
  }
}

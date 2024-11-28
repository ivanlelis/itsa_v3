import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/menu_mgmt.dart';
import 'package:itsa_food_app/admin_pages/orders_mgmt.dart';
import 'package:itsa_food_app/main_home/admin_home.dart';
import 'package:itsa_food_app/admin_pages/user_mgmt.dart';

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
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: _buildNavItem(Icons.home, 0),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildNavItem(Icons.note, 1),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: _buildNavItem(Icons.grid_view, 2),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: _buildNavItem(Icons.person, 3),
          label: 'Users',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: const Color(0xFF291C0E), // Updated selected icon color
      unselectedItemColor: const Color(0xFF291C0E),
      onTap: (index) {
        if (index == selectedIndex) {
          return; // Prevent redundant navigation
        }

        // Navigation logic based on index
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AdminHome(email: "your_email@example.com")),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OrdersManagement()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuManagement()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserManagement()),
          );
        } else {
          onItemTapped(index);
        }
      },
      type: BottomNavigationBarType.fixed,
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;
    return Container(
      decoration: isSelected
          ? BoxDecoration(
              color: const Color(0xFFA78D78), // Circle color (adjust as needed)
              shape: BoxShape.circle,
            )
          : null,
      padding: const EdgeInsets.all(8), // Space around the icon
      child: Icon(icon,
          color: isSelected
              ? const Color(0xFF291C0E)
              : const Color(0xFF291C0E) // Icon color
          ),
    );
  }
}

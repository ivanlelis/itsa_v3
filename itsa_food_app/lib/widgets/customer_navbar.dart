import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        _buildNavItem(Icons.home, 'Home', 0),
        _buildNavItem(Icons.grid_view, 'Menu', 1),
        _buildNavItem(Icons.fastfood, 'Build Your Meal', 2),
        _buildNavItem(Icons.person, 'User', 3),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Color(0xFF291C0E), // Dark brown for text color
      unselectedItemColor: Color(0xFF291C0E), // Beige for unselected items
      backgroundColor: Color(0xFFE1D4C2), // Lightest beige for background
      onTap: onTap,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF6E473B),
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        color: Color(0xFF6E473B),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: currentIndex == index
          ? Container(
              decoration: BoxDecoration(
                color: Color(0xFFA78D78), // Dark brown for circle background
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8), // Adjust padding for the circle size
              child: Icon(
                icon,
                size: 28, // Icon size inside the circle
                color: Color(0xFF291C0E), // Light beige for icon color
              ),
            )
          : Icon(icon), // Default icon when not selected
      label: label,
    );
  }
}

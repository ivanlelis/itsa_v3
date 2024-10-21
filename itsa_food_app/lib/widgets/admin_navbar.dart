import 'package:flutter/material.dart';

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
      onTap: onItemTapped, // Call the provided function when tapped
      type: BottomNavigationBarType.fixed, // Keeps all items visible
    );
  }
}

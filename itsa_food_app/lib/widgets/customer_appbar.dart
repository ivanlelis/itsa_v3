import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey; // Key for accessing Scaffold
  final VoidCallback onCartPressed; // Callback for the cart icon

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple, // Change as needed
      toolbarHeight: 80, // Adjust height if needed
      leading: IconButton(
        icon: const Icon(Icons.menu),
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
          icon: const Icon(Icons.shopping_cart),
          onPressed: onCartPressed, // Call the function passed from parent
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80); // Set preferred height
}

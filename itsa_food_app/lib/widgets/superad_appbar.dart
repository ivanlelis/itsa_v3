import 'package:flutter/material.dart';

class SuperAdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SuperAdminAppBar({super.key});

  @override
  _SuperAdminAppBarState createState() => _SuperAdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SuperAdminAppBarState extends State<SuperAdminAppBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.brown,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      elevation: 0,
      title: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            // Implement your search logic here
          },
        ),
      ),
    );
  }
}

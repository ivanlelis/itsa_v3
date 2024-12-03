import 'package:flutter/material.dart';

class SuperAdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SuperAdminAppBar({super.key});

  @override
  _SuperAdminAppBarState createState() => _SuperAdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SuperAdminAppBarState extends State<SuperAdminAppBar> {
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
    );
  }
}

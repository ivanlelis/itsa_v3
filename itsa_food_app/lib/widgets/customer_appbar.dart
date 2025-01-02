import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onCartPressed;
  final String? userName;
  final String? uid;

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onCartPressed,
    this.userName,
    this.uid,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80); // Set preferred height

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6E473B),
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.menu,
            color: Colors.white), // White burger menu icon
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('customer')
              .doc(uid)
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: onCartPressed,
              );
            }

            int itemCount = snapshot.data!.docs.length;

            return Stack(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: onCartPressed,
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

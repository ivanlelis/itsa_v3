import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onCartPressed;
  final String userName;

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onCartPressed,
    required this.userName,
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
        // Add StreamBuilder to monitor cart changes
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('customer')
              .doc(userName) // Use userName to fetch the correct cart
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            int itemCount = 0; // Default item count

            if (snapshot.hasData) {
              // Update itemCount if data is available
              itemCount = snapshot.data!.docs.length;
            }

            return Stack(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: onCartPressed,
                ),
                if (itemCount > 0) // Show badge if there are items in the cart
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
                        '$itemCount', // Display the number of items
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

  @override
  Size get preferredSize => const Size.fromHeight(80); // Set preferred height
}

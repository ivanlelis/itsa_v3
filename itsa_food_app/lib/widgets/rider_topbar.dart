import 'package:flutter/material.dart';

Widget buildTopBar(BuildContext context) {
  return Positioned(
    top: 40,
    left: 16,
    right: 16,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Smaller Menu Icon in White Rounded Square Container
        Container(
          width: 40, // Set a smaller fixed width and height
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.menu,
                color: Colors.deepOrangeAccent, size: 20), // Reduced icon size
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer (sidebar)
            },
          ),
        ),
        Stack(
          children: [
            Container(
              width: 40, // Reduced width
              height: 40, // Reduced height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications,
                    color: Colors.deepOrangeAccent, size: 20),
                onPressed: () {},
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 15, // Adjust width and height to make the badge a circle
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10), // Circular badge
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

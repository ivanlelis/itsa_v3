import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/admin_notifs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AdminAppBar({
    super.key,
    required this.scaffoldKey,
  });

  @override
  _AdminAppBarState createState() => _AdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _AdminAppBarState extends State<AdminAppBar> {
  int unreadNotificationCount = 0; // Total unread notifications
  DateTime lastCheckedTime = DateTime.now(); // Track the last checked time
  Set<String> notifiedOrderIds = {}; // Track notified orders

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
  }

  // Fetch unread notifications count
  Future<void> _fetchUnreadNotifications() async {
    FirebaseFirestore.instance
        .collectionGroup('orders')
        .snapshots()
        .listen((snapshot) {
      int newNotifications = 0; // Count of new notifications since last checked

      for (var doc in snapshot.docs) {
        String orderId = doc.id; // Use document ID as unique identifier
        Timestamp timestamp = doc['timestamp'];

        // Check if the notification is new and hasn't been counted yet
        if (timestamp.toDate().isAfter(lastCheckedTime) &&
            !notifiedOrderIds.contains(orderId)) {
          newNotifications++;
          notifiedOrderIds.add(orderId); // Add to the set of notified orders
        }
      }

      setState(() {
        unreadNotificationCount +=
            newNotifications; // Increment the total count without limit
      });
    });
  }

  // Reset unread notifications count when admin views them
  void _markNotificationsAsRead() {
    setState(() {
      unreadNotificationCount = 0; // Reset the count
      lastCheckedTime = DateTime.now(); // Update last checked time to now
      notifiedOrderIds.clear(); // Clear the set of notified orders
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          widget.scaffoldKey.currentState?.openDrawer();
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
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                // Navigate to AdminNotifs page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminNotifs()),
                ).then((_) {
                  _markNotificationsAsRead(); // Reset notification count here
                });
              },
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadNotificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

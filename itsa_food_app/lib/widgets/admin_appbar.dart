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

  // Fetch unread notifications count from Firestore
  Future<void> _fetchUnreadNotifications() async {
    final userDoc =
        FirebaseFirestore.instance.collection('admin').doc('admin_1');
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      // Get lastCheckedTime and unreadNotificationCount from Firestore
      lastCheckedTime = (docSnapshot['lastCheckedTime'] as Timestamp).toDate();
      unreadNotificationCount = docSnapshot['unreadNotificationCount'];

      // Fetch notifications based on lastCheckedTime
      FirebaseFirestore.instance
          .collectionGroup('orders')
          .snapshots()
          .listen((snapshot) {
        int newNotifications = 0;

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
          unreadNotificationCount += newNotifications; // Update unread count
        });
      });
    }
  }

  // Update lastCheckedTime only when admin clicks on the notification
  void _markNotificationsAsRead() {
    setState(() {
      unreadNotificationCount = 0;
      lastCheckedTime = DateTime.now(); // Update only when admin clicks
      notifiedOrderIds.clear();
    });

    // Save data to Firestore
    _saveNotificationData();
  }

  // Save unread notification count and last checked time to Firestore
  Future<void> _saveNotificationData() async {
    final userDoc =
        FirebaseFirestore.instance.collection('admin').doc('admin_1');
    await userDoc.update({
      'unreadNotificationCount': unreadNotificationCount,
      'lastCheckedTime': Timestamp.fromDate(lastCheckedTime),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF6E473B), // Updated color
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminNotifs()),
                ).then((_) {
                  _markNotificationsAsRead(); // Update lastCheckedTime when clicked
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

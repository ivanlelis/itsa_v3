import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/admin_pages/order_details.dart';

class AdminNotifs extends StatefulWidget {
  const AdminNotifs({super.key});

  @override
  _AdminNotifsState createState() => _AdminNotifsState();
}

class _AdminNotifsState extends State<AdminNotifs> {
  late Future<List<OrderCard>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders(); // Initial fetch of orders
  }

  Future<List<OrderCard>> fetchOrders() async {
    List<OrderCard> orderCards = [];

    // Fetch all notifications from the root-level "notifications" collection
    QuerySnapshot notificationsSnapshot =
        await FirebaseFirestore.instance.collection('notifications').get();

    // Fetch all customers at once for more efficiency
    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    // Create a map of customer documents to quickly access user data by uid
    Map<String, Map<String, dynamic>> customersMap = {};
    for (var customerDoc in customerSnapshot.docs) {
      customersMap[customerDoc.id] = customerDoc.data() as Map<String, dynamic>;
    }

    // Batch fetch all orders for all customers in parallel
    List<Future<QuerySnapshot>> orderFutures = [];
    for (var customerDoc in customerSnapshot.docs) {
      orderFutures.add(FirebaseFirestore.instance
          .collection('customer')
          .doc(customerDoc.id)
          .collection('orders')
          .get());
    }

    // Wait for all orders to be fetched in parallel
    List<QuerySnapshot> ordersSnapshots = await Future.wait(orderFutures);

    // Iterate over notifications and corresponding orders
    for (var notificationDoc in notificationsSnapshot.docs) {
      var notificationData = notificationDoc.data() as Map<String, dynamic>;
      String orderID = notificationDoc.id;

      String userName = 'Unknown User';
      String emailAddress = 'Unknown Email';

      // Iterate over the orders snapshots for each customer
      for (int i = 0; i < ordersSnapshots.length; i++) {
        var ordersSnapshot = ordersSnapshots[i];

        // Search for the order matching orderID
        for (var orderDoc in ordersSnapshot.docs) {
          if (orderDoc.id == orderID) {
            // Match found, get the userName and emailAddress from the customer document
            var customerData = customersMap[customerSnapshot.docs[i].id]!;
            userName = customerData['userName'] ?? 'Unknown User';
            emailAddress = customerData['emailAddress'] ?? 'Unknown Email';

            // Add OrderCard with userName and emailAddress
            orderCards.add(
              OrderCard(
                orderID: orderID,
                userName: userName,
                emailAddress: emailAddress,
                deliveryType: notificationData['deliveryType'] ?? 'N/A',
                paymentMethod: notificationData['paymentMethod'] ?? 'N/A',
                voucherCode: notificationData['voucherCode'] ?? 'No Voucher',
                totalAmount:
                    (notificationData['totalAmountWithDelivery']?.toDouble() ??
                        0.0),
                productNames:
                    List<String>.from(notificationData['productNames'] ?? []),
                timestamp:
                    (notificationData['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                orderType: notificationData['orderType'] ?? 'N/A',
                uid: customerSnapshot
                    .docs[i].id, // Using customerDoc.id as the uid
              ),
            );
            break;
          }
        }
      }
    }

    return orderCards;
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = fetchOrders(); // Refetch orders on refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Notifications'),
        backgroundColor: Color(0xFF2E0B0D),
      ),
      body: FutureBuilder<List<OrderCard>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView(
              children: snapshot.data!,
            ),
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderID;
  final String userName;
  final String emailAddress;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmount;
  final List<String> productNames;
  final DateTime timestamp;
  final String orderType;
  final String uid;

  const OrderCard({
    super.key,
    required this.orderID,
    required this.userName,
    required this.emailAddress,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmount,
    required this.productNames,
    required this.timestamp,
    required this.orderType,
    required this.uid,
  });

  void _navigateToOrderDetails(BuildContext context) {
    // Navigate to the OrderDetailsScreen, passing orderID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          uid: uid,
          orderID: orderID,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('User: $userName'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _navigateToOrderDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E0B0D),
                ),
                child: Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

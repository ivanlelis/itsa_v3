import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/admin_pages/order_details.dart';

class PendingOrderNotifications extends StatefulWidget {
  const PendingOrderNotifications({super.key});

  @override
  _PendingOrderNotificationsState createState() =>
      _PendingOrderNotificationsState();
}

class _PendingOrderNotificationsState extends State<PendingOrderNotifications> {
  late Future<List<OrderCard>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchPendingOrders(); // Initial fetch of pending orders
  }

  Future<List<OrderCard>> fetchPendingOrders() async {
    List<OrderCard> orderCards = [];

    // Fetch all customers
    QuerySnapshot customersSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    // Create a map of customer documents to quickly access user data by uid
    Map<String, Map<String, dynamic>> customersMap = {};
    for (var customerDoc in customersSnapshot.docs) {
      customersMap[customerDoc.id] = customerDoc.data() as Map<String, dynamic>;
    }

    // Batch fetch all orders for all customers in parallel
    List<Future<QuerySnapshot>> orderFutures = [];
    for (var customerDoc in customersSnapshot.docs) {
      orderFutures.add(FirebaseFirestore.instance
          .collection('customer')
          .doc(customerDoc.id)
          .collection('orders')
          .where('status', isEqualTo: 'pending') // Filter for pending orders
          .get());
    }

    // Wait for all orders to be fetched in parallel
    List<QuerySnapshot> ordersSnapshots = await Future.wait(orderFutures);

    // Iterate over the orders snapshots and customer data
    for (int i = 0; i < ordersSnapshots.length; i++) {
      var ordersSnapshot = ordersSnapshots[i];
      var customerData = customersMap[customersSnapshot.docs[i].id]!;

      for (var orderDoc in ordersSnapshot.docs) {
        var orderData = orderDoc.data() as Map<String, dynamic>;
        String orderID = orderDoc.id;

        // Get the customer details for the userName and emailAddress
        String userName = customerData['userName'] ?? 'Unknown User';
        String emailAddress = customerData['emailAddress'] ?? 'Unknown Email';

        // Add OrderCard with userName and emailAddress
        orderCards.add(
          OrderCard(
            orderID: orderID,
            userName: userName,
            emailAddress: emailAddress,
            deliveryType: orderData['deliveryType'] ?? 'N/A',
            paymentMethod: orderData['paymentMethod'] ?? 'N/A',
            voucherCode: orderData['voucherCode'] ?? 'No Voucher',
            totalAmount:
                (orderData['totalAmountWithDelivery']?.toDouble() ?? 0.0),
            productNames: List<String>.from(orderData['productNames'] ?? []),
            timestamp: (orderData['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            orderType: orderData['orderType'] ?? 'N/A',
            uid:
                customersSnapshot.docs[i].id, // Using customerDoc.id as the uid
          ),
        );
      }
    }

    return orderCards;
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = fetchPendingOrders(); // Refetch pending orders on refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 600, // Adjusted the height of the modal to 600
      child: Column(
        children: [
          // Pending Orders Label
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Pending Orders',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // FutureBuilder for orders
          Expanded(
            child: FutureBuilder<List<OrderCard>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No pending orders available.'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: ListView(
                    children: snapshot.data!,
                  ),
                );
              },
            ),
          ),
        ],
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
    // Navigate to the OrderDetailsScreen, passing orderID and uid
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('User: $userName'),
            Text('Email: $emailAddress'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _navigateToOrderDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E0B0D),
                ),
                child: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

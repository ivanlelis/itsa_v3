import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // Fetch all customer documents
    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    for (var customerDoc in customerSnapshot.docs) {
      String userName = customerDoc['userName'] ?? 'Unknown User';

      // Fetch orders for each customer
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(customerDoc.id)
          .collection('orders')
          .get();

      for (var orderDoc in ordersSnapshot.docs) {
        var orderData = orderDoc.data() as Map<String, dynamic>;
        String orderId = orderDoc.id;

        orderCards.add(
          OrderCard(
            orderId: orderId,
            userName: userName,
            deliveryType: orderData['deliveryType'] ?? 'N/A',
            paymentMethod: orderData['paymentMethod'] ?? 'N/A',
            voucherCode: orderData['voucherCode'] ?? 'No Voucher',
            totalAmount:
                (orderData['totalAmountWithDelivery']?.toDouble() ?? 0.0),
            productNames: List<String>.from(orderData['productNames'] ?? []),
            timestamp: (orderData['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
        );
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
  final String orderId;
  final String userName;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmount;
  final List<String> productNames;
  final DateTime timestamp;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.userName,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmount,
    required this.productNames,
    required this.timestamp,
  });

  void _showOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Order ID: $orderId'),
              Text('Delivery Type: $deliveryType'),
              Text('Payment Method: $paymentMethod'),
              Text('Voucher Code: $voucherCode'),
              Text('Total Amount: ₱${totalAmount.toStringAsFixed(2)}'),
              Text('Timestamp: ${timestamp.toLocal()}'),
              SizedBox(height: 8),
              Text('Products:'),
              ...productNames.map((product) => Text('- $product')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
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
              'Order ID: $orderId',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('User: $userName'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _showOrderDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                      0xFF2E0B0D), // Updated from `primary` to `backgroundColor`
                ),
                child: Text('View'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

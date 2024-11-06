import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderID;
  final String uid;

  OrderDetailsScreen({
    super.key,
    required this.orderID,
    required this.uid,
  });

  // Mapping of Firestore field names to display labels
  final Map<String, String> fieldLabels = {
    'orderType': 'Order Type',
    'orderID': 'Order ID',
    'deliveryType': 'Delivery Type',
    'paymentMethod': 'Payment Method',
    'productNames': 'Items',
    'voucherCode': 'Voucher Code',
    'totalAmountWithDelivery': 'Order Total',
    'timestamp': 'Time Ordered',
  };

  // Function to format timestamp
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customer')
            .doc(uid) // Use the uid of the current user
            .snapshots(),
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!customerSnapshot.hasData || !customerSnapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          var customerData =
              customerSnapshot.data!.data() as Map<String, dynamic>;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('customer')
                .doc(uid) // Use the uid to get the orders
                .collection('orders') // Access the 'orders' subcollection
                .doc(orderID) // Get the specific order document using orderID
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                return const Center(child: Text('Order not found'));
              }

              var orderData =
                  orderSnapshot.data!.data() as Map<String, dynamic>;

              // Retrieve order details
              String userName = customerData['userName'] ?? 'N/A';
              String emailAddress = customerData['emailAddress'] ?? 'N/A';
              String imageUrl = customerData['imageUrl'] ?? '';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display user image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300], // Placeholder color
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null, // Use the image URL if available
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 50) // Default icon
                          : null,
                    ),
                    const SizedBox(height: 16), // Space between image and text
                    // Display userName
                    Text(
                      userName, // Use userName from customer data
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Space between userName and email
                    // Display email
                    Text(
                      emailAddress, // Use email from customer data
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24), // Space before order details
                    // Display order details
                    Expanded(
                      child: ListView(
                        children: orderData.entries.map((entry) {
                          String label = fieldLabels[entry.key] ?? entry.key;
                          String value;

                          if (entry.key == 'timestamp' &&
                              entry.value is Timestamp) {
                            value = formatTimestamp(entry.value);
                          } else if (entry.key == 'productNames' &&
                              entry.value is List) {
                            value = (entry.value as List).join(', ');
                          } else if (entry.key == 'totalAmountWithDelivery') {
                            value = '₱${entry.value.toString()}';
                          } else {
                            value = entry.value.toString();
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

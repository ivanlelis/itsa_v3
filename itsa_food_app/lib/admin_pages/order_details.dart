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
    'paymentReceipt': 'Payment Receipt',
  };

  // Function to format timestamp
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // Function to update the status of the order to 'approved'
  Future<void> _approveOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(uid)
          .collection('orders')
          .doc(orderID)
          .update({'status': 'approved'});
      // Show confirmation message
      print('Order $orderID approved');
    } catch (e) {
      print('Error updating order status: $e');
    }
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

          // Retrieve the imageUrl from customer document
          String imageUrl = customerData['imageUrl'] ?? '';
          String userName = customerData['userName'] ?? 'N/A';
          String emailAddress = customerData['emailAddress'] ?? 'N/A';

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
              String paymentImage = orderData['paymentReceipt'] ?? '';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Display the profile image, userName, and emailAddress inside the ListView
                    imageUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(imageUrl),
                            onBackgroundImageError: (exception, stackTrace) {
                              // Handle error if imageUrl fails to load
                            },
                          )
                        : const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 50),
                          ),
                    const SizedBox(height: 16), // Space between image and name

                    // Center userName and emailAddress
                    Center(
                      child: Column(
                        children: [
                          Text(
                            userName, // Use userName from customer data
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height: 8), // Space between userName and email
                          Text(
                            emailAddress, // Use email from customer data
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Space before order details

                    // Display order details
                    ...orderData.entries.map((entry) {
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
                      } else if (entry.key == 'paymentReceipt') {
                        value = '';
                      } else {
                        value = entry.value.toString();
                      }

                      return entry.key == 'paymentReceipt'
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  paymentImage.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Image with border
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 2), // Add a border
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8), // Rounded corners
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  paymentImage,
                                                  fit: BoxFit.cover,
                                                  height:
                                                      300, // Adjust the size
                                                  width: double.infinity,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Text(
                                                        'Failed to load image');
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                height:
                                                    8), // Space between image and button
                                            // Button to view full image
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    child: InteractiveViewer(
                                                      child: Image.network(
                                                        paymentImage,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Text(
                                                              'Failed to load image');
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[700],
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                  'Tap to view full image'),
                                            ),
                                          ],
                                        )
                                      : const Text('No receipt uploaded'),
                                ],
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                    }),
                    // Approve Order Button
                    ElevatedButton(
                      onPressed: _approveOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve Order'),
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

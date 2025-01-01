import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistory extends StatefulWidget {
  final String emailAddress;
  final String userName;
  final String uid;
  final double latitude;
  final double longitude;

  const OrderHistory({
    super.key,
    required this.emailAddress,
    required this.userName,
    required this.uid,
    required this.latitude,
    required this.longitude,
  });

  @override
  _OrderHistoryState createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  bool _isDescending = true;
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Order History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6E473B), // Updated color
        actions: [
          IconButton(
            icon: Icon(
              _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                final now = DateTime.now();
                if (value == '7 Days') {
                  _filterDate = now.subtract(const Duration(days: 7));
                } else if (value == '14 Days') {
                  _filterDate = now.subtract(const Duration(days: 14));
                } else if (value == '30 Days') {
                  _filterDate = now.subtract(const Duration(days: 30));
                } else {
                  _filterDate = null; // No filter
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7 Days', child: Text('Last 7 Days')),
              const PopupMenuItem(
                  value: '14 Days', child: Text('Last 14 Days')),
              const PopupMenuItem(
                  value: '30 Days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: 'All', child: Text('All')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customer')
            .doc(widget.uid)
            .collection('orders')
            .orderBy('timestamp', descending: _isDescending)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child:
                    Text("No orders found.", style: TextStyle(fontSize: 18)));
          }

          // Filter orders based on the selected date range
          final filteredDocs = _filterDate == null
              ? snapshot.data!.docs
              : snapshot.data!.docs.where((doc) {
                  Timestamp timestamp = doc['timestamp'];
                  return timestamp.toDate().isAfter(_filterDate!);
                }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
                child: Text("No orders found for this range.",
                    style: TextStyle(fontSize: 18)));
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: filteredDocs.map((doc) {
              String orderId = doc.id;
              Timestamp timestamp = doc['timestamp'];
              List<dynamic> productName = doc['products'];

              // Format timestamp to a readable date and time
              String formattedDate = DateFormat('MMM dd, yyyy – hh:mm a')
                  .format(timestamp.toDate());

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order ID: $orderId",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.fastfood,
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  "Items: ${productName.map((product) => '${product['productName']} 1 x ${product['quantity']}').join(', ')}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                "Total: PHP ${doc['total'].toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

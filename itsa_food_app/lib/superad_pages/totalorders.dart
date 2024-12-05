import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalOrders extends StatefulWidget {
  final double width;

  const TotalOrders({super.key, required this.width});

  @override
  _TotalOrdersState createState() => _TotalOrdersState();
}

class _TotalOrdersState extends State<TotalOrders> {
  int _totalOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotalOrders();
  }

  Future<void> _fetchTotalOrders() async {
    try {
      // Fetch all documents in the 'customer' collection
      final customersSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      int totalOrders = 0;

      // Loop through each customer document
      for (var customerDoc in customersSnapshot.docs) {
        // Fetch the 'orders' subcollection for this customer
        final ordersSnapshot =
            await customerDoc.reference.collection('orders').get();

        // Add the number of orders in this customer's subcollection to the total
        totalOrders += ordersSnapshot.size;
      }

      // Update the UI with the total number of orders
      setState(() {
        _totalOrders = totalOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching total orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardCard(
      title: 'Total Orders',
      value: _isLoading ? 'Loading...' : '$_totalOrders',
      subtitle: 'Total number of orders across all customers',
      color: Colors.brown.shade300,
      width: widget.width,
    );
  }

  // Reusable card widget
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required double width,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

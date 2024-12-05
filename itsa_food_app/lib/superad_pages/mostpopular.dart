import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MostPopular extends StatefulWidget {
  final double width;

  const MostPopular({super.key, required this.width});

  @override
  _MostPopularState createState() => _MostPopularState();
}

class _MostPopularState extends State<MostPopular> {
  String _mostPopularItem = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMostPopularItem();
  }

  Future<void> _fetchMostPopularItem() async {
    try {
      // Create a map to store product name counts
      Map<String, int> productCounts = {};

      // Fetch all customers
      final customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      // Loop through all customer documents
      for (var customerDoc in customerSnapshot.docs) {
        // Get orders for each customer
        final ordersSnapshot =
            await customerDoc.reference.collection('orders').get();

        // Loop through all orders
        for (var orderDoc in ordersSnapshot.docs) {
          // Check if the "products" field exists and is an array
          if (orderDoc.data().containsKey('products')) {
            List<dynamic> products = orderDoc['products'];

            // Loop through each product in the products array
            for (var product in products) {
              // Ensure each product contains a "productName" field
              if (product is Map<String, dynamic> &&
                  product.containsKey('productName')) {
                String productName = product['productName'];

                // Increment the count for the product name
                productCounts[productName] =
                    (productCounts[productName] ?? 0) + 1;
              }
            }
          }
        }
      }

      // Find the most popular product (the one with the highest count)
      String mostPopular = "No popular item found";
      int maxCount = 0;

      productCounts.forEach((productName, count) {
        if (count > maxCount) {
          maxCount = count;
          mostPopular = productName;
        }
      });

      // Update UI with the most popular item
      setState(() {
        _mostPopularItem = mostPopular;
        _isLoading = false;
      });
    } catch (e) {
      // Log the error for debugging purposes
      print('Error fetching popular item: $e');
      setState(() {
        _mostPopularItem = "Error fetching data";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardCard(
      title: 'Popular Items',
      value: _isLoading ? 'Loading...' : _mostPopularItem,
      subtitle: 'Most popular item',
      color: Colors.brown.shade400,
      width: widget.width,
    );
  }

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

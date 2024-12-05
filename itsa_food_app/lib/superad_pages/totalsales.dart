import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalSales extends StatefulWidget {
  final double width;

  const TotalSales({super.key, required this.width});

  @override
  _TotalSalesState createState() => _TotalSalesState();
}

class _TotalSalesState extends State<TotalSales> {
  int _totalSales = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotalSales();
  }

  Future<void> _fetchTotalSales() async {
    try {
      int totalSales = 0;

      // Reference the "transactions" document directly (since it's the only one)
      final transactionsDoc = FirebaseFirestore.instance
          .collection('transactions')
          .doc('transactions');

      // Use dynamic date generation or patterns
      DateTime now = DateTime.now();

      // Iterate through the last 30 days
      for (int i = 0; i < 30; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String subCollectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        print("Fetching subcollection: $subCollectionName");

        // Fetch the subcollection for the specific date under the "transactions" document
        final subcollectionRef = transactionsDoc.collection(subCollectionName);

        // Fetch the `dailySales` document
        final dailySalesDoc = await subcollectionRef.doc('dailySales').get();

        if (dailySalesDoc.exists) {
          // Get sales data and sum it up, ensuring it handles both int and double types
          final data = dailySalesDoc.data();
          final sales = data?['sales'];

          if (sales != null) {
            // Safely check if sales is a num (int or double), then convert it to an int
            if (sales is num) {
              totalSales += sales.toInt(); // Convert to int for consistency
              print("Sales for $subCollectionName: $sales");
            } else {
              print(
                  "Sales data is neither int nor double for $subCollectionName");
            }
          } else {
            print("No sales data in $subCollectionName");
          }
        } else {
          print("No dailySales document in $subCollectionName");
        }
      }

      // Update state with the total sales
      setState(() {
        _totalSales = totalSales;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching total sales: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardCard(
      title: 'Total Sales',
      value: _isLoading ? 'Loading...' : '₱$_totalSales',
      subtitle: 'Total sales amount',
      color: Colors.brown.shade200,
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

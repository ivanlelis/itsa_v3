import 'package:flutter/material.dart';

class TotalSales extends StatelessWidget {
  final double width;

  const TotalSales({Key? key, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder data for total sales
    final String totalSales =
        '₱129124'; // Replace with Firestore data fetching logic

    return _buildDashboardCard(
      title: 'Total Sales',
      value: totalSales,
      subtitle: 'Total sales amount',
      color: Colors.brown.shade200,
      width: width,
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

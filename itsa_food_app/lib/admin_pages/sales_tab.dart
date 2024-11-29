import 'package:flutter/material.dart';
import 'weekly_sales.dart'; // Import the WeeklySales screen

class SalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Forecast',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Button to navigate to WeeklySales
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WeeklySales(), // Navigate to WeeklySales screen
                ),
              );
            },
            child: const Text('View Weekly Sales Chart'),
          ),
          const SizedBox(height: 20),
          // Placeholder for detailed sales data
          const Text('Detailed sales data will be shown here.'),
        ],
      ),
    );
  }
}

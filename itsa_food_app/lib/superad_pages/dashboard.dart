import 'package:flutter/material.dart';
import 'package:itsa_food_app/superad_pages/totalsales.dart'; // Adjust the import path as needed.
import 'package:itsa_food_app/superad_pages/totalorders.dart'; // Import the TotalOrders widget.
import 'package:itsa_food_app/superad_pages/mostpopular.dart'; // Import the MostPopular widget.

class SuperAdDashboard extends StatelessWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const SuperAdDashboard({
    super.key,
    this.userName = "Admin",
    required this.email,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Cards Section
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Display TotalSales widget with the dynamic width based on screen size
                  TotalSales(width: _getCardWidth(screenWidth)),

                  // Replace the "Number of Orders" card with the TotalOrders widget
                  TotalOrders(width: _getCardWidth(screenWidth)),

                  // Add the new MostPopular widget here
                  MostPopular(width: _getCardWidth(screenWidth)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to calculate card width based on screen size
  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 64) / 4; // 4 cards in a row
    } else if (screenWidth > 800) {
      return (screenWidth - 48) / 3; // 3 cards in a row
    } else if (screenWidth > 600) {
      return (screenWidth - 32) / 2; // 2 cards in a row
    } else {
      return double.infinity; // Single column layout
    }
  }
}

import 'package:flutter/material.dart';

class SuperAdDashboard extends StatelessWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const SuperAdDashboard({
    Key? key,
    this.userName = "Admin",
    required this.email,
    this.imageUrl = '',
  }) : super(key: key);

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
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 16),
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
                  _buildDashboardCard(
                    title: 'Total Sales',
                    value: '₱129124',
                    subtitle: 'Total sales amount',
                    color: Colors.brown.shade200,
                    width: _getCardWidth(screenWidth),
                  ),
                  _buildDashboardCard(
                    title: 'Number of Orders',
                    value: '1325',
                    subtitle: 'Total number of orders',
                    color: Colors.brown.shade300,
                    width: _getCardWidth(screenWidth),
                  ),
                  _buildDashboardCard(
                    title: 'Popular Items',
                    value: 'Original/Spicy I-Tsa Takoyaki',
                    subtitle: 'Most popular item',
                    color: Colors.brown.shade400,
                    width: _getCardWidth(screenWidth),
                  ),
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

  // Helper to build responsive dashboard cards
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

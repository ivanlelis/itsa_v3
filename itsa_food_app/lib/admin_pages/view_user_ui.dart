import 'package:flutter/material.dart';

class UserDetailsUI extends StatelessWidget {
  final String userName;
  final Map<String, dynamic> userData;

  const UserDetailsUI({
    super.key,
    required this.userName,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    String emailAddress = userData['emailAddress'] ?? 'N/A';
    String userAddress = userData['userAddress'] ?? 'N/A';
    String customerID = userData['customerID'];
    String mostOrderedProduct = userData['mostOrderedProduct'] ?? 'N/A';
    int productOrderCount =
        userData['productOrderCount'] ?? 0; // Added field for count

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: Welcome Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(
                  Icons.account_circle_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 15),
                Text(
                  "Welcome, $userName!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // User Details Section
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    icon: Icons.email_outlined,
                    label: "Email Address",
                    value: emailAddress,
                  ),
                  const Divider(height: 30, color: Colors.grey),
                  _buildDetailItem(
                    icon: Icons.location_on_outlined,
                    label: "User Address",
                    value: userAddress,
                  ),
                  const Divider(height: 30, color: Colors.grey),
                  _buildDetailItem(
                    icon: Icons.fingerprint_outlined,
                    label: "Customer ID",
                    value: customerID,
                  ),
                  const Divider(height: 30, color: Colors.grey),
                  _buildDetailItem(
                    icon: Icons.star_rate_rounded,
                    label: "Most Ordered Product",
                    value: '$mostOrderedProduct ($productOrderCount times)',
                  ), // Show product and count
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Leading Icon
        Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 28,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),

        // Detail Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

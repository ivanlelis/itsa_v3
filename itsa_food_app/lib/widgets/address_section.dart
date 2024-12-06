import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/edit_address.dart';

class AddressSection extends StatelessWidget {
  final String userAddress;
  final String? userName;
  final String? emailAddress;
  final String? email;
  final String? uid;
  final double latitude;
  final double longitude;

  const AddressSection({
    super.key,
    required this.userAddress,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.uid,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                userAddress,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to EditAddress screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAddress(
                      userName: userName ?? '',
                      userAddress: userAddress,
                      email: email ?? '',
                      emailAddress: emailAddress ?? '',
                      uid: uid ?? '',
                      latitude: latitude,
                      longitude: longitude,
                    ), // Navigate to EditAddress
                  ),
                );
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PickupAddress extends StatelessWidget {
  final String userAddress;
  final String? userName;
  final String? emailAddress;
  final String? email;
  final String? uid;
  final double latitude;
  final double longitude;
  final String branchID;

  const PickupAddress({
    super.key,
    required this.userAddress,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.uid,
    required this.latitude,
    required this.longitude,
    required this.branchID,
  });

  // Function to map branchID to branch name
  String getBranchName(String branchID) {
    switch (branchID) {
      case "branch 1":
        return "Sta. Lucia Branch";
      case "branch 2":
        return "Sta. Cruz II Branch";
      case "branch 3":
        return "San Dionisio Branch";
      default:
        return "Unknown Branch";
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchName = getBranchName(branchID);

    return Card(
      elevation: 2,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pickup at $branchName",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

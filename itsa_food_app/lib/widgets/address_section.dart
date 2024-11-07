import 'package:flutter/material.dart';

class AddressSection extends StatelessWidget {
  final String userAddress;

  const AddressSection({
    super.key,
    required this.userAddress,
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
                // Navigate to address edit screen
              },
              child: const Text('Edit', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for FirebaseAuth

class VoucherSection extends StatelessWidget {
  final bool isVisible; // To control whether the voucher section is visible
  final String selectedVoucher; // This will hold the selected voucher code
  final ValueChanged<String?>
      onVoucherSelect; // Callback for selecting a voucher
  final ValueChanged<double>
      onDiscountApplied; // Callback to pass the discount back to parent
  final ValueChanged<String>
      onVoucherDescriptionUpdate; // Callback to pass voucher description

  const VoucherSection({
    super.key,
    required this.isVisible,
    required this.selectedVoucher,
    required this.onVoucherSelect,
    required this.onDiscountApplied,
    required this.onVoucherDescriptionUpdate, // Add the new callback
  });

  @override
  Widget build(BuildContext context) {
    // Only show the Voucher Section if 'isVisible' is true
    return isVisible
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a Voucher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                // StreamBuilder now listens to the claimedVouchers subcollection
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('customer')
                      .doc(FirebaseAuth.instance.currentUser!
                          .uid) // Use FirebaseAuth to get the current user
                      .collection('claimedVouchers')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final claimedVouchers = snapshot.data!.docs;

                    return Column(
                      children: claimedVouchers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            color: Colors.blue[50],
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: const Icon(
                                Icons.card_giftcard,
                                size: 40.0,
                                color: Colors.teal,
                              ),
                              title: Text(
                                data['voucherCode'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['description'],
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  // Display the discount amount and type
                                  Text(
                                    data['discountType'] == 'Fixed Amount'
                                        ? '₱${data['discountAmt'].toStringAsFixed(2)}'
                                        : '${data['discountAmt'].toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.teal[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                onPressed: () {
                                  // Apply discount and update the selected voucher
                                  double discountAmt =
                                      data['discountAmt'] ?? 0.0;
                                  String discountType =
                                      data['discountType'] ?? '';

                                  double discount = 0.0;
                                  if (discountType == 'Fixed Amount') {
                                    discount =
                                        discountAmt; // Subtract fixed amount
                                  } else if (discountType == 'Percentage') {
                                    discount = discountAmt /
                                        100; // Subtract percentage
                                  }

                                  // Pass the voucher code and description back to the parent widget
                                  onVoucherSelect(data['voucherCode']);
                                  onVoucherDescriptionUpdate(data[
                                      'description']); // Update description

                                  // Notify parent with the calculated discount
                                  onDiscountApplied(discount);

                                  // Close the modal (this is the only navigation happening here)
                                  Navigator.pop(
                                      context); // Only closes the modal
                                },
                                child: const Text('Use'),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          )
        : const SizedBox(); // Return an empty container if isVisible is false
  }
}

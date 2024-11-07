import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/address_section.dart';
import 'package:itsa_food_app/widgets/payment_method_section.dart';
import 'package:itsa_food_app/widgets/voucher_section_pickup.dart';
import 'package:itsa_food_app/widgets/cart_products_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PickupTab extends StatefulWidget {
  final String userAddress;
  final String paymentMethod;
  final Function(String) onPaymentMethodChange;
  final VoidCallback onGcashSelected;
  final List<Map<String, dynamic>> cartItems;
  final double originalTotalAmount;

  const PickupTab({
    super.key,
    required this.userAddress,
    required this.paymentMethod,
    required this.onPaymentMethodChange,
    required this.onGcashSelected,
    required this.cartItems,
    required this.originalTotalAmount, // Add totalAmount parameter
  });

  @override
  _PickupTabState createState() => _PickupTabState();
}

class _PickupTabState extends State<PickupTab> {
  String paymentMethod = 'Cash';
  bool isVoucherVisible = false;
  String? selectedVoucher;
  String? voucherDescription;
  double baseTotal = 0.0; // Set initial value to 0
  double finalTotal = 0.0; // Set initial value to 0

  @override
  void initState() {
    super.initState();
    baseTotal = widget
        .originalTotalAmount; // Set baseTotal from widget.originalTotalAmount
    finalTotal = baseTotal; // Set finalTotal to baseTotal initially
  }

  void _onPaymentMethodChange(String method) {
    setState(() {
      paymentMethod = method;
      isVoucherVisible = method == 'GCash';
    });
  }

  void _applyVoucherDiscount(double currentTotalAmount) async {
    if (selectedVoucher == null || selectedVoucher!.isEmpty) return;

    try {
      // Fetch voucher data from Firestore
      DocumentSnapshot voucherSnapshot = await FirebaseFirestore.instance
          .collection('voucher')
          .doc(selectedVoucher)
          .get();

      if (voucherSnapshot.exists) {
        final voucherData = voucherSnapshot.data() as Map<String, dynamic>;
        final double discountAmt = voucherData['discountAmt'] ?? 0.0;
        final String discountType = voucherData['discountType'] ?? '';

        double newTotalAmount =
            currentTotalAmount; // Start with the current total amount

        // Apply discount based on voucher type
        if (discountType == 'Fixed Amount') {
          newTotalAmount -= discountAmt; // Apply fixed amount discount
          voucherDescription =
              'Fixed amount discount of ₱${discountAmt.toStringAsFixed(2)}';
        } else if (discountType == 'Percentage') {
          newTotalAmount -= currentTotalAmount *
              (discountAmt / 100); // Apply percentage discount
          voucherDescription = '${discountAmt.toStringAsFixed(0)}% discount';
        } else {
          voucherDescription = 'No discount';
        }

        // Ensure the total amount never goes below zero
        if (newTotalAmount < 0) {
          newTotalAmount = 0.0;
        }

        setState(() {
          finalTotal = newTotalAmount; // Update finalTotal
        });
      }
    } catch (e) {
      print("Error applying voucher discount: $e");
    }
  }

  void _recalculateTotalAmount() {
    // Reset to the base amount (original total amount)
    double updatedTotalAmount = baseTotal;

    // Apply the voucher discount if any
    if (selectedVoucher != null && selectedVoucher!.isNotEmpty) {
      _applyVoucherDiscount(updatedTotalAmount); // Apply voucher discount
    } else {
      setState(() {
        finalTotal = updatedTotalAmount; // Just set the amount if no voucher
      });
    }
  }

  void _showVoucherModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return VoucherSection(
          isVisible: isVoucherVisible,
          selectedVoucher: selectedVoucher ?? '',
          onVoucherSelect: (voucherCode) {
            setState(() {
              selectedVoucher = voucherCode;
              // Reset the total to baseTotal and recalculate the discount
              finalTotal = baseTotal;
              _recalculateTotalAmount(); // Recalculate the total with new voucher
            });
          },
          onDiscountApplied: (discount) {
            setState(() {
              finalTotal = finalTotal -
                  discount; // Update final total with the discount applied
            });
          },
          onVoucherDescriptionUpdate: (description) {
            setState(() {
              voucherDescription = description;
            });
          },
        );
      },
    ).then((_) {
      if (selectedVoucher != null && selectedVoucher!.isNotEmpty) {
        setState(() {}); // Trigger state update if voucher was selected
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Use the actual userAddress from the widget properties
                  AddressSection(userAddress: widget.userAddress),
                  const SizedBox(height: 16),
                  PaymentMethodSection(
                    paymentMethod: paymentMethod,
                    onPaymentMethodChange: _onPaymentMethodChange,
                    onGcashSelected: () {
                      if (isVoucherVisible) {
                        _showVoucherModal();
                      }
                    },
                  ),
                  if (isVoucherVisible) ...[
                    // Show voucher option if GCash is selected
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: _showVoucherModal,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          elevation: 2,
                        ),
                        child: Text(
                          selectedVoucher == null || selectedVoucher!.isEmpty
                              ? 'Select Voucher'
                              : 'Change Voucher',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (selectedVoucher != null &&
                        voucherDescription != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.blue[50],
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                color: Colors.teal,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Voucher Code: ${selectedVoucher ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Description: ${voucherDescription ?? 'No description available'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.teal[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  CartProductsSection(cartItems: widget.cartItems),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Container for the total and place order button, placed outside the padding
          Container(
            color: Colors.brown,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      '₱${finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Place order logic here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(color: Colors.brown),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

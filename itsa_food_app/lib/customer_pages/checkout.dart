import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/delivery_type_section.dart';
import 'package:itsa_food_app/widgets/payment_method_section.dart';
import 'package:itsa_food_app/widgets/voucher_section_delivery.dart';
import 'package:itsa_food_app/widgets/cart_products_section.dart';
import 'package:itsa_food_app/widgets/address_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/widgets/pickuptab.dart';
import 'package:itsa_food_app/customer_pages/confirm_payment.dart';

class Checkout extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final double totalAmount;
  final String? uid;
  final String? email;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? userAddress;
  final List<Map<String, dynamic>> cartItems;
  final String selectedItemName;
  final String? branchID;

  const Checkout({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.totalAmount,
    required this.uid,
    required this.email,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.userAddress,
    required this.cartItems,
    required this.selectedItemName,
    required this.branchID,
  });

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? deliveryType = 'Standard';
  String paymentMethod = 'Cash';
  String selectedVoucher = ''; // Store the selected voucher
  bool isVoucherButtonVisible = false;
  String selectedPaymentMethod = 'Cash';
  double originalTotalAmount = 0.0;
  double totalAmount = 0.0;
  String? orderType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    orderType = _tabController?.index == 0 ? "Delivery" : "Pickup";

    // Initialize the original total amount (without delivery charges)
    originalTotalAmount = widget.totalAmount;

    // Set the initial total amount (add delivery charge for Standard by default)
    totalAmount =
        originalTotalAmount + 20.0; // Default delivery charge for Standard

    // Listen for tab changes
    _tabController?.addListener(() {
      if (_tabController!.index == 1) {
        // If the 'Pick Up' tab is selected, reset the total amount to the base amount
        setState(() {
          totalAmount =
              originalTotalAmount; // Remove delivery charge for pickup
        });
      } else {
        // If the 'Delivery' tab is selected, recalculate the total amount
        _updateTotalAmount(
            deliveryType ?? 'Standard'); // Reapply delivery charge
      }
    });

    orderType = _tabController?.index == 0
        ? "Delivery"
        : "Pickup"; // Set initial orderType

    _tabController?.addListener(() {
      setState(() {
        orderType = _tabController!.index == 0
            ? "Delivery"
            : "Pickup"; // Update based on selected tab
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void selectPaymentMethod(String method) {
    setState(() {
      paymentMethod = method;
      isVoucherButtonVisible = method == 'GCash';
    });
  }

  void _handlePaymentMethodChange(String method) {
    setState(() {
      paymentMethod = method;
    });
  }

  // Function to handle GCash selection
  void _handleGcashSelected() {
    // Example logic: You can show a modal, update UI, etc.
    print('GCash selected');
  }

  void _showVoucherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VoucherSectionDelivery(
        isVisible: true,
        selectedVoucher: selectedVoucher,
        onVoucherSelect: (value) {
          setState(() {
            selectedVoucher = value ?? ''; // Update the selected voucher
            // Modal closes here without needing to call Navigator.pop again
            // No need for Navigator.pop(context) in onVoucherSelect

            // Recalculate the total amount when voucher is changed
            _recalculateTotalAmount(); // Recalculate from base amount again
          });
        },
        onDiscountApplied: (discountedAmount) {
          // Apply the discount to the total amount
          setState(() {
            totalAmount = discountedAmount;
          });
        },
      ),
    );
  }

  void _recalculateTotalAmount() {
    // Reset to the base amount (original total amount)
    double updatedTotalAmount = originalTotalAmount;

    // Apply the delivery charge based on the selected delivery type
    double deliveryCharge = 0.0;

    if (deliveryType == 'Standard') {
      deliveryCharge = 20.0;
    } else if (deliveryType == 'Fast') {
      deliveryCharge = 50.0;
    }

    updatedTotalAmount += deliveryCharge; // Add delivery charge to base amount

    // Apply the voucher discount if any
    if (selectedVoucher.isNotEmpty) {
      _applyVoucherDiscount(updatedTotalAmount); // Apply voucher discount
    } else {
      setState(() {
        totalAmount = updatedTotalAmount; // Just set the amount if no voucher
      });
    }
  }

  void _applyVoucherDiscount(double currentTotalAmount) async {
    if (selectedVoucher.isEmpty) return;

    try {
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

        if (discountType == 'Fixed Amount') {
          // Apply fixed amount discount
          newTotalAmount -= discountAmt;
        } else if (discountType == 'Percentage') {
          // Apply percentage discount
          newTotalAmount -= currentTotalAmount * (discountAmt / 100);
        }

        // Ensure the total amount never goes below zero
        if (newTotalAmount < 0) {
          newTotalAmount = 0.0;
        }

        setState(() {
          totalAmount = newTotalAmount;
        });
      }
    } catch (e) {
      print("Error applying voucher discount: $e");
    }
  }

  void _updateTotalAmount(String deliveryType) {
    double deliveryCharge = 0.0;

    // Set delivery charge based on selected delivery type
    if (deliveryType == 'Standard') {
      deliveryCharge = 20.0;
    } else if (deliveryType == 'Fast') {
      deliveryCharge = 50.0;
    }

    // Start with the base (original) total amount
    double updatedTotalAmount = originalTotalAmount + deliveryCharge;

    // If a voucher is selected, apply the voucher discount after recalculating the delivery charge
    if (selectedVoucher.isNotEmpty) {
      _applyVoucherDiscount(
          updatedTotalAmount); // Reapply discount based on new delivery type
    } else {
      // If no voucher is selected, set the updated total amount
      setState(() {
        totalAmount = updatedTotalAmount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('Order Details',
                    style: TextStyle(color: Colors.white)),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Delivery'),
                Tab(text: 'Pick Up'),
              ],
              indicatorColor: Colors.brown,
              labelColor: Colors.brown,
              unselectedLabelColor: Colors.grey,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Delivery Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      AddressSection(userAddress: widget.userAddress ?? ''),
                      const SizedBox(height: 16),
                      DeliveryTypeSection(
                        deliveryType: deliveryType ?? 'Standard',
                        onDeliveryTypeChange: (value) {
                          setState(() {
                            deliveryType = value;
                            _updateTotalAmount(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      PaymentMethodSection(
                        paymentMethod: selectedPaymentMethod,
                        onPaymentMethodChange: (method) => setState(() {
                          selectedPaymentMethod = method;
                          if (method == 'GCash') {
                            isVoucherButtonVisible = true;
                          } else if (method == 'Cash') {
                            isVoucherButtonVisible = false;
                            selectedVoucher =
                                ''; // Reset voucher when "Cash" is selected
                            totalAmount =
                                originalTotalAmount; // Reset total amount
                          } else if (method == 'PayPal') {
                            // PayPal specific logic if needed (e.g., no voucher)
                            isVoucherButtonVisible = false;
                            selectedVoucher = ''; // Reset voucher for PayPal
                            totalAmount =
                                originalTotalAmount; // Reset total amount for PayPal
                          }
                        }),
                        onGcashSelected: () {
                          setState(() {
                            isVoucherButtonVisible = true;
                          });
                        },
                        onPaypalSelected: () {
                          setState(() {
                            selectedPaymentMethod = 'PayPal';
                            isVoucherButtonVisible =
                                false; // Hide voucher button for PayPal
                            selectedVoucher =
                                ''; // Reset voucher when PayPal is selected
                            totalAmount =
                                originalTotalAmount; // Reset total amount for PayPal
                          });
                        },
                      ),
                      if (isVoucherButtonVisible)
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
                              selectedVoucher.isEmpty
                                  ? 'Select Voucher'
                                  : 'Change Voucher',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (selectedVoucher.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Card(
                            color: Colors.green[50],
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: Icon(
                                Icons.card_giftcard,
                                size: 40.0,
                                color: Colors.teal,
                              ),
                              title: Text(
                                selectedVoucher,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('voucher')
                                    .doc(selectedVoucher)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    final voucherData = snapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final description =
                                        voucherData['description'] ??
                                            'No description available';
                                    return Text(
                                      description,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    );
                                  }
                                  return Text(
                                    'Voucher not found',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600]),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      CartProductsSection(
                        cartItems: widget.cartItems,
                        selectedItemName:
                            widget.selectedItemName, // Pass selectedItemName
                      ),
                    ],
                  ),
                ),
                // Pick Up Tab
                PickupTab(
                  userName: widget.userName,
                  emailAddress: widget.emailAddress,
                  email: widget.email,
                  uid: widget.uid,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  imageUrl: widget.imageUrl,
                  orderType: orderType ?? "Delivery",
                  userAddress: widget.userAddress,
                  paymentMethod: selectedPaymentMethod,
                  branchID: widget.branchID,
                  onPaymentMethodChange: (method) => setState(() {
                    selectedPaymentMethod = method;

                    if (method == 'GCash') {
                      isVoucherButtonVisible = true;
                    } else if (method == 'Cash') {
                      isVoucherButtonVisible = false;
                      selectedVoucher =
                          ''; // Reset voucher when "Cash" is selected
                    } else if (method == 'PayPal') {
                      // PayPal specific logic (no voucher for PayPal)
                      isVoucherButtonVisible =
                          false; // Hide voucher button for PayPal
                      selectedVoucher =
                          ''; // Reset voucher when PayPal is selected
                    }
                  }),
                  onGcashSelected: () {
                    setState(() {
                      isVoucherButtonVisible = true;
                    });
                  },
                  cartItems: widget.cartItems,
                  selectedItemName: widget.selectedItemName,
                  originalTotalAmount: originalTotalAmount,
                ),
              ],
            ),
          ),
          // Show the total and place order button only when the "Delivery" tab is selected
          if (_tabController?.index == 0)
            Container(
              color: Colors.brown,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      Text('₱${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmPayment(
                            cartItems: widget.cartItems,
                            deliveryType:
                                deliveryType ?? 'Unknown Delivery Type',
                            paymentMethod: selectedPaymentMethod,
                            voucherCode: selectedVoucher,
                            totalAmount: totalAmount,
                            uid: widget.uid,
                            userName: widget.userName,
                            userAddress: widget.userAddress,
                            emailAddress: widget.emailAddress,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            orderType: orderType ?? "Delivery",
                            email: widget.email,
                            imageUrl: widget.imageUrl,
                            selectedItemName: widget.selectedItemName,
                            branchID: widget.branchID,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Place Order',
                        style: TextStyle(color: Colors.brown)),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:itsa_food_app/customer_pages/confirm_payment.dart';

class Checkout extends StatefulWidget {
  final String userName;
  final String email;
  final double totalAmount;

  const Checkout({
    super.key,
    required this.userName,
    required this.email,
    required this.totalAmount,
  });

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> cartItems = [];
  int selectedDeliveryType = 1; // Default to 'Standard'
  double deliveryFee = 20.00; // Default fee for 'Standard' delivery
  late double totalAmountWithDelivery;
  late double originalTotalAmountWithDelivery;

  late TabController _tabController;
  int selectedPaymentMethod = -1; // -1 means no selection
  String? selectedVoucherCode;
  double totalDiscount = 0; // Variable to store total discount

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCartItems();

    // Calculate the initial total amount with the default delivery fee
    totalAmountWithDelivery = widget.totalAmount + deliveryFee;
    originalTotalAmountWithDelivery = totalAmountWithDelivery;

    // Listen for tab changes to reset the total if Pickup is selected
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // If the Pickup tab is selected, reset the total to the original amount
        setState(() {
          totalAmountWithDelivery = widget.totalAmount;
        });
      } else if (_tabController.index == 0) {
        // If Delivery tab is selected, include the selected delivery fee
        setState(() {
          totalAmountWithDelivery = widget.totalAmount + deliveryFee;
        });
      }
    });
  }

  void _updateVoucher(Map<String, dynamic> data) {
    // Reset total amount before recalculating
    totalAmountWithDelivery = originalTotalAmountWithDelivery;

    // Calculate the new discount based on the selected voucher
    if (data['discountType'] == 'Percentage') {
      double discount =
          data['discountAmt'] / 100; // Convert percentage to decimal
      totalAmountWithDelivery -=
          totalAmountWithDelivery * discount; // Apply discount
    } else if (data['discountType'] == 'Fixed') {
      totalAmountWithDelivery -= data['discountAmt']; // Apply fixed discount
    }

    // Update selected voucher code and refresh the UI
    setState(() {
      selectedVoucherCode = data['voucherCode'];
    });
  }

  Future<void> fetchVouchers() async {
    QuerySnapshot voucherSnapshot =
        await FirebaseFirestore.instance.collection('voucher').get();

    // Loop through the vouchers and calculate totalDiscount
    for (var doc in voucherSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double discountAmt = data['discountAmt'] ?? 0; // Fetch discount amount
      String discountType = data['discountType'] ?? ''; // Fetch discount type

      // Calculate totalDiscount based on discountType
      if (discountType == 'Percentage') {
        totalDiscount += discountAmt; // Use it as a percentage
      } else if (discountType == 'Fixed') {
        totalDiscount -= discountAmt; // Deduct fixed amount
      }
    }

    // After fetching and calculating, update the totalAmountWithDelivery accordingly
    totalAmountWithDelivery +=
        totalDiscount; // Update total amount with discount
  }

  Future<void> _fetchCartItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.userName)
          .collection('cart')
          .get();

      setState(() {
        cartItems = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'productName': doc['productName'],
            'sizeQuantity': doc['sizeQuantity'],
            'quantity': doc['quantity'],
            'total': doc['total'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  void _updateDeliveryFee(int deliveryType) {
    setState(() {
      selectedDeliveryType = deliveryType;
      if (selectedDeliveryType == 0) {
        deliveryFee = 50.00; // Fast delivery fee
      } else {
        deliveryFee = 20.00; // Standard delivery fee
      }

      // Update the total amount with the selected delivery fee only if Delivery tab is selected
      if (_tabController.index == 0) {
        totalAmountWithDelivery = widget.totalAmount + deliveryFee;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery and Pickup Tabs
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Delivery'),
                Tab(text: 'Pickup'),
              ],
              indicator: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(25)),
                color: Color.fromARGB(255, 192, 153, 144),
              ),
              indicatorColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              indicatorWeight: 0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar Views for Delivery and Pickup
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Delivery Tab View
                _buildDeliveryView(),
                // Pickup Tab View
                _buildPickupView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Address section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Dasmariñas, Cavite, Philippines',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle address editing
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Type section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Type',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            RadioListTile(
                              title: const Text('Fast'),
                              subtitle: const Text('₱50.00'),
                              value: 0,
                              groupValue: selectedDeliveryType,
                              onChanged: (value) {
                                _updateDeliveryFee(value as int);
                              },
                              secondary: const Icon(Icons.delivery_dining),
                            ),
                            const Divider(height: 1),
                            RadioListTile(
                              title: const Text('Standard'),
                              subtitle: const Text('₱20.00'),
                              value: 1,
                              groupValue: selectedDeliveryType,
                              onChanged: (value) {
                                _updateDeliveryFee(value as int);
                              },
                              secondary:
                                  const Icon(Icons.delivery_dining_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Cash'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedPaymentMethod == 0
                                      ? Colors.green
                                      : null, // Default color
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedPaymentMethod = 0; // Select Cash
                                  });
                                },
                                child: Text(
                                  selectedPaymentMethod == 0
                                      ? 'Selected'
                                      : 'Select',
                                  style: TextStyle(
                                    color: selectedPaymentMethod == 0
                                        ? Colors
                                            .white // Change text color to white when selected
                                        : Colors.black, // Default text color
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('GCash'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedPaymentMethod == 1
                                      ? Colors.green
                                      : null, // Default color
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedPaymentMethod = 1; // Select GCash
                                  });
                                },
                                child: Text(
                                  selectedPaymentMethod == 1
                                      ? 'Selected'
                                      : 'Select',
                                  style: TextStyle(
                                    color: selectedPaymentMethod == 1
                                        ? Colors
                                            .white // Change text color to white when selected
                                        : Colors.black, // Default text color
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedPaymentMethod == 1) ...[
                        const Text(
                          'Select Voucher',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(selectedVoucherCode ??
                                'Voucher Code'), // Update title based on selection
                            trailing: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('All Available Vouchers'),
                                      content: FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('voucher')
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 4.0,
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return const Text(
                                                'No vouchers available');
                                          }

                                          return SingleChildScrollView(
                                            child: Column(
                                              children: snapshot.data!.docs
                                                  .map((doc) {
                                                var data = doc.data()
                                                    as Map<String, dynamic>;
                                                DateTime startDate =
                                                    (data['startDate']
                                                            as Timestamp)
                                                        .toDate();
                                                DateTime expDate =
                                                    (data['expDate']
                                                            as Timestamp)
                                                        .toDate();
                                                String formattedStartDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(startDate);
                                                String formattedExpDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(expDate);

                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    title: Text(
                                                        data['voucherCode'] ??
                                                            'No Code'),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Description: ${data['description'] ?? 'No Description'}'),
                                                        Text(
                                                            'Start Date: $formattedStartDate'),
                                                        Text(
                                                            'Expiration Date: $formattedExpDate'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Update the selected voucher code and calculate discount
                                                      setState(() {
                                                        selectedVoucherCode =
                                                            data['voucherCode'];

                                                        // Fetch discount values
                                                        double discountAmt =
                                                            data['discountAmt']
                                                                    ?.toDouble() ??
                                                                0;
                                                        String discountType =
                                                            data['discountType'] ??
                                                                'Fixed';

                                                        double totalDiscount =
                                                            0.0;

                                                        // Calculate total discount based on type
                                                        if (discountType ==
                                                            'Percentage') {
                                                          totalDiscount =
                                                              totalAmountWithDelivery *
                                                                  (discountAmt /
                                                                      100); // Apply percentage discount
                                                        } else if (discountType ==
                                                            'Fixed') {
                                                          totalDiscount =
                                                              discountAmt; // Use fixed discount directly
                                                        }

                                                        // Update total amount with the discount
                                                        totalAmountWithDelivery -=
                                                            totalDiscount; // Subtract the discount from the total amount

                                                        // Call the function to handle voucher updates
                                                        _updateVoucher(
                                                            data); // This will manage the total amount with the discount
                                                      });
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        },
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(selectedVoucherCode == null
                                  ? 'Select'
                                  : 'Change'), // Change button text based on selection
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // Cart Items section
                Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      shrinkWrap:
                          true, // Allow ListView to take the height of its children
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'], // Update this line
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Size/Quantity: ${item['sizeQuantity']} x ${item['quantity']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '₱${item['total'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Total Amount and Place Order button
        _buildTotalAndOrderButton(),
      ],
    );
  }

  Widget _buildPickupView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Ready to pick-up information
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ready to pick up in 15-25 mins',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.store),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Cash'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedPaymentMethod == 0
                                      ? Colors.green
                                      : null, // Default color
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedPaymentMethod = 0; // Select Cash
                                  });
                                },
                                child: Text(
                                  selectedPaymentMethod == 0
                                      ? 'Selected'
                                      : 'Select',
                                  style: TextStyle(
                                    color: selectedPaymentMethod == 0
                                        ? Colors
                                            .white // Change text color to white when selected
                                        : Colors.black, // Default text color
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('GCash'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedPaymentMethod == 1
                                      ? Colors.green
                                      : null, // Default color
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedPaymentMethod = 1; // Select GCash
                                  });
                                },
                                child: Text(
                                  selectedPaymentMethod == 1
                                      ? 'Selected'
                                      : 'Select',
                                  style: TextStyle(
                                    color: selectedPaymentMethod == 1
                                        ? Colors
                                            .white // Change text color to white when selected
                                        : Colors.black, // Default text color
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedPaymentMethod == 1) ...[
                        const Text(
                          'Select Voucher',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(selectedVoucherCode ??
                                'Voucher Code'), // Update title based on selection
                            trailing: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('All Available Vouchers'),
                                      content: FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('voucher')
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 4.0,
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return const Text(
                                                'No vouchers available');
                                          }

                                          return SingleChildScrollView(
                                            child: Column(
                                              children: snapshot.data!.docs
                                                  .map((doc) {
                                                var data = doc.data()
                                                    as Map<String, dynamic>;
                                                DateTime startDate =
                                                    (data['startDate']
                                                            as Timestamp)
                                                        .toDate();
                                                DateTime expDate =
                                                    (data['expDate']
                                                            as Timestamp)
                                                        .toDate();
                                                String formattedStartDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(startDate);
                                                String formattedExpDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(expDate);

                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    title: Text(
                                                        data['voucherCode'] ??
                                                            'No Code'),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Description: ${data['description'] ?? 'No Description'}'),
                                                        Text(
                                                            'Start Date: $formattedStartDate'),
                                                        Text(
                                                            'Expiration Date: $formattedExpDate'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      // Update the selected voucher code and calculate discount
                                                      setState(() {
                                                        selectedVoucherCode =
                                                            data['voucherCode'];

                                                        // Fetch discount values
                                                        double discountAmt =
                                                            data['discountAmt']
                                                                    ?.toDouble() ??
                                                                0;
                                                        String discountType =
                                                            data['discountType'] ??
                                                                'Fixed';

                                                        double totalDiscount =
                                                            0.0;

                                                        // Calculate total discount based on type
                                                        if (discountType ==
                                                            'Percentage') {
                                                          totalDiscount =
                                                              totalAmountWithDelivery *
                                                                  (discountAmt /
                                                                      100); // Apply percentage discount
                                                        } else if (discountType ==
                                                            'Fixed') {
                                                          totalDiscount =
                                                              discountAmt; // Use fixed discount directly
                                                        }

                                                        // Update total amount with the discount
                                                        totalAmountWithDelivery -=
                                                            totalDiscount; // Subtract the discount from the total amount

                                                        // Call the function to handle voucher updates
                                                        _updateVoucher(
                                                            data); // This will manage the total amount with the discount
                                                      });
                                                      Navigator.of(context)
                                                          .pop(); // Close the dialog
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        },
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(selectedVoucherCode == null
                                  ? 'Select'
                                  : 'Change'), // Change button text based on selection
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cart Items section
                Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      shrinkWrap:
                          true, // Allow ListView to take the height of its children
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'], // Update this line
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Size/Quantity: ${item['sizeQuantity']} x ${item['quantity']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '₱${item['total'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Total Amount and Place Order button
        _buildTotalAndOrderButton(),
      ],
    );
  }

  Widget _buildTotalAndOrderButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.brown[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '₱${totalAmountWithDelivery.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            // Navigate directly to ConfirmPayment without any transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ConfirmPayment(),
                transitionDuration: Duration.zero, // Remove transition duration
                reverseTransitionDuration:
                    Duration.zero, // Remove reverse transition duration
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.brown,
            child: const Center(
              child: Text(
                'Place Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

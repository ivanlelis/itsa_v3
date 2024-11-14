import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:itsa_food_app/main_home/customer_home.dart';

class ConfirmPayment extends StatefulWidget {
  final List<dynamic> cartItems;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmount;
  final String uid; // Current customer’s ID
  final String userName;
  final String userAddress;
  final String emailAddress;
  final double latitude;
  final double longitude;
  final String orderType;
  final String email;
  final String imageUrl;

  const ConfirmPayment({
    super.key,
    required this.cartItems,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmount,
    required this.uid,
    required this.userName,
    required this.userAddress,
    required this.emailAddress,
    required this.latitude,
    required this.longitude,
    required this.orderType,
    required this.email,
    required this.imageUrl,
  });

  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  String discountDescription = '';

  @override
  void initState() {
    super.initState();
    _fetchVoucherDetails();
  }

  // Fetch voucher details from Firestore
  Future<void> _fetchVoucherDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('voucher')
        .doc(widget.voucherCode)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        final discountAmt = data['discountAmt'];
        final discountType = data['discountType'];

        // Format discount string based on type
        if (discountType == "Fixed Amount") {
          discountDescription = '₱$discountAmt off';
        } else if (discountType == "Percentage") {
          discountDescription = '$discountAmt% off';
        }

        setState(() {}); // Update the UI with the fetched discount
      }
    }
  }

  // Generate a random 8-character order ID
  String _generateOrderID() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(
        8, (index) => characters[random.nextInt(characters.length)]).join();
  }

  // Extract product names from cartItems
  List<String> _getProductNames() {
    return widget.cartItems
        .map((item) => item['productName'] as String)
        .toList();
  }

  Future<void> _deleteCart() async {
    final cartRef = FirebaseFirestore.instance
        .collection('customer')
        .doc(widget.uid)
        .collection('cart');

    final cartItems = await cartRef.get();

    for (var doc in cartItems.docs) {
      await doc.reference.delete();
    }
  }

  // Create order in Firestore
  Future<void> _createOrder() async {
    String orderID = _generateOrderID();
    List<String> productNames = _getProductNames();
    Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> orderData = {
      'deliveryType': widget.deliveryType,
      'orderID': orderID,
      'orderType': widget.orderType,
      'paymentMethod': widget.paymentMethod,
      'productNames': productNames,
      'timestamp': timestamp,
      'total': widget.totalAmount,
      'voucherCode': widget.voucherCode,
    };

    try {
      // Create the order in Firestore
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('orders')
          .doc(orderID)
          .set(orderData);

      // Create the notification in Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(orderID)
          .set(orderData);

      await _updateStockFromCartItems();

      // Delete the cart items after order creation
      await _deleteCart();

      // Show success modal directly after completing Firestore operations
      _showPaymentSuccessModal();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to confirm order: $e')));
    }
  }

  Future<void> _updateStockFromCartItems() async {
    // Get product names directly from the cart items
    List<String> productNames = _getProductNames();

    for (String productName in productNames) {
      // Fetch product details from Firestore based on the productName
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productName', isEqualTo: productName)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        DocumentSnapshot productDoc = productSnapshot.docs.first;
        List ingredients = productDoc['ingredients'];

        for (var ingredient in ingredients) {
          String matName =
              ingredient['name']; // Use 'name' as field key in products
          String ingredientQuantityStr = ingredient['quantity'];

          // Extract numeric part and unit from quantity string (e.g., "0.1875 liters" -> 0.1875 and "liters")
          List<String> quantityParts = ingredientQuantityStr.split(' ');
          double ingredientQuantity = double.tryParse(quantityParts[0]) ?? 0.0;
          String ingredientUnit =
              quantityParts.length > 1 ? quantityParts[1] : '';

          // Get current raw material stock from rawStock collection
          DocumentSnapshot rawMaterialDoc = await FirebaseFirestore.instance
              .collection('rawStock')
              .doc(matName)
              .get();

          if (rawMaterialDoc.exists) {
            double availableStock =
                double.tryParse(rawMaterialDoc['quantity'].toString()) ?? 0.0;
            String stockUnit = rawMaterialDoc['unit'];

            // Ensure units match before subtracting
            if (stockUnit == ingredientUnit) {
              if (availableStock >= ingredientQuantity) {
                // Update stock
                await FirebaseFirestore.instance
                    .collection('rawStock')
                    .doc(matName)
                    .update({'quantity': availableStock - ingredientQuantity});
                print(
                    "Subtracted $ingredientQuantity $ingredientUnit from $matName in rawStock.");
              } else {
                print(
                    "Not enough stock for $matName. Needed: $ingredientQuantity $ingredientUnit, Available: $availableStock $stockUnit");
              }
            } else {
              print(
                  "Unit mismatch for $matName. Ingredient unit: $ingredientUnit, Stock unit: $stockUnit");
            }
          } else {
            print("Ingredient $matName not found in rawStock.");
          }
        }
      } else {
        print("Product $productName not found in products.");
      }
    }
  }

  void _showPaymentSuccessModal() {
    if (!mounted) return; // Check if the widget is still mounted
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to take more space if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment Successful',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Your order is now being processed.'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      // Navigate to Track Order page (you might need to create this page)
                    },
                    child: Text('Track Order', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerMainHome(
                            userName: widget.userName,
                            emailAddress: widget.emailAddress,
                            email: widget.email,
                            imageUrl: widget.imageUrl,
                            uid: widget.uid,
                            userAddress: widget.userAddress,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                        ),
                      );
                    },
                    child: Text('Back to Home', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Payment'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Order Summary Title
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15),

            // Cart Items
            _buildSectionTitle('Cart Items'),
            _buildCartItems(),

            SizedBox(height: 20),

            // Delivery and Payment Details
            _buildSectionTitle('Delivery & Payment Details'),
            _buildDetailsRow('Delivery Type:', widget.deliveryType),
            _buildDetailsRow('Payment Method:', widget.paymentMethod),
            if (widget.voucherCode.isNotEmpty) ...[
              _buildDetailsRow('Voucher Code:', widget.voucherCode),
              if (discountDescription.isNotEmpty)
                _buildDetailsRow('Discount:', discountDescription),
            ],
            _buildDetailsRow(
                'Total Amount:', '₱${widget.totalAmount.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            // User Information
            _buildSectionTitle('User Information'),
            _buildDetailsRow('Name:', widget.userName),
            _buildDetailsRow('Address:', widget.userAddress),
            _buildDetailsRow('Email:', widget.emailAddress),

            SizedBox(height: 20),

            // Order Information
            _buildSectionTitle('Order Information'),
            _buildDetailsRow('Order Type:', widget.orderType),

            SizedBox(height: 30),

            // Confirm Payment Button
            ElevatedButton(
              onPressed: _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Cart Items Widget
  Widget _buildCartItems() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[300]!, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: widget.cartItems.map((item) {
          final total = item['total'] ?? 0.0;
          final sizeQuantity = item['sizeQuantity'] ?? 'N/A';
          final quantity = item['quantity'] ?? 1;

          final size = (sizeQuantity == 'Small' ||
                  sizeQuantity == 'Medium' ||
                  sizeQuantity == 'Large')
              ? sizeQuantity
              : item['size'] ?? 'N/A';

          final variant = (sizeQuantity == '4 pcs' ||
                  sizeQuantity == '8 pcs' ||
                  sizeQuantity == '12 pcs')
              ? sizeQuantity
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                item['productName'],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              children: [
                if (variant != 'N/A')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Variant: $variant',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                if (size != 'N/A')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text('Size: $size', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text('Qty: $quantity', style: TextStyle(fontSize: 16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Total: ₱${total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Details Row Widget
  Widget _buildDetailsRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

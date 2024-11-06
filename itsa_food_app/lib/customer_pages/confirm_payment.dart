import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';

class ConfirmPayment extends StatefulWidget {
  final List<String> productNames;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmountWithDelivery;
  final String uid;
  final String orderType;
  final String userName;
  final String email;
  final String emailAddress;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String userAddress;

  const ConfirmPayment({
    super.key,
    required this.productNames,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmountWithDelivery,
    required this.uid,
    required this.orderType,
    required this.userName,
    required this.imageUrl,
    required this.email,
    required this.emailAddress,
    required this.latitude,
    required this.longitude,
    required this.userAddress,
  });

  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  String _generateOrderID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  Future<void> _submitPayment() async {
    // Get the current logged-in user's document ID
    final user = _auth.currentUser;
    if (user == null) return; // Exit if no user is logged in

    // Generate a unique order ID
    final orderID = _generateOrderID();

    // Create order details with orderType included
    final orderData = {
      'productNames': widget.productNames,
      'deliveryType': widget.deliveryType,
      'paymentMethod': widget.paymentMethod,
      'voucherCode': widget.voucherCode,
      'totalAmountWithDelivery': widget.totalAmountWithDelivery,
      'orderID': orderID,
      'orderType': widget.orderType, // Added orderType field
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Create "orders" subcollection in the "customer" collection
      await _firestore
          .collection('customer')
          .doc(widget.uid)
          .collection('orders')
          .doc(orderID) // Document name as orderID
          .set(orderData);

      // Create document in the "notifications" collection at the root level
      await _firestore
          .collection('notifications')
          .doc(orderID) // Document name as orderID
          .set(orderData);

      // Delete the entire "cart" subcollection after order submission
      await _deleteCartSubcollection();

      // Show the success modal
      _showSuccessModal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit payment. Try again!')),
      );
    }
  }

  Future<void> _deleteCartSubcollection() async {
    // Get the cart subcollection reference
    final cartRef =
        _firestore.collection('customer').doc(widget.uid).collection('cart');

    // Get all documents in the cart subcollection
    final cartDocs = await cartRef.get();

    // Delete each document in the cart subcollection
    for (var doc in cartDocs.docs) {
      await doc.reference.delete();
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Payment Successful'),
          content: Text('Payment successful. Order is now processing.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => Menu(
                        userName: widget.userName,
                            emailAddress: widget.emailAddress,
                            imageUrl: widget.imageUrl,
                            uid: widget.uid,
                            email: widget.email,
                            userAddress: widget.userAddress,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                      )), // Direct route to Menu
                );
              },
              child: Text('Go Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Payment'),
        backgroundColor: Color(0xFF2E0B0D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Proof of Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E0B0D),
              ),
            ),
            SizedBox(height: 20),
            for (String productName in widget.productNames)
              Text(
                'Product: $productName',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            SizedBox(height: 20),
            Text(
              'Delivery Type: ${widget.deliveryType}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Payment Method: ${widget.paymentMethod}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            if (widget.voucherCode.isNotEmpty)
              Text(
                'Selected Voucher: ${widget.voucherCode}',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            SizedBox(height: 20),
            Text(
              'Order Type: ${widget.orderType}', // Displaying orderType
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
            Text(
              'Total Amount with Delivery: ₱${widget.totalAmountWithDelivery.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 1),
                ),
                child: _image == null
                    ? Center(
                        child: Text('Tap to attach image',
                            style: TextStyle(color: Colors.grey[600])))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            Image.file(File(_image!.path), fit: BoxFit.cover),
                      ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E0B0D),
                padding: EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: Size(double.infinity, 56),
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

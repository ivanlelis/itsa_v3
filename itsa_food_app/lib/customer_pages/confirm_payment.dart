import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ConfirmPayment extends StatefulWidget {
  final List<String> productNames;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmountWithDelivery;
  final String uid;

  const ConfirmPayment({
    super.key,
    required this.productNames,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmountWithDelivery,
    required this.uid,
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

    // Create order details
    final orderData = {
      'productNames': widget.productNames,
      'deliveryType': widget.deliveryType,
      'paymentMethod': widget.paymentMethod,
      'voucherCode': widget.voucherCode,
      'totalAmountWithDelivery': widget.totalAmountWithDelivery,
      'orderID': orderID,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Create "orders" subcollection and add the order document
      await _firestore
          .collection('customer')
          .doc(widget.uid) // Assuming the document ID is the user's email
          .collection('orders')
          .doc(orderID) // Name the document with the order ID
          .set(orderData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit payment. Try again!')),
      );
    }
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

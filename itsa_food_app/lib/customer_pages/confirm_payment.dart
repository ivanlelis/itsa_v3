// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';

class ConfirmPayment extends StatefulWidget {
  final double totalAmountWithDelivery;
  final String productName;
  final String sizeQuantity;
  final String paymentMethod;
  final String deliveryType;
  final String voucherCode;

  const ConfirmPayment({
    super.key,
    required this.totalAmountWithDelivery,
    required this.productName,
    required this.sizeQuantity,
    required this.paymentMethod,
    required this.deliveryType,
    required this.voucherCode,
  });

  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void _submitPayment() async {
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;

    if (currentUser != null && _image != null) {
      try {
        await FirebaseFirestore.instance
            .collection('customer')
            .doc(currentUser.uid)
            .collection('orders')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'imagePath': _image!.path,
          'totalAmountWithDelivery': widget.totalAmountWithDelivery,
          'productName': widget.productName,
          'sizeQuantity': widget.sizeQuantity,
          'paymentMethod': widget.paymentMethod,
          'deliveryType': widget.deliveryType,
          'voucherCode': widget.voucherCode,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting payment: $e')),
        );
      }
    } else if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is currently logged in.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please attach proof of payment!')),
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
                        child: Text(
                          'Tap to attach image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Total Amount: ₱${widget.totalAmountWithDelivery.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E0B0D),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Product Name: ${widget.productName}',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Size/Quantity: ${widget.sizeQuantity}',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Payment Method: ${widget.paymentMethod}',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Delivery Type: ${widget.deliveryType}',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Voucher Code: ${widget.voucherCode}',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E0B0D),
                padding: EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(double.infinity, 56),
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

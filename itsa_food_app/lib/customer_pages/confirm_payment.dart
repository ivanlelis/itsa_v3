import 'dart:io'; // Import this to use the File class
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ConfirmPayment extends StatefulWidget {
  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  XFile? _image; // Store the selected image
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image; // Update the image state
    });
  }

  void _submitPayment() {
    // Handle payment submission logic here
    if (_image != null) {
      // Implement your submission logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment submitted successfully!')),
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
        backgroundColor: Color(0xFF2E0B0D), // Main color
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
            Spacer(), // This will push the button to the bottom
            ElevatedButton(
              onPressed: _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E0B0D), // Main color for button
                padding: EdgeInsets.symmetric(
                    vertical: 20), // Increase vertical padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize:
                    Size(double.infinity, 56), // Make the button bigger
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(
                  fontSize: 18, // Increase font size
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

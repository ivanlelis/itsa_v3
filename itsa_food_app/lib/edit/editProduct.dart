import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductEditModal extends StatefulWidget {
  final String productName;
  final String productType;
  final Map<String, String> prices;
  final String imageUrl; // Add imageUrl to hold the current product image URL

  const ProductEditModal({
    super.key,
    required this.productName,
    required this.productType,
    required this.prices,
    required this.imageUrl, // Add imageUrl to constructor
  });

  @override
  _ProductEditModalState createState() => _ProductEditModalState();
}

class _ProductEditModalState extends State<ProductEditModal> {
  late TextEditingController _productNameController;
  String? _selectedProductType;
  late Map<String, TextEditingController> _priceControllers;
  File? _selectedImage; // Holds the newly selected image

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.productName);
    _selectedProductType = widget.productType;
    _priceControllers = {
      ...widget.prices.map(
          (key, value) => MapEntry(key, TextEditingController(text: value))),
    };
  }

  void _updateProduct() async {
    final String newProductName = _productNameController.text.trim();
    final String newProductType = _selectedProductType!;

    CollectionReference productsCollection =
        FirebaseFirestore.instance.collection('products');
    DocumentReference productDoc = productsCollection
        .doc(widget.productName); // Use old product name for deletion

    String? imageUrl;

    // Upload new image if selected
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToFirebase(
          _selectedImage!, newProductName); // Pass both arguments
    } else {
      imageUrl = widget
          .imageUrl; // Keep the existing image URL if no new image is selected
    }

    // Create new product data based on the product type
    Map<String, dynamic> newProductData = {
      'productName': newProductName,
      'productType': newProductType,
      'imageUrl': imageUrl,
    };

    // Add specific fields based on product type
    if (newProductType == 'Milk Tea') {
      newProductData.addAll({
        'small': _priceControllers['Milk Tea Small']?.text.trim() ?? '',
        'medium': _priceControllers['Milk Tea Medium']?.text.trim() ?? '',
        'large': _priceControllers['Milk Tea Large']?.text.trim() ?? '',
      });
    } else if (newProductType == 'Takoyaki') {
      newProductData.addAll({
        '4pc': _priceControllers['Takoyaki 4 pcs']?.text.trim() ?? '',
        '8pc': _priceControllers['Takoyaki 8 pcs']?.text.trim() ?? '',
        '12pc': _priceControllers['Takoyaki 12 pcs']?.text.trim() ?? '',
      });
    } else if (newProductType == 'Meals') {
      newProductData.addAll({
        'price': _priceControllers['Meals Price']?.text.trim() ?? '',
      });
    }

    try {
      // Delete the old document first
      await productDoc.delete();

      // Create a new document with the updated data
      await productsCollection.doc(newProductName).set(newProductData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: $e')),
      );
    }
  }

  Future<String?> _uploadImageToFirebase(File image, String productName) async {
    try {
      String fileName =
          '$productName.jpg'; // Use productName as the filename with an appropriate extension

      // Set the correct path to the existing folder
      Reference storageRef = FirebaseStorage.instance.ref().child(
          'product_image/$fileName'); // Ensure this matches your existing folder

      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl; // Return the download URL of the uploaded image
    } catch (e) {
      print('Image upload failed: $e');
      return null; // Return null if upload fails
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Update the selected image
      });
    }
  }

  void _setPricesForProductType(String? productType) {
    for (var controller in _priceControllers.values) {
      controller.clear();
    }

    if (productType == 'Takoyaki') {
      _priceControllers = {
        'Takoyaki 4 pcs': TextEditingController(),
        'Takoyaki 8 pcs': TextEditingController(),
        'Takoyaki 12 pcs': TextEditingController(),
      };
    } else if (productType == 'Milk Tea') {
      _priceControllers = {
        'Milk Tea Small': TextEditingController(),
        'Milk Tea Medium': TextEditingController(),
        'Milk Tea Large': TextEditingController(),
      };
    } else if (productType == 'Meals') {
      _priceControllers = {
        'Meals Price': TextEditingController(),
      };
    }

    for (var entry in widget.prices.entries) {
      if (_priceControllers.containsKey(entry.key)) {
        _priceControllers[entry.key]?.text = entry.value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Product',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            Text('Select Product Type:'),
            DropdownButton<String>(
              value: _selectedProductType,
              items: ['Takoyaki', 'Milk Tea', 'Meals'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProductType = newValue;
                  _setPricesForProductType(newValue);
                });
              },
              hint: Text('Select Product Type'),
            ),
            const SizedBox(height: 16),
            Text('Set Prices:'),
            ..._priceControllers.entries.map((entry) {
              return TextField(
                controller: entry.value,
                decoration: InputDecoration(labelText: entry.key),
              );
            }),
            const SizedBox(height: 16),
            // Image preview section
            if (_selectedImage != null) ...[
              Image.file(_selectedImage!, height: 200, width: 200),
            ] else ...[
              Image.network(widget.imageUrl, height: 200, width: 200),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProduct,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

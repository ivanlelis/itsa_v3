// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print, empty_catches

import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:itsa_food_app/edit/editProduct.dart';
import 'dart:math'; // Import for random number generation

class MenuManagement extends StatefulWidget {
  const MenuManagement({super.key});

  @override
  _MenuManagementState createState() => _MenuManagementState();
}

class _MenuManagementState extends State<MenuManagement> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedCategoryIndex = 0;

  // Method to show the add product modal
  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const AddProductModal();
      },
    );
  }

  // Fetch products from Firestore
  Stream<QuerySnapshot> _getProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      // Modify this part of your code
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CategoryButton(
                  title: 'All',
                  index: 0,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 0;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Takoyaki',
                  index: 1,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 1;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Milk Tea',
                  index: 2,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 2;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Meals',
                  index: 3,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 3;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // StreamBuilder to listen to products in Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading products'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Get list of products from Firestore
                  final products = snapshot.data!.docs;

                  // Filter products based on selected category
                  final filteredProducts = products.where((product) {
                    if (_selectedCategoryIndex == 0) return true; // All
                    if (_selectedCategoryIndex == 1 &&
                        product['productType'] == 'Takoyaki') return true;
                    if (_selectedCategoryIndex == 2 &&
                        product['productType'] == 'Milk Tea') return true;
                    if (_selectedCategoryIndex == 3 &&
                        product['productType'] == 'Meals') return true;
                    return false;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products available'));
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        productName: product['productName'],
                        productType: product['productType'],
                        prices: _getProductPrices(product),
                        imageUrl: product['imageUrl'], // Pass the imageUrl
                        productID: product[
                            'productID'], // Add this line to pass the productID
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: AdminSidebar(onLogout: () {
        // Add logout logic here
      }),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: 2, // Set to the appropriate index for Menu Management
        onItemTapped: (index) {
          // Add navigation logic here
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, String> _getProductPrices(QueryDocumentSnapshot product) {
    final productType = product['productType'];
    if (productType == 'Takoyaki') {
      return {
        'Takoyaki 4 pcs': product['4pc'],
        'Takoyaki 8 pcs': product['8pc'],
        'Takoyaki 12 pcs': product['12pc'],
      };
    } else if (productType == 'Milk Tea') {
      return {
        'Milk Tea Small': product['small'],
        'Milk Tea Medium': product['medium'],
        'Milk Tea Large': product['large'],
      };
    } else if (productType == 'Meals') {
      return {
        'Meals Price': product['price'],
      };
    }
    return {};
  }
}

class AddProductModal extends StatefulWidget {
  const AddProductModal({super.key});

  @override
  _AddProductModalState createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  String? _selectedProductType;
  final TextEditingController _productNameController = TextEditingController();
  final Map<String, String> _variantPrices = {
    'Takoyaki': '',
    'Milk Tea': '',
    'Meals': '',
  };

  File? _selectedImage; // Variable to store selected image file

  // Method to pick an image from the device
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    } else {
      // Notify user that image selection failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected. Please select an image.')),
      );
    }
  }

  // Method to upload the selected image to Firebase Storage
  Future<String?> _uploadImageToFirebase(String productID) async {
    if (_selectedImage == null) return null;

    final destination = 'product_image/$productID.jpg';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to generate a random productID
  String _generateProductID() {
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = List.generate(
        6, (index) => characters[random.nextInt(characters.length)]).join();
    return 'itsa-$randomString';
  }

  // Method to save product details to Firestore
  Future<void> _saveProductToFirestore() async {
    final productName = _productNameController.text.trim();
    if (productName.isEmpty || _selectedProductType == null) {
      // Show an error if no product name or type is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter product name and select type')),
      );
      return;
    }

    // Ensure an image has been selected
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    // Generate productID
    final productID = _generateProductID();

    // Upload image to Firebase Storage with productID as the filename
    final imageUrl = await _uploadImageToFirebase(productID);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image. Please try again.')),
      );
      return;
    }

    // Create a document with the productID as the ID
    final productData = {
      'productID': productID,
      'productName': productName,
      'productType': _selectedProductType,
      'imageUrl': imageUrl, // Store the image URL in Firestore
    };

    // Add variant-specific prices to the document
    if (_selectedProductType == 'Takoyaki') {
      productData.addAll({
        '4pc': _variantPrices['Takoyaki 4pcs'] ?? '',
        '8pc': _variantPrices['Takoyaki 8pcs'] ?? '',
        '12pc': _variantPrices['Takoyaki 12pcs'] ?? '',
      });
    } else if (_selectedProductType == 'Milk Tea') {
      productData.addAll({
        'small': _variantPrices['Milk Tea Small'] ?? '',
        'medium': _variantPrices['Milk Tea Medium'] ?? '',
        'large': _variantPrices['Milk Tea Large'] ?? '',
      });
    } else if (_selectedProductType == 'Meals') {
      productData.addAll({
        'price': _variantPrices['Meals Price'] ?? '',
      });
    }

    // Save to Firestore using the productID as the document ID
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productID) // Document ID is the generated productID
        .set(productData);

    Navigator.pop(context); // Close the modal after saving
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height:
            MediaQuery.of(context).size.height * 0.85, // 85% of screen height
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Product',
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
              hint: Text('Select Product Type'),
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
                  _variantPrices
                      .clear(); // Reset prices for the selected product type
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedProductType != null) ...[
              Text('Set Prices for ${_selectedProductType!} Variants:'),
              if (_selectedProductType == 'Takoyaki') ...[
                TextField(
                  decoration: InputDecoration(labelText: '4pcs Price'),
                  onChanged: (value) {
                    _variantPrices['Takoyaki 4pcs'] = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: '8pcs Price'),
                  onChanged: (value) {
                    _variantPrices['Takoyaki 8pcs'] = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: '12pcs Price'),
                  onChanged: (value) {
                    _variantPrices['Takoyaki 12pcs'] = value;
                  },
                ),
              ] else if (_selectedProductType == 'Milk Tea') ...[
                TextField(
                  decoration: InputDecoration(labelText: 'Small Price'),
                  onChanged: (value) {
                    _variantPrices['Milk Tea Small'] = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Medium Price'),
                  onChanged: (value) {
                    _variantPrices['Milk Tea Medium'] = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Large Price'),
                  onChanged: (value) {
                    _variantPrices['Milk Tea Large'] = value;
                  },
                ),
              ] else if (_selectedProductType == 'Meals') ...[
                TextField(
                  decoration: InputDecoration(labelText: 'Meals Price'),
                  onChanged: (value) {
                    _variantPrices['Meals Price'] = value;
                  },
                ),
              ],
              const SizedBox(height: 16),
              if (_selectedImage != null) ...[
                Image.file(_selectedImage!, height: 200, width: 200), // Preview
              ],
              TextButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProductToFirestore,
                child: const Text('Add Product'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productName;
  final String productType;
  final Map<String, String> prices;
  final String imageUrl; // Directly using the provided imageUrl
  final String productID;

  const ProductCard({
    super.key,
    required this.productName,
    required this.productType,
    required this.prices,
    required this.imageUrl,
    required this.productID,
  });

  void _showEditProductModal(BuildContext context, String productID) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ProductEditModal(
          productName: productName,
          productType: productType,
          prices: prices,
          imageUrl: imageUrl,
          productID: productID, // Pass the productID
        );
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context, String productID) async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Delete from Firestore using the productID
      await FirebaseFirestore.instance
          .collection('products') // Update with your collection name
          .doc(productID) // Use productID as the document ID
          .delete();

      // Delete image from Firebase Storage using the productID
      await _deleteImageFromFirebaseStorage(productID);
    }
  }

  Future<void> _deleteImageFromFirebaseStorage(String productID) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref().child(
          'product_image/$productID.jpg'); // Use productID to locate the image
      await storageRef.delete();
    } catch (e) {
      print('Error deleting image from Firebase Storage: $e');
    }
  }

  Future<String> _getImageUrl() async {
    final Reference ref =
        FirebaseStorage.instance.ref().child('product_image/$productID.jpg');
    try {
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return ''; // Return an empty string if the image doesn't exist
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _getImageUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data!.isEmpty) {
                  return Container(); // No image, do not show anything
                } else {
                  return Image.network(
                    snapshot.data!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              productName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Type: $productType'),
            const SizedBox(height: 8),
            ...prices.entries.map((priceEntry) {
              String priceValue =
                  priceEntry.value.isNotEmpty ? priceEntry.value : 'N/A';
              return Text('${priceEntry.key}: ₱$priceValue');
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  _showEditProductModal(context, productID), // Pass productID
              child: const Text('Edit Product'),
            ),
            ElevatedButton(
              onPressed: () =>
                  _deleteProduct(context, productID), // Pass productID
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set color to red
              ),
              child: const Text('Delete Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onPressed;

  const CategoryButton({
    super.key,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedIndex == index ? Colors.deepPurple : Colors.grey[300],
          padding:
              EdgeInsets.symmetric(vertical: 12), // Adjust vertical padding
        ),
        onPressed: onPressed,
        child: Text(
          title,
          textAlign: TextAlign.center, // Center the text
          style: TextStyle(
            color: selectedIndex == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

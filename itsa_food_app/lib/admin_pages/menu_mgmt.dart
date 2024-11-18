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
        'Milk Tea Regular': product['regular'],
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
  final TextEditingController _tagController = TextEditingController();
  final Map<String, String> _variantPrices = {
    'Takoyaki': '',
    'Milk Tea': '',
    'Meals': '',
  };
  File? _selectedImage;

  // List to store ingredient name, quantity, and unit type controllers
  final List<Map<String, TextEditingController>> _ingredients = [];
  // List to store tags
  final List<String> _tags = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected. Please select an image.')),
      );
    }
  }

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

  String _generateProductID() {
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = List.generate(
        6, (index) => characters[random.nextInt(characters.length)]).join();
    return 'itsa-$randomString';
  }

  Future<void> _saveProductToFirestore() async {
    final productName = _productNameController.text.trim();
    if (productName.isEmpty || _selectedProductType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter product name and select type')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    final productID = _generateProductID();
    final imageUrl = await _uploadImageToFirebase(productID);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image. Please try again.')),
      );
      return;
    }

    final productData = {
      'productID': productID,
      'productName': productName,
      'productType': _selectedProductType,
      'imageUrl': imageUrl,
      'ingredients': _ingredients
          .map((ingredient) {
            final name = ingredient['name']?.text.trim();
            final quantity = ingredient['quantity']?.text.trim();
            final unit = ingredient['unit']?.text.trim();
            return {'name': name, 'quantity': '$quantity $unit'};
          })
          .where((ingredient) => ingredient['name']!.isNotEmpty)
          .toList(),
      'tags': _tags,
    };

    if (_selectedProductType == 'Takoyaki') {
      productData.addAll({
        '4pc': _variantPrices['Takoyaki 4pcs'] ?? '',
        '8pc': _variantPrices['Takoyaki 8pcs'] ?? '',
        '12pc': _variantPrices['Takoyaki 12pcs'] ?? '',
      });
    } else if (_selectedProductType == 'Milk Tea') {
      productData.addAll({
        'regular': _variantPrices['Milk Tea Regular'] ?? '',
        'large': _variantPrices['Milk Tea Large'] ?? '',
      });
    } else if (_selectedProductType == 'Meals') {
      productData.addAll({
        'price': _variantPrices['Meals Price'] ?? '',
      });
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productID)
        .set(productData);
    Navigator.pop(context);
  }

  void _addIngredientField() {
    setState(() {
      _ingredients.add({
        'name': TextEditingController(),
        'quantity': TextEditingController(),
        'unit': TextEditingController(),
      });
    });
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      _tagController.clear(); // Clear the input field after adding the tag
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
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
                  _variantPrices.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            // Variant Prices Logic Here...

            Text('Ingredients:'),
            Column(
              children: _ingredients
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: entry.value['name'],
                              decoration: InputDecoration(
                                labelText: 'Ingredient ${entry.key + 1}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: entry.value['quantity'],
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              hint: Text('Unit'),
                              value: entry.value['unit']?.text.isEmpty ?? true
                                  ? null
                                  : entry.value['unit']?.text,
                              items: ['pcs', 'ml', 'liters', 'grams', 'kg']
                                  .map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  entry.value['unit']?.text = newValue ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            TextButton(
              onPressed: _addIngredientField,
              child: Text('Add Ingredient'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0), // Reduced padding
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8.0,
                crossAxisAlignment:
                    WrapCrossAlignment.center, // Align tags vertically
                children: [
                  // Display existing tags
                  ..._tags.map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () => _removeTag(tag),
                      )),
                  // TextField for new tag input
                  TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add Tags Here...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      _addTag(value.trim());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProductToFirestore,
              child: Text('Save Product'),
            ),
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
    bool isSelected = index == selectedIndex;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 4.0), // Space between buttons
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.purple : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0), // Uniform padding
          ),
          child: Text(
            title, // Use title instead of label
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                        // Add prices based on product type
                        prices: _getProductPrices(product),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                // Currently empty; you can add logic to display products later
                children: const [], // Empty list to avoid displaying hardcoded items
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
        '4pcs': product['4pc'],
        '8pcs': product['8pc'],
        '12pcs': product['12pc'],
      };
    } else if (productType == 'Milk Tea') {
      return {
        'Small': product['small'],
        'Medium': product['medium'],
        'Large': product['large'],
      };
    } else if (productType == 'Meals') {
      return {
        'Price': product['price'],
      };
    }
    return {};
  }
}

class AddProductModal extends StatefulWidget {
  const AddProductModal({Key? key}) : super(key: key);

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

    // Create a document with the product name as the ID
    final productData = {
      'productName': productName,
      'productType': _selectedProductType,
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
        'price': _variantPrices['Meals'] ?? '',
      });
    }

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productName) // Document ID is the product name
        .set(productData);

    Navigator.pop(context); // Close the modal after saving
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                // Reset prices for the selected product type
                _variantPrices.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          // Display price input fields based on selected product type
          if (_selectedProductType != null) ...[
            Text('Set Prices for ${_selectedProductType!} Variants:'),
            if (_selectedProductType == 'Takoyaki') ...[
              TextField(
                decoration: InputDecoration(labelText: '4pcs Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Takoyaki 4pcs'] = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: '8pcs Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Takoyaki 8pcs'] = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: '12pcs Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Takoyaki 12pcs'] = value;
                  });
                },
              ),
            ] else if (_selectedProductType == 'Milk Tea') ...[
              TextField(
                decoration: InputDecoration(labelText: 'Small Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Milk Tea Small'] = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Medium Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Milk Tea Medium'] = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Large Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Milk Tea Large'] = value;
                  });
                },
              ),
            ] else if (_selectedProductType == 'Meals') ...[
              TextField(
                decoration: InputDecoration(labelText: 'Meals Price'),
                onChanged: (value) {
                  setState(() {
                    _variantPrices['Meals'] = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProductToFirestore,
              child: const Text('Add Product'),
            ),
          ],
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productName;
  final String productType;
  final Map<String, String> prices;

  const ProductCard({
    Key? key,
    required this.productName,
    required this.productType,
    required this.prices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Type: $productType'),
            const SizedBox(height: 8),
            ...prices.entries.map((priceEntry) {
              return Text('${priceEntry.key}: ₱${priceEntry.value}');
            }).toList(),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedIndex == index ? Colors.deepPurple : Colors.grey[300],
      ),
      onPressed: onPressed,
      child: Text(
        title,
        style: TextStyle(
          color: selectedIndex == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

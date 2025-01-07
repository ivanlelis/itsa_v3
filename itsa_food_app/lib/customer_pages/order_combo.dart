import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/widgets/addon_section.dart';

class OrderCombo extends StatefulWidget {
  final String comboName;
  final String userName;

  const OrderCombo({
    super.key,
    required this.comboName,
    required this.userName,
  });

  @override
  _OrderComboState createState() => _OrderComboState();
}

class _OrderComboState extends State<OrderCombo> {
  String? productName1;
  String? productName2;
  String? branchID;
  String? imageUrl1;
  String? imageUrl2;
  String? productDetail1;
  String? productDetail2;
  String? productType1;
  String? productType2;
  bool isLoading = true;
  int quantity = 1; // Default quantity

  @override
  void initState() {
    super.initState();
    _fetchComboDetails();
    _fetchUserBranchID();
  }

  Future<void> _fetchComboDetails() async {
    try {
      final customersRef = FirebaseFirestore.instance.collection('customer');
      final querySnapshot = await customersRef.get();

      for (var customerDoc in querySnapshot.docs) {
        final combosRef = customerDoc.reference.collection('combos');
        final combosSnapshot = await combosRef
            .where('comboName', isEqualTo: widget.comboName)
            .get();

        if (combosSnapshot.docs.isNotEmpty) {
          final comboDoc = combosSnapshot.docs.first.data();
          setState(() {
            productName1 = comboDoc['productName1'];
            productName2 = comboDoc['productName2'];
            isLoading = false;
          });
          _fetchProductDetails();
          break;
        }
      }
    } catch (e) {
      print('Error fetching combo details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserBranchID() async {
    try {
      final customersRef = FirebaseFirestore.instance.collection('customer');
      final querySnapshot = await customersRef
          .where('userName', isEqualTo: widget.userName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first.data();
        setState(() {
          branchID = userDoc['branchID'];
        });
      }
    } catch (e) {
      print('Error fetching user branchID: $e');
    }
  }

  Future<void> _fetchProductDetails() async {
    if (productName1 != null && productName2 != null && branchID != null) {
      try {
        String collectionName;
        if (branchID == 'branch 1') {
          collectionName = 'products';
        } else if (branchID == 'branch 2') {
          collectionName = 'products_branch1';
        } else if (branchID == 'branch 3') {
          collectionName = 'products_branch2';
        } else {
          return;
        }

        final productsRef =
            FirebaseFirestore.instance.collection(collectionName);

        // Fetch product 1 details
        final product1Doc = await productsRef
            .where('productName', isEqualTo: productName1)
            .limit(1)
            .get();

        if (product1Doc.docs.isNotEmpty) {
          final productData1 = product1Doc.docs.first.data();
          setState(() {
            imageUrl1 = productData1['imageUrl'];
            productType1 = productData1['productType'];
            if (productType1 == 'Takoyaki') {
              productDetail1 = productData1['4pc'];
            } else if (productType1 == 'Milk Tea') {
              productDetail1 = productData1['regular'];
            } else if (productType1 == 'Meals') {
              productDetail1 = productData1['price'];
            }
          });
        }

        // Fetch product 2 details
        final product2Doc = await productsRef
            .where('productName', isEqualTo: productName2)
            .limit(1)
            .get();

        if (product2Doc.docs.isNotEmpty) {
          final productData2 = product2Doc.docs.first.data();
          setState(() {
            imageUrl2 = productData2['imageUrl'];
            productType2 = productData2['productType'];
            if (productType2 == 'Takoyaki') {
              productDetail2 = productData2['4pc'];
            } else if (productType2 == 'Milk Tea') {
              productDetail2 = productData2['regular'];
            } else if (productType2 == 'Meals') {
              productDetail2 = productData2['price'];
            }
          });
        }
      } catch (e) {
        print('Error fetching product details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Combo'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (productName1 != null && productName2 != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductCard(
                      productName: productName1,
                      productDetail: productDetail1,
                      imageUrl: imageUrl1,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 32, thickness: 1),
                    _buildProductCard(
                      productName: productName2,
                      productDetail: productDetail2,
                      imageUrl: imageUrl2,
                    ),
                    const SizedBox(
                        height: 24), // Space between cards and add-ons section

                    // AddOnSection Widget goes here
                    AddOnSection(
                      productTypes: [
                        productType1 ?? '',
                        productType2 ?? '',
                      ],
                      onAddOnsSelected: (selectedAddOns) {
                        print('Selected Add-ons: $selectedAddOns');
                      },
                    ),
                  ],
                )
              else
                const Center(
                  child: Text(
                    'No products found for this combo.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
              const SizedBox(height: 5), // Adjust the space between sections
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total price and quantity selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHP ${calculateTotalPrice().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _quantitySelector(),
            ],
          ),
          const SizedBox(height: 16),
          // Add to Cart button
          _addToCartButton(),
        ],
      ),
    );
  }

  // Quantity selector widget
  Widget _quantitySelector() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (quantity > 1) {
              setState(() {
                quantity--;
              });
            }
          },
          icon: const Icon(Icons.remove, color: Colors.white),
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              quantity++;
            });
          },
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _addToCartButton() {
    return SizedBox(
      width:
          double.infinity, // Makes the button take the full width of its parent
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to cart successfully!')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // White background
          foregroundColor: Colors.brown, // Brown text
          padding: const EdgeInsets.symmetric(vertical: 16.0), // Adjusts height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
        ),
        child: const Text(
          'Add to Cart',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String? productName,
    required String? productDetail,
    required String? imageUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              productName ?? 'Unknown Product',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: PHP ${productDetail ?? "N/A"}.00',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double calculateTotalPrice() {
    double price1 =
        double.tryParse(productDetail1?.replaceAll(',', '') ?? '0') ?? 0;
    double price2 =
        double.tryParse(productDetail2?.replaceAll(',', '') ?? '0') ?? 0;

    // Multiply the sum of the prices by the quantity
    return (price1 + price2) * quantity;
  }
}

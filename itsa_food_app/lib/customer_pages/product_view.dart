// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductView extends StatefulWidget {
  final String productName;
  final String imageUrl;
  final String? takoyakiPrices;
  final String? takoyakiPrices8;
  final String? takoyakiPrices12;
  final String? milkTeaSmall;
  final String? milkTeaMedium;
  final String? milkTeaLarge;
  final String? mealsPrice;
  final String userName; // Non-nullable
  final String emailAddress; // Non-nullable
  final String productType; // Non-nullable
  final String uid;
  final String userAddress;
  final String email;
  final double latitude;
  final double longitude;

  const ProductView({
    super.key,
    required this.productName,
    required this.imageUrl,
    this.takoyakiPrices,
    this.takoyakiPrices8,
    this.takoyakiPrices12,
    this.milkTeaSmall,
    this.milkTeaMedium,
    this.milkTeaLarge,
    this.mealsPrice,
    required this.userName,
    required this.emailAddress,
    required this.productType,
    required this.uid,
    required this.userAddress,
    required this.email,
    required this.latitude,
    required this.longitude,
  });

  @override
  _ProductViewState createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  int _selectedQuantityIndex = 0;
  int _quantity = 1;
  double _totalPrice = 0.0;
  bool _takoyakiSauce = false;
  bool _bonitoFlakes = false;
  bool _mayonnaise = false;

  List<String> quantityOptions = [];
  List<String> prices = [];

  @override
  void initState() {
    super.initState();
    if (widget.takoyakiPrices != null) {
      quantityOptions = ['4 pcs', '8 pcs', '12 pcs'];
      prices = [
        widget.takoyakiPrices ?? '0',
        widget.takoyakiPrices8 ?? '0',
        widget.takoyakiPrices12 ?? '0',
      ];
    } else if (widget.mealsPrice != null) {
      quantityOptions = ['Price'];
      prices = [widget.mealsPrice ?? '0'];
    } else if (widget.milkTeaSmall != null) {
      quantityOptions = ['Small', 'Medium', 'Large'];
      prices = [
        widget.milkTeaSmall ?? '0',
        widget.milkTeaMedium ?? '0',
        widget.milkTeaLarge ?? '0',
      ];
    }
    assert(quantityOptions.length == prices.length);
    _totalPrice = double.parse(prices[_selectedQuantityIndex]);
  }

  void _updateTotalPrice() {
    double basePrice = double.parse(prices[_selectedQuantityIndex]);
    double addOnsPrice = (_takoyakiSauce ? 15 : 0) +
        (_bonitoFlakes ? 15 : 0) +
        (_mayonnaise ? 15 : 0);
    setState(() {
      _totalPrice = (basePrice + addOnsPrice) * _quantity;
    });
  }

  // Add to Cart function
  Future<void> addToCart({
    required String userName,
    required String productName,
    required String productType,
    required String sizeQuantity,
    required int quantity,
    required double total,
  }) async {
    try {
      CollectionReference cart = FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart');

      await cart.doc(productName).set({
        'productName': productName,
        'productType': productType,
        'sizeQuantity': sizeQuantity,
        'quantity': quantity,
        'total': total,
        'takoyakiSauce': _takoyakiSauce,
        'bonitoFlakes': _bonitoFlakes,
        'mayonnaise': _mayonnaise,
      });
      print('Item added to cart successfully!');
      // Optional: Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$productName added to cart!')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      // Optional: Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('customer')
                .doc(widget.uid)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainCart(
                          userName: widget.userName,
                          emailAddress: widget.emailAddress,
                          uid: widget.uid,
                          email: widget.email,
                          userAddress: widget.userAddress,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          imageUrl: widget.imageUrl,
                        ),
                      ),
                    );
                  },
                );
              }

              int itemCount = snapshot.data!.docs.length;

              return Stack(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainCart(
                            userName: widget.userName,
                            emailAddress: widget.emailAddress,
                            uid: widget.uid,
                            userAddress: widget.userAddress,
                            email: widget.email,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            imageUrl: widget.imageUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '₱${prices[_selectedQuantityIndex]}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16.0),
                  Text('Choose Quantity/Size:',
                      style: const TextStyle(fontSize: 16)),
                  ...List.generate(quantityOptions.length, (index) {
                    return RadioListTile<int>(
                      value: index,
                      groupValue: _selectedQuantityIndex,
                      title:
                          Text('${quantityOptions[index]} - ₱${prices[index]}'),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuantityIndex = value!;
                          _updateTotalPrice();
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                  _updateTotalPrice();
                                });
                              }
                            : null,
                      ),
                      Text('$_quantity', style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _quantity++;
                            _updateTotalPrice();
                          });
                        },
                      ),
                    ],
                  ),
                  if (widget.takoyakiPrices != null) ...[
                    const SizedBox(height: 16.0),
                    Text('Add-ons:', style: const TextStyle(fontSize: 16)),
                    CheckboxListTile(
                      title:
                          const Text('Takoyaki Sauce (Original/Spicy) - ₱15'),
                      value: _takoyakiSauce,
                      onChanged: (value) {
                        setState(() {
                          _takoyakiSauce = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Bonito Flakes - ₱15'),
                      value: _bonitoFlakes,
                      onChanged: (value) {
                        setState(() {
                          _bonitoFlakes = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Mayonnaise - ₱15'),
                      value: _mayonnaise,
                      onChanged: (value) {
                        setState(() {
                          _mayonnaise = value!;
                          _updateTotalPrice();
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _addToCart(); // Call the function to add to cart
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    String sizeQuantity;
    if (widget.productType == 'milktea') {
      sizeQuantity =
          quantityOptions[_selectedQuantityIndex]; // e.g., small, medium, large
    } else if (widget.productType == 'takoyaki') {
      sizeQuantity =
          quantityOptions[_selectedQuantityIndex]; // e.g., 4pc, 8pc, 12pc
    } else {
      sizeQuantity = ''; // Meals don't have size/quantity specified
    }

    try {
      CollectionReference cart = FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart');

      // Add a new document with unique ID to allow multiple configurations
      await cart.add({
        'productName': widget.productName,
        'productType': widget.productType,
        'sizeQuantity': sizeQuantity,
        'quantity': _quantity,
        'total': _totalPrice,
        'takoyakiSauce': _takoyakiSauce,
        'bonitoFlakes': _bonitoFlakes,
        'mayonnaise': _mayonnaise,
      });

      print('Item added to cart successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.productName} added to cart!')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart. Please try again.')),
      );
    }
  }
}

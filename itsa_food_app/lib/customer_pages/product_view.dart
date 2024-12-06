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
  final String? milkTeaRegular;
  final String? milkTeaLarge;
  final String? mealsPrice;
  final String? userName; // Non-nullable
  final String? emailAddress; // Non-nullable
  final String? productType; // Non-nullable
  final String? uid;
  final String? userAddress;
  final String? email;
  final double latitude;
  final double longitude;
  final String? branchID;

  const ProductView({
    super.key,
    required this.productName,
    required this.imageUrl,
    this.takoyakiPrices,
    this.takoyakiPrices8,
    this.takoyakiPrices12,
    this.milkTeaRegular,
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
    required this.branchID,
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
  bool _pearls = false;
  bool _creampuff = false;
  bool _nata = false;
  bool _oreo = false;
  bool _jelly = false;

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
    } else if (widget.milkTeaRegular != null) {
      quantityOptions = ['Regular', 'Large'];
      prices = [
        widget.milkTeaRegular ?? '0',
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
        (_mayonnaise ? 15 : 0) +
        (_pearls ? 15 : 0) +
        (_creampuff ? 20 : 0) +
        (_nata ? 15 : 0) +
        (_oreo ? 15 : 0) +
        (_jelly ? 15 : 0);
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
    required String branchID,
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
        'pearls': _pearls,
        'creampuff': _creampuff,
        'nata': _nata,
        'oreo': _oreo,
        'jelly': _jelly,
      });
    } catch (e) {}
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
                          branchID: widget.branchID,
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
                            branchID: widget.branchID,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                          'PHP ${prices[_selectedQuantityIndex]}.00',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16.0),
                        // Quantity Options with styled container
                        ...List.generate(quantityOptions.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical:
                                    5.0), // Added vertical margin for space between containers
                            padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                                horizontal:
                                    4.0), // Smaller padding for smaller container height
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  12.0), // Smaller border radius
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: RadioListTile<int>(
                              value: index,
                              groupValue: _selectedQuantityIndex,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0.0,
                                  horizontal:
                                      4.0), // Minimal padding for a compact layout
                              title: Text(
                                '${quantityOptions[index]} - PHP ${prices[index]}.00',
                                style: const TextStyle(
                                    fontSize: 15), // Smaller font size
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedQuantityIndex = value!;
                                  _updateTotalPrice();
                                });
                              },
                            ),
                          );
                        }),
                        const SizedBox(
                            height:
                                10.0), // Added space between quantity options and next section
                        if (widget.takoyakiPrices != null) ...[
                          const SizedBox(height: 10.0), // Reduced space
                          Text('Add-ons:',
                              style: const TextStyle(
                                  fontSize: 16)), // Smaller font size
                          ...[
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text(
                                    'Takoyaki Sauce (Original/Spicy) (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _takoyakiSauce,
                                onChanged: (value) {
                                  setState(() {
                                    _takoyakiSauce = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Bonito Flakes (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _bonitoFlakes,
                                onChanged: (value) {
                                  setState(() {
                                    _bonitoFlakes = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Mayonnaise (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _mayonnaise,
                                onChanged: (value) {
                                  setState(() {
                                    _mayonnaise = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                        if (widget.milkTeaRegular != null) ...[
                          const SizedBox(height: 10.0), // Reduced space
                          Text('Add-ons:',
                              style: const TextStyle(
                                  fontSize: 14)), // Smaller font size
                          ...[
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Black Pearls (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _pearls,
                                onChanged: (value) {
                                  setState(() {
                                    _pearls = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Cream Puff (PHP 20)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _creampuff,
                                onChanged: (value) {
                                  setState(() {
                                    _creampuff = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Nata (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _nata,
                                onChanged: (value) {
                                  setState(() {
                                    _nata = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Oreo Crushed (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _oreo,
                                onChanged: (value) {
                                  setState(() {
                                    _oreo = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Coffee Jelly (PHP 15)',
                                    style: TextStyle(
                                        fontSize: 15)), // Smaller font size
                                value: _jelly,
                                onChanged: (value) {
                                  setState(() {
                                    _jelly = value!;
                                    _updateTotalPrice();
                                  });
                                },
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown, // Background color of the container
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25), // Rounded top corners
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total Price and Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Price
                    Text(
                      'PHP ${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white, // Text color
                        fontSize: 20, // Font size for total
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                    // Quantity Selector
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                    _updateTotalPrice();
                                  });
                                }
                              : null,
                          child: CircleAvatar(
                            radius: 12, // Circle size
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.remove,
                              color: Colors.green, // Icon color
                              size: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: Colors.white, // Quantity text color
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _quantity++;
                              _updateTotalPrice();
                            });
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.add,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing between rows
                // Add to Cart Button
                SizedBox(
                  width: double.infinity, // Make the button full width
                  height: 50, // Adjust height as needed
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(25), // Rounded button
                      ),
                    ),
                    onPressed: () {
                      _addToCart(); // Call the function to add to cart
                    },
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        color: Colors.brown, // Text color
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    } catch (e) {}
  }
}

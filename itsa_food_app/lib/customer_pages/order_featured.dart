import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';

class OrderFeatured extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;
  final String productName;
  final DateTime startDate;
  final DateTime endDate;
  final String exBundle;

  const OrderFeatured({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.imageUrl,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
    required this.productName,
    required this.startDate,
    required this.endDate,
    required this.exBundle,
  });

  @override
  _OrderFeaturedState createState() => _OrderFeaturedState();
}

class _OrderFeaturedState extends State<OrderFeatured> {
  int _quantity = 1;
  double _totalPrice = 0.0;
  int _selectedQuantityIndex = 0;
  String _productType = "";

  List<String> quantityOptions = [];
  List<double> prices = [];

  // Track selected add-ons for Milk Tea
  late Map<String, bool> selectedAddOns;

  // Define milk tea add-ons globally in the class
  final List<Map<String, dynamic>> milkTeaAddOns = [
    {'name': 'Black Pearls', 'price': 15.0},
    {'name': 'Cream Puff', 'price': 20.0},
    {'name': 'Nata', 'price': 15.0},
    {'name': 'Oreo Crushed', 'price': 15.0},
    {'name': 'Coffee Jelly', 'price': 15.0},
  ];

  @override
  void initState() {
    super.initState();
    fetchProductType();
    // Initialize selectedAddOns here
    selectedAddOns = {
      for (var addOn in milkTeaAddOns) addOn['name'] as String: false
    };
  }

  Future<void> fetchProductType() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productName', isEqualTo: widget.productName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _productType = snapshot.docs.first['productType'] ?? "";

          if (_productType == "Milk Tea") {
            quantityOptions = ['Regular', 'Large'];
            prices = [55.0, 75.0];
          } else if (_productType == "Takoyaki") {
            quantityOptions = ['4 pcs', '8 pcs', '12 pcs'];
            prices = [45.0, 85.0, 120.0];
          } else if (_productType == "Meals") {
            quantityOptions = ['Price'];
            prices = [99.0];
          }

          _totalPrice = prices[_selectedQuantityIndex];
        });
      }
    } catch (e) {
      print('Error fetching product type: $e');
    }
  }

  void _updateTotalPrice() {
    double addOnTotal = milkTeaAddOns.fold(0.0, (sum, addOn) {
      if (selectedAddOns[addOn['name']] ?? false) {
        return sum + addOn['price'];
      }
      return sum;
    });

    setState(() {
      _totalPrice = prices[_selectedQuantityIndex] * _quantity + addOnTotal;
    });
  }

  void addToCart({
    required String userName,
    required String productName,
    required String productType,
    required String sizeQuantity,
    required int quantity,
    required double total,
  }) {
    print(
        'Adding to cart: $productName, $sizeQuantity, Quantity: $quantity, Total: ₱$total');
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

                  const SizedBox(height: 16.0),
                  Text('Choose Quantity/Size:',
                      style: const TextStyle(fontSize: 16)),
                  // Quantity/Size options
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

                  const SizedBox(height: 16.0),
                  if (_productType == 'Milk Tea') ...[
                    Text('Add-ons:', style: TextStyle(fontSize: 16)),
                    ...milkTeaAddOns.map((addOn) {
                      final addOnName = addOn['name'] as String;
                      final addOnPrice = addOn['price'] as double;
                      return CheckboxListTile(
                        title: Text('$addOnName (₱$addOnPrice)'),
                        value: selectedAddOns[addOnName] ?? false,
                        onChanged: (value) {
                          setState(() {
                            selectedAddOns[addOnName] = value!;
                            _updateTotalPrice();
                          });
                        },
                      );
                    }),
                  ],

                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _addToCart, // Calls the _addToCart method directly
                        child: Text('Add to Cart'),
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

  // Your _addToCart method definition remains the same:
  Future<void> _addToCart() async {
    String sizeQuantity;
    if (_productType == 'Milk Tea') {
      sizeQuantity =
          quantityOptions[_selectedQuantityIndex]; // e.g., small, medium, large
    } else if (_productType == 'Takoyaki') {
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
        'productType': _productType,
        'sizeQuantity': sizeQuantity,
        'quantity': _quantity,
        'total': _totalPrice,
      });
    } catch (e) {
      print("Error adding to cart: $e"); // You may want to handle the error
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';

class OrderTrending extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;
  final String productName;
  final String? productImageUrl; // New parameter
  final String? productType; // New parameter
  final String? productDetail; // New parameter

  const OrderTrending({
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
    this.productImageUrl, // New parameter
    this.productType, // New parameter
    this.productDetail, // New parameter
  });

  @override
  _OrderTrendingState createState() => _OrderTrendingState();
}

class _OrderTrendingState extends State<OrderTrending> {
  int _quantity = 1;
  double _totalPrice = 0.0;
  int _selectedQuantityIndex = 0;
  String _productType = "";

  List<String> quantityOptions = [];
  List<double> prices = [];

  @override
  void initState() {
    super.initState();
    fetchProductType();
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
          _productType = widget.productType ?? 'Unknown';

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
    setState(() {
      _totalPrice = prices[_selectedQuantityIndex] * _quantity;
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
              widget.productImageUrl ?? 'default_image_url',
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
                  Text(
                      'Product Type: ${widget.productType}', // Display productType
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16.0),
                  Text(
                      'Product Details: ${widget.productDetail}', // Display productDetail
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16.0),
                  Text('Choose Quantity/Size: ',
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
                        onPressed: () {
                          addToCart(
                            userName: widget.userName,
                            productName: widget.productName,
                            productType: widget.productType ?? 'Unknown',
                            sizeQuantity:
                                quantityOptions[_selectedQuantityIndex],
                            quantity: _quantity,
                            total: _totalPrice,
                          );
                        },
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
}

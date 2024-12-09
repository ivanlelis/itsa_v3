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
    Map<String, double> addOnPrices = {
      'Takoyaki Sauce': 15.00,
      'Bonito Flakes': 15.00,
      'Mayonnaise': 15.00,
      'Black Pearls': 15.00,
      'Cream Puff': 20.00,
      'Nata': 15.00,
      'Oreo Crushed': 15.00,
      'Coffee Jelly': 15.00,
    };

    double addOnsPrice = 0.0;

    // Calculate the total price of selected add-ons
    if (_takoyakiSauce) addOnsPrice += addOnPrices['Takoyaki Sauce']!;
    if (_bonitoFlakes) addOnsPrice += addOnPrices['Bonito Flakes']!;
    if (_mayonnaise) addOnsPrice += addOnPrices['Mayonnaise']!;
    if (_pearls) addOnsPrice += addOnPrices['Black Pearls']!;
    if (_creampuff) addOnsPrice += addOnPrices['Cream Puff']!;
    if (_nata) addOnsPrice += addOnPrices['Nata']!;
    if (_oreo) addOnsPrice += addOnPrices['Oreo Crushed']!;
    if (_jelly) addOnsPrice += addOnPrices['Coffee Jelly']!;

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
          onPressed: () => Navigator.of(context).pop(),
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
                return _cartIcon(context);
              }
              int itemCount = snapshot.data!.docs.length;
              return Stack(
                children: <Widget>[
                  _cartIcon(context),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _cartBadge(itemCount),
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
            Image.network(widget.imageUrl,
                height: 250, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _productNameAndPrice(),
                  ..._buildQuantityOptions(),
                  if (widget.takoyakiPrices != null)
                    ..._buildAddOns('Takoyaki'),
                  if (widget.milkTeaRegular != null)
                    ..._buildAddOns('Milk Tea'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _cartIcon(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      onPressed: () => Navigator.push(
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
            takoyakiSauce: _takoyakiSauce,
            bonitoFlakes: _bonitoFlakes,
            mayonnaise: _mayonnaise,
            pearls: _pearls,
            creampuff: _creampuff,
            nata: _nata,
            oreo: _oreo,
            jelly: _jelly,
            selectedQuantityIndex:
                _selectedQuantityIndex, // Pass as optional parameter
          ),
        ),
      ),
    );
  }

  Widget _cartBadge(int itemCount) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        '$itemCount',
        style: const TextStyle(color: Colors.white, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _productNameAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.productName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Text('PHP ${prices[_selectedQuantityIndex]}.00',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16.0),
      ],
    );
  }

  List<Widget> _buildQuantityOptions() {
    return List.generate(quantityOptions.length, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade300)),
        child: RadioListTile<int>(
          value: index,
          groupValue: _selectedQuantityIndex,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
          title: Text('${quantityOptions[index]} - PHP ${prices[index]}.00',
              style: const TextStyle(fontSize: 15)),
          onChanged: (value) {
            setState(() {
              _selectedQuantityIndex = value!;
              _updateTotalPrice();
            });
          },
        ),
      );
    });
  }

  List<Widget> _buildAddOns(String type) {
    Map<String, double> addOnPrices = {
      'Takoyaki Sauce': 15.0,
      'Bonito Flakes': 15.0,
      'Mayonnaise': 15.0,
      'Black Pearls': 15.0,
      'Cream Puff': 20.0,
      'Nata': 15.0,
      'Oreo Crushed': 15.0,
      'Coffee Jelly': 15.0,
    };

    List<String> addOns = type == 'Takoyaki'
        ? ['Takoyaki Sauce', 'Bonito Flakes', 'Mayonnaise']
        : [
            'Black Pearls',
            'Cream Puff',
            'Nata',
            'Oreo Crushed',
            'Coffee Jelly'
          ];

    return [
      const SizedBox(height: 10.0),
      Text('Add-ons:', style: const TextStyle(fontSize: 14)),
      ...addOns.map((addOn) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 4.0),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade300)),
          child: CheckboxListTile(
            title: Text(
              '$addOn (PHP ${addOnPrices[addOn]})',
              style: const TextStyle(fontSize: 15),
            ),
            value: _getAddOnState(addOn),
            onChanged: (value) {
              setState(() {
                _setAddOnState(addOn, value!);
                _updateTotalPrice();
              });
            },
          ),
        );
      })
    ];
  }

  bool _getAddOnState(String addOn) {
    switch (addOn) {
      case 'Takoyaki Sauce':
        return _takoyakiSauce;
      case 'Bonito Flakes':
        return _bonitoFlakes;
      case 'Mayonnaise':
        return _mayonnaise;
      case 'Black Pearls':
        return _pearls;
      case 'Cream Puff':
        return _creampuff;
      case 'Nata':
        return _nata;
      case 'Oreo Crushed':
        return _oreo;
      case 'Coffee Jelly':
        return _jelly;
      default:
        return false;
    }
  }

  void _setAddOnState(String addOn, bool value) {
    switch (addOn) {
      case 'Takoyaki Sauce':
        _takoyakiSauce = value;
        break;
      case 'Bonito Flakes':
        _bonitoFlakes = value;
        break;
      case 'Mayonnaise':
        _mayonnaise = value;
        break;
      case 'Black Pearls':
        _pearls = value;
        break;
      case 'Cream Puff':
        _creampuff = value;
        break;
      case 'Nata':
        _nata = value;
        break;
      case 'Oreo Crushed':
        _oreo = value;
        break;
      case 'Coffee Jelly':
        _jelly = value;
        break;
    }
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PHP ${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              _quantitySelector(),
            ],
          ),
          const SizedBox(height: 16),
          _addToCartButton(),
        ],
      ),
    );
  }

  Widget _quantitySelector() {
    return Row(
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
            radius: 12,
            backgroundColor: Colors.white,
            child: Icon(Icons.remove, color: Colors.green, size: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$_quantity',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
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
            child: Icon(Icons.add, color: Colors.green, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _addToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25))),
        onPressed: _addToCart,
        child: const Text('Add to Cart',
            style: TextStyle(
                color: Colors.brown,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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

    // Calculate the add-ons price
    double addOnsPrice = (_takoyakiSauce ? 15 : 00) +
        (_bonitoFlakes ? 15 : 0) +
        (_mayonnaise ? 15 : 0) +
        (_pearls ? 15 : 0) +
        (_creampuff ? 20 : 0) +
        (_nata ? 15 : 0) +
        (_oreo ? 15 : 0) +
        (_jelly ? 15 : 0);

    // Final price including base and add-ons
    double totalPrice =
        double.parse(prices[_selectedQuantityIndex]) + addOnsPrice;

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
        'total': totalPrice * _quantity,
        'takoyakiSauce': _takoyakiSauce,
        'bonitoFlakes': _bonitoFlakes,
        'mayonnaise': _mayonnaise,
        'coffeeJelly': _jelly,
        'oreo': _oreo,
        'nata': _nata,
        'pearls': _pearls,
        'creampuff': _creampuff,
      });
    } catch (e) {
      // Handle error appropriately
      print("Error adding to cart: $e");
    }
  }
}

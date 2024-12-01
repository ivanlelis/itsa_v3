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
  final String branchID;

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
    required this.branchID,
  });

  @override
  _OrderFeaturedState createState() => _OrderFeaturedState();
}

class _OrderFeaturedState extends State<OrderFeatured> {
  int _quantity = 1;
  double _totalPrice = 0.0;
  String _selectedQuantityIndex = '';
  String _productType = "";
  final double _addOnTotal = 0.0;

  List<String> quantityOptions = [];
  List<double> prices = [];
  List<Map<String, String>> productDetails = [];
  int? selectedCardIndex;
  ValueNotifier<int?> selectedCardIndexNotifier = ValueNotifier<int?>(null);

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

    if (widget.exBundle == "1 Free Regular Milktea") {
      fetchProductDetails(); // Fetch product names if exBundle condition is met
    }
  }

  Future<void> fetchProductDetails() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      setState(() {
        productDetails = snapshot.docs.map((doc) {
          return {
            'productName': doc['productName'] as String,
            'imageUrl': doc['imageUrl'] as String,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching product details: $e');
    }
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

          // Set quantity options and prices based on product type
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

          // Set total price based on selected quantity
          _updateTotalPrice();
        });
      }
    } catch (e) {
      print('Error fetching product type: $e');
    }
  }

  void _updateTotalPrice() {
    // Find the index of the selected quantity and calculate the total price
    int selectedIndex = quantityOptions.indexOf(_selectedQuantityIndex);
    if (selectedIndex != -1) {
      _totalPrice = prices[selectedIndex] * _quantity + _addOnTotal;
    }
  }

  @override
  void dispose() {
    selectedCardIndexNotifier.dispose(); // Don't forget to dispose
    super.dispose();
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
                  ...List.generate(quantityOptions.length, (index) {
                    return RadioListTile<String>(
                      // Change the type to String
                      value: quantityOptions[
                          index], // Store the actual quantity/size value
                      groupValue: _selectedQuantityIndex,
                      title:
                          Text('${quantityOptions[index]} - ₱${prices[index]}'),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuantityIndex =
                              value!; // Now holding the actual value
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
                  if (widget.exBundle == "1 Free Regular Milktea")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              "Select 1 Free Regular-sized Milktea",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth = 150; // Width of each card
                            double spacing =
                                8.0; // Horizontal spacing between cards
                            int cardsPerRow =
                                (constraints.maxWidth / (cardWidth + spacing))
                                    .floor();

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Wrap(
                                  spacing:
                                      spacing, // Horizontal spacing between cards
                                  runSpacing:
                                      spacing, // Vertical spacing between cards
                                  alignment: WrapAlignment.start,
                                  children: List.generate(productDetails.length,
                                      (index) {
                                    final productDetail = productDetails[index];
                                    final isSelected =
                                        selectedCardIndex == index;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (selectedCardIndex == index) {
                                            // Unselect the card if it's already selected
                                            selectedCardIndex = null;
                                          } else {
                                            // Select the card
                                            selectedCardIndex = index;
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        width: (constraints.maxWidth -
                                                (cardsPerRow - 1) * spacing) /
                                            cardsPerRow,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: isSelected
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.white,
                                          boxShadow: isSelected
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ],
                                        ),
                                        transform: isSelected
                                            ? (Matrix4.identity()
                                              ..scale(
                                                  0.95)) // Use cascade operator
                                            : Matrix4.identity(),
                                        child: Stack(
                                          children: [
                                            Card(
                                              elevation: isSelected ? 0 : 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12),
                                                      topRight:
                                                          Radius.circular(12),
                                                    ),
                                                    child: Image.network(
                                                      productDetail[
                                                          'imageUrl']!,
                                                      height: 140,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      color: isSelected
                                                          ? Colors.black
                                                              .withOpacity(0.3)
                                                          : null,
                                                      colorBlendMode: isSelected
                                                          ? BlendMode.darken
                                                          : null,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      productDetail[
                                                          'productName']!,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.green,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            );
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
                          _addToCart(); // Pass the selectedCardIndex when calling _addToCart
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

  Future<void> _addToCart() async {
    String? selectedItemName;

    // Assign the selected product name based on the selectedCardIndex
    if (selectedCardIndex != null) {
      selectedItemName = productDetails[selectedCardIndex!]['productName'];
    }

    try {
      CollectionReference cart = FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart');

      // Get all documents inside the cart collection
      QuerySnapshot existingItems = await cart.get();

      bool isItemFoundWithSelectedItemName = false;

      // Loop through the documents in the cart collection
      for (var doc in existingItems.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Check if the document has a 'selectedItemName' field
        if (data.containsKey('selectedItemName')) {
          // If the selectedItemName in Firestore is different from the one to be added
          if (data['selectedItemName'] != selectedItemName) {
            // Update the existing document with the new selectedItemName
            await doc.reference.update({
              'selectedItemName': selectedItemName,
            });
          }
          isItemFoundWithSelectedItemName = true;
          break; // Exit the loop if we find any matching `selectedItemName`
        }
      }

      // If no matching selectedItemName was found, create a new document without selectedItemName
      if (!isItemFoundWithSelectedItemName) {
        await cart.add({
          'productName': widget.productName,
          'productType': _productType,
          'sizeQuantity': _selectedQuantityIndex,
          'quantity': _quantity,
          'total': _totalPrice,
          // Add selectedItemName only if no matching item exists
          if (selectedItemName != null) 'selectedItemName': selectedItemName,
        });
      } else {
        // If a matching selectedItemName was found, create a new document without selectedItemName
        await cart.add({
          'productName': widget.productName,
          'productType': _productType,
          'sizeQuantity': _selectedQuantityIndex,
          'quantity': _quantity,
          'total': _totalPrice,
        });
      }
    } catch (e) {
      print('Failed to add to cart: $e');
    }
  }
}

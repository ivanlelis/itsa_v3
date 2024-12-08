// ignore_for_file: library_private_types_in_public_api, avoid_print, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/checkout.dart';

class MainCart extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? uid;
  final String? email;
  final String? imageUrl;
  final String? userAddress;
  final double latitude;
  final double longitude;
  final String? branchID;
  final bool? takoyakiSauce;
  final bool? bonitoFlakes;
  final bool? mayonnaise;
  final bool? pearls;
  final bool? creampuff;
  final bool? nata;
  final bool? oreo;
  final bool? jelly;
  final int? selectedQuantityIndex; // Nullable parameter

  const MainCart({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.uid,
    required this.email,
    required this.imageUrl,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
    required this.branchID,
    this.takoyakiSauce,
    this.bonitoFlakes,
    this.mayonnaise,
    this.pearls,
    this.creampuff,
    this.nata,
    this.oreo,
    this.jelly,
    this.selectedQuantityIndex,
  });

  @override
  _MainCartState createState() => _MainCartState();
}

class _MainCartState extends State<MainCart> {
  List<Map<String, dynamic>> cartItems = [];
  String? selectedItemName;
  final Map<String, String> addOnFieldMapping = {
    'Bonito Flakes': 'bonitoFlakes',
    'Coffee Jelly': 'coffeeJelly',
    'Creampuff': 'creampuff',
    'Mayonnaise': 'mayonnaise',
    'Nata': 'nata',
    'Oreo': 'oreo',
    'Pearls': 'pearls',
    'Takoyaki Sauce': 'takoyakiSauce',
  };

  final Map<String, double> addOnPrices = {
    'Bonito Flakes': 15.0,
    'Coffee Jelly': 15.0,
    'Creampuff': 20.0,
    'Mayonnaise': 15.0,
    'Nata': 15.0,
    'Oreo': 15.0,
    'Pearls': 15.0,
    'Takoyaki Sauce': 15.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<DocumentSnapshot?> _fetchProductType(String selectedItemName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productName', isEqualTo: selectedItemName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first; // Return the document if found
      }
      return null; // Explicitly return null if no document matches
    } catch (e) {
      print('Error fetching product type for $selectedItemName: $e');
      return null;
    }
  }

  Future<void> _fetchCartItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart')
          .get();

      setState(() {
        cartItems = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Set selectedItemName to the value of the first cart item (if any)
          if (data.containsKey('selectedItemName')) {
            selectedItemName =
                data['selectedItemName']; // Update the class-level variable
          } else {
            selectedItemName = null; // No item selected, set to null
          }

          // Fetch add-on fields from the cart document
          return {
            'id': doc.id, // Store document ID for deletion
            'productName': data.containsKey('productName')
                ? data['productName']
                : 'Unnamed Product',
            'selectedItemName': data.containsKey('selectedItemName')
                ? data['selectedItemName']
                : null,
            'sizeQuantity': data.containsKey('sizeQuantity')
                ? data['sizeQuantity']
                : 'Unknown',
            'quantity': data.containsKey('quantity') ? data['quantity'] : 1,
            'total': data.containsKey('total') ? data['total'] : 0.0,
            'bonitoFlakes': data['bonitoFlakes'] ?? false,
            'coffeeJelly': data['coffeeJelly'] ?? false,
            'creampuff': data['creampuff'] ?? false,
            'mayonnaise': data['mayonnaise'] ?? false,
            'nata': data['nata'] ?? false,
            'oreo': data['oreo'] ?? false,
            'pearls': data['pearls'] ?? false,
            'takoyakiSauce': data['takoyakiSauce'] ?? false,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> _deleteCartItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart')
          .doc(docId)
          .delete();
      print('Item deleted successfully!');
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  void _proceedToCheckout({required String? selectedItemName}) {
    if (cartItems.isEmpty) {
      // Show a dialog if the cart is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cart is empty'),
          content: const Text('Add some items to your cart first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Proceed to checkout if there are items in the cart
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Checkout(
            userName: widget.userName,
            emailAddress: widget.emailAddress,
            totalAmount:
                cartItems.fold(0.0, (sum, item) => sum + item['total']),
            uid: widget.uid,
            email: widget.email,
            imageUrl: widget.imageUrl,
            latitude: widget.latitude,
            longitude: widget.longitude,
            userAddress: widget.userAddress,
            cartItems: cartItems,
            branchID: widget.branchID,
            selectedItemName:
                selectedItemName ?? 'No item selected', // Default value if null
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6E473B),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final productName =
                          item['productName'] ?? 'Unnamed Product';
                      return Column(
                        children: [
                          _buildCartItemCard(item, index, productName),
                          if (item['selectedItemName'] != null)
                            _buildSelectedItemCard(item['selectedItemName']),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          _buildTotalAmount(),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
      Map<String, dynamic> item, int index, String productName) {
    return Dismissible(
      key: Key('${item['id']}-productName'),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteCartItem(item['id']);
        setState(() => cartItems.removeAt(index));
      },
      child: _buildCardContent(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            _buildInfoText('Size: ${item['sizeQuantity']}'),
            _buildQuantityControl(item, index),
            _buildInfoText(
              'Total: ₱${item['total'].toStringAsFixed(2)}',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildAddOnsList(item),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(Map<String, dynamic> item, int index) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.white),
          onPressed: () {
            if (item['quantity'] > 1) {
              _updateQuantity(item, index, item['quantity'] - 1);
            }
          },
        ),
        Text(
          '${item['quantity']}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.white),
          onPressed: () {
            _updateQuantity(item, index, item['quantity'] + 1);
          },
        ),
      ],
    );
  }

  Future<void> _updateQuantity(
      Map<String, dynamic> item, int index, int newQuantity) async {
    try {
      // Update the quantity in Firestore
      final cartDocRef = FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart')
          .doc(item['id']);

      final newTotal = item['total'] / item['quantity'] * newQuantity;

      await cartDocRef.update({
        'quantity': newQuantity,
        'total': newTotal,
      });

      // Update the local state
      setState(() {
        cartItems[index]['quantity'] = newQuantity;
        cartItems[index]['total'] = newTotal;
      });
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Widget _buildAddOnsList(Map<String, dynamic> item) {
    // Add-ons fields to check
    final addOnFields = {
      'Bonito Flakes': item['bonitoFlakes'],
      'Coffee Jelly': item['coffeeJelly'],
      'Creampuff': item['creampuff'],
      'Mayonnaise': item['mayonnaise'],
      'Nata': item['nata'],
      'Oreo': item['oreo'],
      'Pearls': item['pearls'],
      'Takoyaki Sauce': item['takoyakiSauce'],
    };

    // Filter selected add-ons
    final selectedAddOns =
        addOnFields.entries.where((addOn) => addOn.value == true).toList();

    if (selectedAddOns.isEmpty) {
      return const SizedBox(); // No add-ons to display
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add-ons:',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        ...selectedAddOns.map((addOn) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('- ${addOn.key}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70)),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  _showRemoveConfirmationDialog(
                    addOnKey: addOn.key,
                    itemId: item['id'],
                  );
                },
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _showRemoveConfirmationDialog(
      {required String addOnKey, required String itemId}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Add-on'),
          content:
              Text('Are you sure you want to remove $addOnKey from this item?'),
          actions: [
            TextButton(
              onPressed: () {
                _removeAddOnFromFirestore(addOnKey: addOnKey, itemId: itemId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeAddOnFromFirestore({
    required String addOnKey,
    required String itemId,
  }) async {
    try {
      final firestoreFieldKey = addOnFieldMapping[addOnKey];

      if (firestoreFieldKey == null) {
        print('Error: No Firestore key found for add-on "$addOnKey"');
        return;
      }

      // Fetch the current total from Firestore before removing the add-on
      final cartDocRef = FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('cart')
          .doc(itemId);

      final cartDoc = await cartDocRef.get();
      if (cartDoc.exists) {
        double currentTotal = cartDoc['total'] ?? 0.0;

        // Subtract the price of the add-on from the total
        double addOnPrice = addOnPrices[addOnKey] ?? 0.0;
        double newTotal = currentTotal - addOnPrice;

        // Update the Firestore field to false (remove the add-on)
        await cartDocRef.update({firestoreFieldKey: false, 'total': newTotal});

        // Update the local state
        setState(() {
          final itemIndex =
              cartItems.indexWhere((item) => item['id'] == itemId);
          if (itemIndex != -1) {
            cartItems[itemIndex][firestoreFieldKey] =
                false; // Modify the field locally
            cartItems[itemIndex]['total'] = newTotal; // Update total locally
          }
        });

        print('Add-on "$addOnKey" removed successfully!');
      }
    } catch (e) {
      print('Error removing add-on "$addOnKey": $e');
    }
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildSelectedItemCard(String selectedItemName) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _fetchProductType(selectedItemName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorCard(selectedItemName);
        }

        final document = snapshot.data!;
        final productType = document['productType'] ?? 'Unknown';
        final extraInfo = productType == 'Milk Tea'
            ? 'Size: Regular'
            : productType == 'Takoyaki'
                ? 'Quantity: 4 pcs'
                : 'No extra info available';

        return _buildCardContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selectedItemName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(extraInfo,
                  style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Add-on Price: Free',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6E473B))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return _buildCardContent(const Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorCard(String selectedItemName) {
    return _buildCardContent(
      Text('Product type for "$selectedItemName" not found',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
    );
  }

  Widget _buildProductInfoCard(
      DocumentSnapshot snapshot, String selectedItemName) {
    final productType = snapshot['productType'] ?? 'Unknown';
    final extraInfo = productType == 'Milk Tea'
        ? 'Size: Regular'
        : (productType == 'Takoyaki' ? 'Quantity: 4 pc' : null);
    return _buildCardContent(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selectedItemName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (extraInfo != null) _buildInfoText(extraInfo, isBold: true),
          _buildInfoText('Total: Free',
              isBold: true, color: const Color(0xFF6E473B)),
        ],
      ),
    );
  }

  Widget _buildCardContent(Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF6E473B),
        child: SizedBox(
          width: double.infinity, // Ensures the card takes the full width
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text,
      {bool isBold = false, Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color),
      ),
    );
  }

  Widget _buildTotalAmount() {
    final totalAmount =
        cartItems.fold(0.0, (sum, item) => sum + (item['total'] ?? 0));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('₱${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6E473B))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  _proceedToCheckout(selectedItemName: selectedItemName ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color(0xFF6E473B), // Use the first color in the palette
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

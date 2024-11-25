// ignore_for_file: library_private_types_in_public_api, avoid_print, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/checkout.dart';

class MainCart extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String uid;
  final String email;
  final String imageUrl;
  final String userAddress;
  final double latitude;
  final double longitude;

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
  });

  @override
  _MainCartState createState() => _MainCartState();
}

class _MainCartState extends State<MainCart> {
  List<Map<String, dynamic>> cartItems = [];
  String? selectedItemName;

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
        title: const Text('My Cart'),
        backgroundColor: Colors.orangeAccent,
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
                      final selectedItemName = item['selectedItemName'];

                      return Column(
                        children: [
                          // Card for productName
                          Dismissible(
                            key: Key('${item['id']}-productName'),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              _deleteCartItem(item['id']);
                              setState(() {
                                cartItems.removeAt(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('$productName removed from cart')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0), // Margins around the card
                              child: SizedBox(
                                width: double
                                    .infinity, // Forces the card to take full width
                                child: Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0), // Spacing between cards
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Quantity: ${item['quantity']}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Size: ${item['sizeQuantity']}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Total: ₱${item['total'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Card for selectedItemName (if exists)
                          if (selectedItemName != null)
                            FutureBuilder<DocumentSnapshot?>(
                              future: _fetchProductType(
                                  selectedItemName), // Call the fetch method
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'Product type for "$selectedItemName" not found',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Extract product type and determine extra details
                                  final productType =
                                      snapshot.data!['productType'] ??
                                          'Unknown';
                                  final extraInfo = productType == 'Milk Tea'
                                      ? 'Size: Regular'
                                      : productType == 'Takoyaki'
                                          ? 'Quantity: 4 pc'
                                          : null;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Display the selected item name
                                              Text(
                                                selectedItemName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8.0),
                                              if (extraInfo != null) ...[
                                                const SizedBox(height: 8.0),
                                                Text(
                                                  extraInfo,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 8.0),
                                              // Add "Total: Free" text
                                              const Text(
                                                'Total: Free',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orangeAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Make the button stretch the entire width
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${cartItems.fold(0.0, (sum, item) => sum + (item['total'] ?? 0)).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _proceedToCheckout(
                        selectedItemName:
                            selectedItemName ?? ''), // Pass the argument here
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Checkout',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

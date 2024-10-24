import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainCart extends StatefulWidget {
  final String userName;
  final String email;

  const MainCart({Key? key, required this.userName, required this.email})
      : super(key: key);

  @override
  _MainCartState createState() => _MainCartState();
}

class _MainCartState extends State<MainCart> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    try {
      // Fetch the cart items for the current user using the passed userName
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer') // Ensure this is the correct collection name
          .doc(widget.userName) // Using the userName from the widget
          .collection('cart') // Cart subcollection
          .get();

      setState(() {
        cartItems = snapshot.docs.map((doc) {
          return {
            'productType': doc['productType'],
            'sizeQuantity': doc['sizeQuantity'],
            'quantity': doc['quantity'],
            'total': doc['total'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching cart items: $e');
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
          // Display the cart items
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        elevation: 4, // Shadow effect for card
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['productType'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Size/Quantity: ${item['sizeQuantity']} x ${item['quantity']}',
                                      style:
                                          const TextStyle(color: Colors.grey),
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey), // Divider for total section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₱${cartItems.fold(0.0, (sum, item) => sum + item['total']).toStringAsFixed(2)}', // Total of all items
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Space below the total
        ],
      ),
    );
  }
}

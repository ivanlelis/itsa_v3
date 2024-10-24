import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartPage extends StatelessWidget {
  final String userName; // Non-nullable
  final String email; // Non-nullable
  final String productName;
  final int quantity;
  final String size;
  final double price;
  final bool takoyakiSauce;
  final bool bonitoFlakes;
  final bool mayonnaise;
  final String productType;

  const CartPage({
    Key? key,
    required this.userName,
    required this.email,
    required this.productName,
    required this.quantity,
    required this.size,
    required this.price,
    required this.takoyakiSauce,
    required this.bonitoFlakes,
    required this.mayonnaise,
    required this.productType,
  }) : super(key: key);

  // Add item to cart function
  Future<void> addToCart({
    required String userName, // Non-nullable user name
    required String productName, // Non-nullable product name
    required String productType,
    required String sizeQuantity,
    required int quantity,
    required double total,
  }) async {
    try {
      // Reference to the user's cart collection
      CollectionReference cart = FirebaseFirestore.instance
          .collection('customer') // Ensure this is the correct collection name
          .doc(userName) // Use the user's name as the document ID
          .collection('cart');

      // Add the cart item with relevant details as a document named after the product
      await cart.doc(productName).set({
        // Using set to create a document with productName
        'productName': productName,
        'productType': productType,
        'sizeQuantity': sizeQuantity,
        'quantity': quantity,
        'total': total,
        'takoyakiSauce': takoyakiSauce,
        'bonitoFlakes': bonitoFlakes,
        'mayonnaise': mayonnaise,
      });
      print('Item added to cart successfully!'); // Debugging output
    } catch (e) {
      print('Error adding to cart: $e'); // Catch and log any errors
    }
  }

  // Function to handle adding to the cart
  Future<void> _addToCart() async {
    String sizeQuantity;
    if (productType == 'milktea') {
      sizeQuantity = size; // e.g., small, medium, large
    } else if (productType == 'takoyaki') {
      sizeQuantity = size; // e.g., 4pc, 8pc, 12pc
    } else {
      sizeQuantity = ''; // Meals don't have size/quantity specified
    }

    await addToCart(
      userName: userName, // Pass the user name to the function
      productName: productName, // Pass the product name to the function
      productType: productType,
      sizeQuantity: sizeQuantity,
      quantity: quantity,
      total: price,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Order',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text('Size/Quantity: $size x $quantity',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8.0),
                    if (takoyakiSauce)
                      const Text('Add-on: Takoyaki Sauce (₱15)'),
                    if (bonitoFlakes) const Text('Add-on: Bonito Flakes (₱15)'),
                    if (mayonnaise) const Text('Add-on: Mayonnaise (₱15)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16.0),
            Text(
              'Total: ₱${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 32.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _addToCart();
                  // Optionally, navigate to another screen
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to the product list or shopping page
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CartProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String? selectedItemName;

  const CartProductsSection({
    super.key,
    required this.cartItems,
    this.selectedItemName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Ensures full width for children
      children: [
        ...cartItems.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 2,
            child: ListTile(
              title: Text(item['productName']),
              subtitle: Text(
                  'Size/Quantity: ${item['sizeQuantity']} x ${item['quantity']}'),
              trailing: Text('₱${item['total'].toStringAsFixed(2)}'),
            ),
          );
        }), // Ensure `toList()` is called for safe mapping
        const SizedBox(
          height: 5,
        ),
        // Display Exclusive Bundle only if selectedItemName has a value
        if (selectedItemName != null && selectedItemName!.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 2,
            color: Colors.green, // Set the card's background color to green
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Exclusive Bundle: $selectedItemName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set the text color to white
                ),
              ),
            ),
          ),
      ],
    );
  }
}

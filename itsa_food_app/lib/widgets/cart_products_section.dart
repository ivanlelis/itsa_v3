import 'package:flutter/material.dart';

class CartProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartProductsSection({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartItems.map((item) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 4.0),
          elevation: 2,
          child: ListTile(
            title: Text(item['productName']),
            subtitle: Text(
                'Size/Quantity: ${item['sizeQuantity']} x ${item['quantity']}'),
            trailing: Text('₱${item['total'].toStringAsFixed(2)}'),
          ),
        );
      }).toList(),
    );
  }
}

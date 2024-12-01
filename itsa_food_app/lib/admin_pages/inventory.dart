import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_inventory.dart';
import 'package:itsa_food_app/widgets/admin_stock.dart'; // Import ProductsStock

class InventoryPage extends StatelessWidget {
  final String userName; // Add a userName parameter to the InventoryPage

  const InventoryPage({
    super.key,
    required this.userName, // Ensure that the userName is passed when navigating
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AdminInventory(
                userName: userName), // Pass userName to AdminInventory
            AdminStock(
                userName: userName), // Call ProductsStock below AdminInventory
          ],
        ),
      ),
    );
  }
}

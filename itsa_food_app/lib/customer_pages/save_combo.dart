import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaveCombo extends StatelessWidget {
  final String? selectedProductID;
  final String? selectedMilkTeaID;
  final String? branchID;

  // Constructor to receive the selectedItem and selectedMilkTeaID
  const SaveCombo(
      {Key? key, this.selectedProductID, this.selectedMilkTeaID, this.branchID})
      : super(key: key);

  // Fetch products based on branchID from Firestore
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    // Reference to the Firestore collection based on the branchID
    String collectionName = '';

    // Set collection name based on branchID
    if (branchID == "branch 1") {
      collectionName = "products";
    } else if (branchID == "branch 2") {
      collectionName = "products_branch1";
    } else if (branchID == "branch 3") {
      collectionName = "products_branch2";
    } else {
      throw Exception('Invalid branch ID');
    }

    // Fetch documents from the selected Firestore collection
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    // Return list of products from Firestore
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Save Combo"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Combo Details:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Selected Item: $selectedProductID",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Selected Milk Tea ID: $selectedMilkTeaID",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            // FutureBuilder to fetch products based on branchID from Firestore
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No products available for this branch.");
                } else {
                  final products = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Products:",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...products.map((product) {
                        return Text(
                          product['producName'] ?? 'Unknown product',
                          style: const TextStyle(fontSize: 18),
                        );
                      }).toList(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Handle saving the combo or any further logic here
                // For now, just pop back to the previous screen
                Navigator.pop(context);
              },
              child: const Text("Save Combo"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsa_food_app/admin_pages/view_user_ui.dart';

class ViewUser extends StatelessWidget {
  final String userName;

  const ViewUser({super.key, required this.userName});

  Future<Map<String, dynamic>?> getUserData(String userName) async {
    try {
      // Query Firestore to find the document with the matching userName
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer')
          .where('userName', isEqualTo: userName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Retrieve the first matching document
        DocumentSnapshot document = snapshot.docs.first;

        // Extract the data from the document
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;

        // Add the customerID (which is the document ID)
        data['customerID'] = document.id;

        // Fetch most ordered product and its order count
        Map<String, dynamic> mostOrderedProductData =
            await _getMostOrderedProduct(document.id); // Pass document ID
        data['mostOrderedProduct'] = mostOrderedProductData['productName'];
        data['productOrderCount'] = mostOrderedProductData['orderCount'];

        return data;
      } else {
        return null; // No matching document found
      }
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getMostOrderedProduct(String customerID) async {
    try {
      // Reference to the orders subcollection
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .doc(customerID)
          .collection('orders')
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        // Count total quantity for each productName
        Map<String, int> productQuantityMap = {};

        for (var doc in ordersSnapshot.docs) {
          // Extract the 'products' array
          List<dynamic> products = doc['products'] ?? [];
          for (var product in products) {
            String productName = product['productName'] ?? 'Unknown Product';
            int quantity = product['quantity'] ?? 0;

            // Add to the total count for this productName
            productQuantityMap[productName] =
                (productQuantityMap[productName] ?? 0) + quantity;
          }
        }

        // Find the product with the highest quantity
        var mostOrderedProduct = productQuantityMap.entries
            .reduce((a, b) => a.value > b.value ? a : b);

        return {
          'productName': mostOrderedProduct.key,
          'orderCount': mostOrderedProduct.value,
        };
      } else {
        return {'productName': 'No orders', 'orderCount': 0};
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return {'productName': 'Error', 'orderCount': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(userName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching user data.'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found.'));
          } else {
            // Pass the fetched data to the UI widget
            return UserDetailsUI(
              userName: userName,
              userData: snapshot.data!,
            );
          }
        },
      ),
    );
  }
}

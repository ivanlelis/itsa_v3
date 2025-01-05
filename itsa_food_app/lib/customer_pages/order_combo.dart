import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderCombo extends StatefulWidget {
  final String comboName;
  final String userName;

  const OrderCombo(
      {super.key, required this.comboName, required this.userName});

  @override
  _OrderComboState createState() => _OrderComboState();
}

class _OrderComboState extends State<OrderCombo> {
  String? productName1;
  String? productName2;
  String? branchID;
  String? imageUrl1;
  String? imageUrl2;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComboDetails();
    _fetchUserBranchID();
  }

  // Fetch combo details (product names)
  Future<void> _fetchComboDetails() async {
    try {
      final customersRef = FirebaseFirestore.instance.collection('customer');
      final querySnapshot = await customersRef.get();

      for (var customerDoc in querySnapshot.docs) {
        final combosRef = customerDoc.reference.collection('combos');
        final combosSnapshot = await combosRef
            .where('comboName', isEqualTo: widget.comboName)
            .get();

        if (combosSnapshot.docs.isNotEmpty) {
          final comboDoc = combosSnapshot.docs.first.data();
          setState(() {
            productName1 = comboDoc['productName1'];
            productName2 = comboDoc['productName2'];
            isLoading = false;
          });
          _fetchProductImages(); // Fetch product images after getting product names
          break;
        }
      }
    } catch (e) {
      print('Error fetching combo details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch the branchID for the current userName
  Future<void> _fetchUserBranchID() async {
    try {
      final customersRef = FirebaseFirestore.instance.collection('customer');
      final querySnapshot = await customersRef
          .where('userName', isEqualTo: widget.userName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first.data();
        setState(() {
          branchID =
              userDoc['branchID']; // Get the branchID from the user document
        });
      }
    } catch (e) {
      print('Error fetching user branchID: $e');
    }
  }

  // Fetch product images based on the branchID
  Future<void> _fetchProductImages() async {
    if (productName1 != null && productName2 != null && branchID != null) {
      try {
        String collectionName;
        // Determine which collection to query based on branchID
        if (branchID == 'branch 1') {
          collectionName = 'products';
        } else if (branchID == 'branch 2') {
          collectionName = 'products_branch1';
        } else if (branchID == 'branch 3') {
          collectionName = 'products_branch2';
        } else {
          return;
        }

        final productsRef =
            FirebaseFirestore.instance.collection(collectionName);

        // Fetch product 1 image
        final product1Doc = await productsRef
            .where('productName', isEqualTo: productName1)
            .limit(1)
            .get();

        if (product1Doc.docs.isNotEmpty) {
          final productData1 = product1Doc.docs.first.data();
          setState(() {
            imageUrl1 = productData1['imageUrl'];
          });
        }

        // Fetch product 2 image
        final product2Doc = await productsRef
            .where('productName', isEqualTo: productName2)
            .limit(1)
            .get();

        if (product2Doc.docs.isNotEmpty) {
          final productData2 = product2Doc.docs.first.data();
          setState(() {
            imageUrl2 = productData2['imageUrl'];
          });
        }
      } catch (e) {
        print('Error fetching product images: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Combo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.comboName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const CircularProgressIndicator()
            else if (productName1 != null && productName2 != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$productName1',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (imageUrl1 != null)
                    Image.network(imageUrl1!, height: 200, fit: BoxFit.cover),
                  Text(
                    '$productName2',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (imageUrl2 != null)
                    Image.network(imageUrl2!, height: 200, fit: BoxFit.cover),
                ],
              )
            else
              const Text(
                'No products found for this combo.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Process the order here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order placed successfully!')),
                );
              },
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/my_combos.dart';
import 'package:itsa_food_app/customer_pages/view_combo.dart';

class SearchCustom extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? imageUrl;
  final String? uid;
  final String? email;
  final String? userAddress;
  final double latitude;
  final double longitude;
  final String? branchID;

  const SearchCustom({
    super.key,
    this.userName,
    this.emailAddress,
    this.imageUrl,
    this.uid,
    this.email,
    this.userAddress,
    required this.latitude,
    required this.longitude,
    this.branchID,
  });

  @override
  State<SearchCustom> createState() => _SearchCustomState();
}

class _SearchCustomState extends State<SearchCustom> {
  String _searchQuery = "";
  List<String> comboNames = [];

  @override
  void initState() {
    super.initState();
    _fetchComboNames();
  }

  Future<void> _fetchComboNames() async {
    try {
      // Reference to the 'customers' collection
      final customersRef = FirebaseFirestore.instance.collection('customer');

      // Get all customer documents
      final customerDocs = await customersRef.get();

      // Loop through each customer document
      for (var customer in customerDocs.docs) {
        // Reference to the 'combos' subcollection for each customer
        final combosRef = customer.reference.collection('combos');

        // Query for combos where visibility == 'Public'
        final combosQuery =
            await combosRef.where('visibility', isEqualTo: 'Public').get();

        // Add the combo names to the list
        for (var combo in combosQuery.docs) {
          setState(() {
            comboNames.add(combo['comboName']);
          });
        }
      }
    } catch (e) {
      print("Error fetching combo names: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.brown),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Content goes here
                    Expanded(
                      child: _searchQuery.isEmpty
                          ? ListView.builder(
                              itemCount: comboNames.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  elevation: 4,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: ListTile(
                                      title: Text(
                                        comboNames[index],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          _onViewButtonPressed(
                                              comboNames[index]);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              children: [
                                Center(
                                  child: Text(
                                    'Search results for: $_searchQuery',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Positioned View My Combos button at the bottom left corner of the main card
            Positioned(
              bottom: 16,
              left: 16,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the MyCombos screen when the button is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyCombos(userName: widget.userName),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View My Combos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onViewButtonPressed(String comboName) async {
    try {
      // Fetch combo details from Firestore
      final customersRef = FirebaseFirestore.instance.collection('customer');

      // Iterate through all customer documents to find the combo
      for (var customer
          in await customersRef.get().then((value) => value.docs)) {
        final combosRef = customer.reference.collection('combos');
        final comboDoc = await combosRef
            .where('comboName', isEqualTo: comboName)
            .limit(1)
            .get();

        if (comboDoc.docs.isNotEmpty) {
          final comboData = comboDoc.docs.first.data();
          final description = comboData['description'] as String;

          // Get product names (productName1 and productName2)
          final productName1 = comboData['productName1'] as String;
          final productName2 = comboData['productName2'] as String;

          final tags = List<String>.from(comboData['tags'] as List<dynamic>);

          // Show combo details in the bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ViewCombo(
                  comboName: comboName,
                  description: description,
                  productName1: productName1, // Pass productName1
                  productName2: productName2, // Pass productName2
                  tags: tags, // Pass tags
                  branchID: widget.branchID ?? '',
                ),
              );
            },
          );

          return; // Exit the loop once the combo is found
        }
      }

      // Show a message if the combo was not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Combo "$comboName" not found.')),
      );
    } catch (e) {
      print("Error fetching combo details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch combo details.')),
      );
    }
  }
}

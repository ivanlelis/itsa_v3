import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyCombos extends StatefulWidget {
  final String? userName;

  const MyCombos({super.key, this.userName});

  @override
  State<MyCombos> createState() => _MyCombosState();
}

class _MyCombosState extends State<MyCombos> {
  List<String> privateComboNames = [];

  @override
  void initState() {
    super.initState();
    _fetchPrivateCombos();
  }

  Future<void> _fetchPrivateCombos() async {
    try {
      // Print the userName to the debug console
      print('Current userName: ${widget.userName}');

      // Reference to the 'customers' collection
      final customersRef = FirebaseFirestore.instance.collection('customer');

      // Query to find the customer document where userName matches the current user's userName
      final customerQuery = await customersRef
          .where('userName', isEqualTo: widget.userName)
          .get();

      // Check if the customer document exists
      if (customerQuery.docs.isEmpty) {
        print('No user found with the given userName.');
      } else {
        // Reference to the 'combos' subcollection for the matched customer
        final customerDoc = customerQuery.docs.first;
        final combosRef = customerDoc.reference.collection('combos');

        // Query for combos where visibility == 'Private'
        final combosQuery =
            await combosRef.where('visibility', isEqualTo: 'Private').get();

        // Add the private combo names to the list
        if (combosQuery.docs.isEmpty) {
          print('No private combos found for this user.');
        } else {
          setState(() {
            privateComboNames = combosQuery.docs.map((combo) {
              // Log the combo and its visibility for debugging
              print(
                  'Combo: ${combo['comboName']} - Visibility: ${combo['visibility']}');
              return combo['comboName'] as String;
            }).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching private combos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Combos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: privateComboNames.isEmpty
            ? const Center(child: Text('Loading...'))
            : ListView.builder(
                itemCount: privateComboNames.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        privateComboNames[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

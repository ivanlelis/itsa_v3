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
      final customersRef = FirebaseFirestore.instance.collection('customer');
      final customerDocs = await customersRef.get();
      final newComboNames = <String>[];

      for (var customer in customerDocs.docs) {
        final combosRef = customer.reference.collection('combos');
        final combosQuery =
            await combosRef.where('visibility', isEqualTo: 'Public').get();

        for (var combo in combosQuery.docs) {
          newComboNames.add(combo['comboName']);
        }
      }

      setState(() {
        comboNames = newComboNames;
      });
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Refresh button placed inside the card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search Combos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed:
                              _fetchComboNames, // Fetch latest combos when pressed
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    // Content
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchQuery.isEmpty
                            ? comboNames.length
                            : comboNames
                                .where((name) => name
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))
                                .length,
                        itemBuilder: (context, index) {
                          final filteredCombos = _searchQuery.isEmpty
                              ? comboNames
                              : comboNames
                                  .where((name) => name
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                                  .toList();
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                filteredCombos[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  _onViewButtonPressed(filteredCombos[index]);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Positioned View My Combos button
            Positioned(
              bottom: 16,
              left: 16,
              child: ElevatedButton(
                onPressed: () {
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

  Widget _buildComboCard(String comboName) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          comboName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () {
            _onViewButtonPressed(comboName);
          },
        ),
      ),
    );
  }

  void _onViewButtonPressed(String comboName) async {
    try {
      final customersRef = FirebaseFirestore.instance.collection('customer');

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
          final productName1 = comboData['productName1'] as String;
          final productName2 = comboData['productName2'] as String;
          final tags = List<String>.from(comboData['tags'] as List<dynamic>);

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
                  productName1: productName1,
                  productName2: productName2,
                  tags: tags,
                  branchID: widget.branchID ?? '',
                ),
              );
            },
          );

          return;
        }
      }

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

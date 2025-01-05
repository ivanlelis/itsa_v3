import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewCombo extends StatefulWidget {
  final String comboName;
  final String description;
  final String productName1;
  final String productName2;
  final List<String> tags;
  final String? branchID;

  const ViewCombo({
    super.key,
    required this.comboName,
    required this.description,
    required this.productName1,
    required this.productName2,
    required this.tags,
    this.branchID,
  });

  @override
  _ViewComboState createState() => _ViewComboState();
}

class _ViewComboState extends State<ViewCombo> {
  String? imageUrl1;
  String? imageUrl2;
  double _dragPosition = 0.0; // Tracks drag position

  @override
  void initState() {
    super.initState();
    _fetchProductImages();
  }

  Future<void> _fetchProductImages() async {
    try {
      // Determine which collection to query based on branchID
      String collectionName = '';
      if (widget.branchID == 'branch 1') {
        collectionName = 'products';
      } else if (widget.branchID == 'branch 2') {
        collectionName = 'products_branch1';
      } else if (widget.branchID == 'branch 3') {
        collectionName = 'products_branch2';
      }

      if (collectionName.isNotEmpty) {
        // Fetch the products based on productName1 and productName2
        final productsRef =
            FirebaseFirestore.instance.collection(collectionName);

        // Fetch product 1 details
        final product1Doc = await productsRef
            .where('productName', isEqualTo: widget.productName1)
            .limit(1)
            .get();

        if (product1Doc.docs.isNotEmpty) {
          final productData1 = product1Doc.docs.first.data();
          setState(() {
            imageUrl1 = productData1['imageUrl'];
          });
        }

        // Fetch product 2 details
        final product2Doc = await productsRef
            .where('productName', isEqualTo: widget.productName2)
            .limit(1)
            .get();

        if (product2Doc.docs.isNotEmpty) {
          final productData2 = product2Doc.docs.first.data();
          setState(() {
            imageUrl2 = productData2['imageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error fetching product images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          // Adjust position on drag
          _dragPosition += details.primaryDelta!;
        });
      },
      onVerticalDragEnd: (details) {
        // Close the modal if dragged down significantly
        if (_dragPosition > 100) {
          Navigator.pop(context); // Close modal if dragged down far enough
        } else {
          setState(() {
            _dragPosition = 0.0; // Reset position if not enough drag
          });
        }
      },
      child: Column(
        children: [
          // Non-scrollable part: Combo Name (title)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.comboName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          // Scrollable content: product cards, tags, description, etc.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Included Items Section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Included Items",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Product 1 Card
                  if (imageUrl1 != null) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        children: [
                          Image.network(imageUrl1!, fit: BoxFit.cover),
                          ListTile(
                            leading:
                                const Icon(Icons.check, color: Colors.green),
                            title: Text(widget.productName1),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                  ],
                  // Product 2 Card
                  if (imageUrl2 != null) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        children: [
                          Image.network(imageUrl2!, fit: BoxFit.cover),
                          ListTile(
                            leading:
                                const Icon(Icons.check, color: Colors.green),
                            title: Text(widget.productName2),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  // Tags Section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Tags",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: widget.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.brown[200],
                              ))
                          .toList(),
                    ),
                  ),
                  const Divider(),
                  // Description Section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      widget.description,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Large Order Now Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Add your order action here
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 60), // Large button
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Order Now",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white, // White text color
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Close Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 60), // Large button
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white, // White text color
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

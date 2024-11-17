import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsStock extends StatelessWidget {
  const ProductsStock({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('productType', whereIn: ['Milk Tea', 'Takoyaki']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No Milk Tea products available."));
        }

        return Card(
          margin: EdgeInsets.all(19.0),
          child: Column(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String productName = data['productName'] ?? 'Unnamed Product';
              List ingredients =
                  data['ingredients'] ?? []; // Get ingredients list

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 17.0),
                child: ListTile(
                  title: Text(productName),
                  trailing: IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: () {
                      // Show modal with ingredient details
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Ingredients for $productName'),
                            content: FutureBuilder(
                              future: _fetchIngredientStock(ingredients),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Text('No ingredients available');
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: snapshot.data!
                                      .map<Widget>((ingredientStock) {
                                    String ingredientName =
                                        ingredientStock['name'];
                                    String ingredientQuantity =
                                        ingredientStock['quantity'] ?? 'null';
                                    String stockStatus =
                                        ingredientStock['inStock']
                                            ? 'In Stock'
                                            : 'Out of Stock';
                                    return Text(
                                        '$ingredientName: $ingredientQuantity ($stockStatus)');
                                  }).toList(),
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Method to fetch ingredient stock status
  Future<List<Map<String, dynamic>>> _fetchIngredientStock(
      List ingredients) async {
    List<Map<String, dynamic>> ingredientStockList = [];

    for (var ingredient in ingredients) {
      String ingredientName = ingredient['name'];
      String ingredientQuantity = ingredient['quantity'] ?? 'null';

      var ingredientDoc = await FirebaseFirestore.instance
          .collection('rawStock')
          .where('matName',
              isEqualTo:
                  ingredientName) // Match ingredient name with matName in rawStock
          .limit(1)
          .get();

      if (ingredientDoc.docs.isNotEmpty) {
        var stockData = ingredientDoc.docs.first.data();
        ingredientStockList.add({
          'name': ingredientName,
          'quantity': ingredientQuantity,
          'inStock': stockData['quantity'] != null && stockData['quantity'] > 0
        });
      } else {
        ingredientStockList.add({
          'name': ingredientName,
          'quantity': ingredientQuantity,
          'inStock': false
        });
      }
    }

    return ingredientStockList;
  }
}

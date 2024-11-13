import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsStock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('productType', isEqualTo: 'Milk Tea')
          .snapshots(),
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

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 17.0),
                child: ListTile(
                  title: Text(productName),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RedeemedRewardsScreen extends StatefulWidget {
  const RedeemedRewardsScreen({super.key});

  @override
  _RedeemedRewardsScreenState createState() => _RedeemedRewardsScreenState();
}

class _RedeemedRewardsScreenState extends State<RedeemedRewardsScreen> {
  late Stream<QuerySnapshot> redeemedRewardsStream;

  @override
  void initState() {
    super.initState();
    // Fetch rewards from the "rewards" subcollection for the current user
    redeemedRewardsStream = FirebaseFirestore.instance
        .collection('customer')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('rewards') // Changed to "rewards" subcollection
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Redeemed Rewards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF6E473B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: redeemedRewardsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No redeemed rewards.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFA78D78),
                ),
              ),
            );
          }

          List<QueryDocumentSnapshot> redeemedRewards = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: redeemedRewards.map((reward) {
                // Get reward name and quantity
                var rewardName = reward['rewardName'];
                var quantity = reward['quantity'];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 40,
                    ),
                    title: Text(
                      rewardName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Quantity: $quantity',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

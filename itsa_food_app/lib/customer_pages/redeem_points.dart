import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'redeemed_rewards.dart'; // Import the RedeemedRewardsScreen

class RedeemPoints extends StatefulWidget {
  final String? emailAddress;
  final String? userName;
  final String? uid;
  final double latitude;
  final double longitude;

  const RedeemPoints({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.uid,
    required this.latitude,
    required this.longitude,
  });

  @override
  _RedeemPointsState createState() => _RedeemPointsState();
}

class _RedeemPointsState extends State<RedeemPoints> {
  int earnedPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchEarnedPoints();
  }

  Future<void> _fetchEarnedPoints() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('customer')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            earnedPoints = doc.data()?['points'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem Points'),
        backgroundColor: Color(0xFF6E473B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Earned Points:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),
              Text(
                '$earnedPoints',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              // Display UID below the earned points
              Text(
                'User UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'UID not available'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 20),
              Text(
                'Choose your reward:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              // Reward options
              _buildRewardOption('5% Discount', 30),
              _buildRewardOption('10% Discount', 50),
              _buildRewardOption('Free Delivery', 70),
              _buildRewardOption('10 PHP Off', 90),
              _buildRewardOption('Coming Soon!', 110, isComingSoon: true),
              _buildRewardOption('Coming Soon!', 130, isComingSoon: true),

              // Button to navigate to the Redeemed Rewards screen
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RedeemedRewardsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6E473B),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Redeemed Rewards',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardOption(String rewardText, int requiredPoints,
      {bool isComingSoon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isComingSoon
              ? null
              : () {
                  if (earnedPoints >= requiredPoints) {
                    _redeemReward(rewardText, requiredPoints);
                  } else {
                    _showInsufficientPointsMessage();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isComingSoon ? Colors.grey : Color(0xFF6E473B),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isComingSoon ? '$rewardText - Coming Soon!' : rewardText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isComingSoon ? Colors.white70 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _redeemReward(String rewardText, int requiredPoints) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef =
            FirebaseFirestore.instance.collection('customer').doc(user.uid);

        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          final currentPoints = doc.data()?['points'] ?? 0;

          if (currentPoints >= requiredPoints) {
            // Update user points
            await docRef.update({'points': currentPoints - requiredPoints});
            setState(() {
              earnedPoints = currentPoints - requiredPoints;
            });

            // Add or update the reward in the "rewards" subcollection
            await _updateRewardInSubcollection(user.uid, rewardText);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully redeemed $rewardText!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error redeeming reward: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error redeeming reward. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateRewardInSubcollection(
      String uid, String rewardText) async {
    try {
      // Reference to the rewards subcollection
      final rewardsRef = FirebaseFirestore.instance
          .collection('customer')
          .doc(uid)
          .collection('rewards')
          .doc(rewardText);

      // Get the current document if it exists
      final doc = await rewardsRef.get();

      if (doc.exists) {
        // If the document exists, update the quantity
        await rewardsRef.update({'quantity': FieldValue.increment(1)});
      } else {
        // If the document does not exist, create it with quantity = 1
        await rewardsRef.set({
          'rewardName': rewardText,
          'quantity': 1,
        });
      }
    } catch (e) {
      print('Error updating reward subcollection: $e');
    }
  }

  void _showInsufficientPointsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You do not have enough points for this reward.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

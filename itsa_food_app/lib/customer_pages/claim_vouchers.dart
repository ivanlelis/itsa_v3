import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimVouchers extends StatefulWidget {
  final String emailAddress;
  final String userName;
  final String uid;
  final double latitude;
  final double longitude;

  const ClaimVouchers({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.uid,
    required this.latitude,
    required this.longitude,
  });

  @override
  _ClaimVouchersState createState() => _ClaimVouchersState();
}

class _ClaimVouchersState extends State<ClaimVouchers> {
  late Stream<QuerySnapshot> availableVouchersStream;
  late Stream<QuerySnapshot> claimedVouchersStream;

  @override
  void initState() {
    super.initState();
    // Fetch available vouchers stream
    availableVouchersStream =
        FirebaseFirestore.instance.collection('voucher').snapshots();
    // Fetch claimed vouchers stream for the current user
    claimedVouchersStream = FirebaseFirestore.instance
        .collection('customer')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('claimedVouchers')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claim Vouchers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${widget.userName}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Email: ${widget.emailAddress}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // Available Vouchers Section with ExpansionTile
            StreamBuilder<QuerySnapshot>(
              stream: availableVouchersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No vouchers available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                List<QueryDocumentSnapshot> availableVouchers =
                    snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExpansionTile(
                    title: Text(
                      'Available Vouchers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                    children: [
                      Column(
                        children: availableVouchers.map((voucher) {
                          var voucherCode = voucher['voucherCode'];
                          var discountAmt = voucher['discountAmt'];
                          var discountType = voucher['discountType'];
                          var expDate = voucher['expDate'].toDate();

                          String discountSymbol =
                              discountType == "Percentage" ? "%" : "₱";
                          String formattedDiscount =
                              discountType == "Percentage"
                                  ? '$discountAmt$discountSymbol'
                                  : '$discountSymbol$discountAmt';

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(
                                Icons.local_offer,
                                color: Colors.deepOrangeAccent,
                                size: 40,
                              ),
                              title: Text(
                                voucherCode,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrangeAccent,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Discount: $formattedDiscount',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Expires on: ${expDate.day}-${expDate.month}-${expDate.year}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _claimVoucher(voucherCode, {
                                    'voucherCode': voucherCode,
                                    'discountAmt': discountAmt,
                                    'discountType': discountType,
                                    'expDate': voucher['expDate'],
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrangeAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Claim',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Claimed Vouchers Section with ExpansionTile
            StreamBuilder<QuerySnapshot>(
              stream: claimedVouchersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No claimed vouchers yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                List<QueryDocumentSnapshot> claimedVouchers =
                    snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExpansionTile(
                    title: Text(
                      'Claimed Vouchers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                    children: [
                      Column(
                        children: claimedVouchers.map((voucher) {
                          var voucherCode = voucher['voucherCode'];
                          var discountAmt = voucher['discountAmt'];
                          var discountType = voucher['discountType'];
                          var expDate = voucher['expDate'].toDate();

                          String discountSymbol =
                              discountType == "Percentage" ? "%" : "₱";
                          String formattedDiscount =
                              discountType == "Percentage"
                                  ? '$discountAmt$discountSymbol'
                                  : '$discountSymbol$discountAmt';

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 40,
                              ),
                              title: Text(
                                voucherCode,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Discount: $formattedDiscount',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Expires on: ${expDate.day}-${expDate.month}-${expDate.year}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Claim the voucher and update state
  void _claimVoucher(
      String voucherCode, Map<String, dynamic> voucherData) async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;

    // Reference to the voucher document
    DocumentReference voucherRef =
        FirebaseFirestore.instance.collection('voucher').doc(voucherCode);

    // Run Firestore transaction
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot voucherSnapshot = await transaction.get(voucherRef);

      if (!voucherSnapshot.exists) {
        // Voucher does not exist (it may have already been deleted if usageLimit reached zero)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voucher no longer available.')),
        );
        return;
      }

      int usageLimit = voucherSnapshot['usageLimit'] ?? 0;

      if (usageLimit > 0) {
        // Reduce usageLimit by 1
        usageLimit--;

        if (usageLimit == 0) {
          // Delete voucher if usageLimit has reached zero
          transaction.delete(voucherRef);
        } else {
          // Update the usageLimit field if it's greater than zero
          transaction.update(voucherRef, {'usageLimit': usageLimit});
        }

        // Save claimed voucher in user's claimedVouchers subcollection
        DocumentReference claimedVoucherRef = FirebaseFirestore.instance
            .collection('customer')
            .doc(userUid)
            .collection('claimedVouchers')
            .doc(voucherCode);
        transaction.set(claimedVoucherRef, voucherData);

        // Update UI after claiming
        setState(() {});
      } else {
        // Voucher usage limit reached
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voucher usage limit reached.')),
        );
      }
    });
  }
}

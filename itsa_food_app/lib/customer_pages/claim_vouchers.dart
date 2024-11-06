import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claim Vouchers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('voucher').snapshots(),
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

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var voucher = snapshot.data!.docs[index];
              var voucherCode = voucher['voucherCode'];
              var discountAmt = voucher['discountAmt'];
              var discountType = voucher['discountType'];
              var expDate = voucher['expDate'].toDate();

              // Determine the discount symbol
              String discountSymbol = discountType == "Percentage" ? "%" : "₱";
              String formattedDiscount = discountType == "Percentage"
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
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Expires on: ${expDate.day}-${expDate.month}-${expDate.year}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Implement claim voucher functionality here
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
            },
          );
        },
      ),
    );
  }
}

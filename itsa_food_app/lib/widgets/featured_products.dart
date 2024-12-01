import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/customer_pages/order_featured.dart';

class FeaturedProductWidget extends StatelessWidget {
  final Future<DocumentSnapshot> featuredProduct;
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;
  final String branchID;

  const FeaturedProductWidget({
    super.key,
    required this.featuredProduct,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.imageUrl,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
    required this.branchID,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: featuredProduct,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('');
        }

        // Extract featured product data
        var featuredData = snapshot.data!.data() as Map<String, dynamic>;
        var productName = featuredData['productName'] ?? 'No name';
        var startDate = (featuredData['startDate'] as Timestamp)
            .toDate()
            .add(Duration(hours: 8)); // Adjust to Philippine Time
        var endDate = (featuredData['endDate'] as Timestamp)
            .toDate()
            .add(Duration(hours: 8)); // Adjust to Philippine Time

        var today = DateTime.now();

        // Logic to determine visibility
        bool isFeaturedVisible =
            today.isAfter(startDate) && today.isBefore(endDate);

        if (!isFeaturedVisible) {
          return SizedBox.shrink(); // Hide the entire section
        }

        // If visible, return the UI
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Featured Product" text
                Text(
                  'Featured Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // "View full menu" button
                TextButton(
                  onPressed: () {
                    // Navigate to the menu screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Menu(
                          userName: userName,
                          emailAddress: emailAddress,
                          email: email,
                          imageUrl: imageUrl,
                          uid: uid,
                          userAddress: userAddress,
                          latitude: latitude,
                          longitude: longitude,
                          branchID: branchID,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View full menu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6E473B), // Updated color
                    ),
                  ),
                ),
              ],
            ),
            // Product Card Section
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .where('productName', isEqualTo: productName)
                  .get(),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (productSnapshot.hasError) {
                  return Text('Error: ${productSnapshot.error}');
                }
                if (!productSnapshot.hasData ||
                    productSnapshot.data!.docs.isEmpty) {
                  return Text(
                      'No matching product found in products collection');
                }

                // Extract product data
                var productDoc = productSnapshot.data!.docs.first;
                var productData = productDoc.data() as Map<String, dynamic>;
                var imageUrl = productData['imageUrl'] ?? '';
                var priceField = productData['price'] ??
                    productData['4pc'] ??
                    productData['regular'] ??
                    '';
                var exBundle = featuredData['exBundle'] ?? 'No bundle';

                var dateFormatter = DateFormat('MMMM dd, yyyy, hh:mm a');
                var startDateFormatted = dateFormatter.format(startDate);
                var endDateFormatted = dateFormatter.format(endDate);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  productName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (priceField.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Starts with ₱$priceField',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Divider(color: Colors.grey[300]),
                            SizedBox(height: 4),
                            // Start Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Color(0xFF6E473B)),
                                SizedBox(width: 6),
                                Text(
                                  'Start Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  startDateFormatted,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
// End Date
                            Row(
                              children: [
                                Icon(Icons.event, color: Color(0xFF6E473B)),
                                SizedBox(width: 6),
                                Text(
                                  'End Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  endDateFormatted,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),

                            Divider(color: Colors.grey[300]),
                            // "Order Now" Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderFeatured(
                                        userName: userName,
                                        emailAddress: emailAddress,
                                        email: email,
                                        imageUrl: imageUrl,
                                        uid: uid,
                                        userAddress: userAddress,
                                        latitude: latitude,
                                        longitude: longitude,
                                        productName: productName,
                                        startDate: startDate,
                                        endDate: endDate,
                                        exBundle: exBundle,
                                        branchID: branchID,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(
                                      0xFFA78D78), // Updated color #6E473B
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  'Order Now',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

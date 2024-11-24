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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Featured Products text on the left
            Text(
              'Featured Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // View full menu button on the right
            TextButton(
              onPressed: () {
                // Navigate to MenuPage and pass the required arguments
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Menu(
                      userName: userName, // Pass the parameters
                      emailAddress: emailAddress,
                      email: email,
                      imageUrl: imageUrl,
                      uid: uid,
                      userAddress: userAddress,
                      latitude: latitude,
                      longitude: longitude,
                    ),
                  ),
                );
              },
              child: Text(
                'View full menu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
        // Reduced padding and margin between the text and the product card
        FutureBuilder<DocumentSnapshot>(
          future: featuredProduct,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('No featured product available');
            }

            var featuredData = snapshot.data!.data() as Map<String, dynamic>;
            var productName = featuredData['productName'] ?? 'No name';
            var startDate = (featuredData['startDate'] as Timestamp)
                .toDate()
                .add(Duration(hours: 8));
            var endDate = (featuredData['endDate'] as Timestamp)
                .toDate()
                .add(Duration(hours: 8));
            var exBundle = featuredData['exBundle'] ?? 'No bundle';

            var dateFormatter = DateFormat('MMMM dd, yyyy, hh:mm a');
            var startDateFormatted = dateFormatter.format(startDate);
            var endDateFormatted = dateFormatter.format(endDate);

            return FutureBuilder<QuerySnapshot>(
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

                var productDoc = productSnapshot.data!.docs.first;
                var productData = productDoc.data() as Map<String, dynamic>;
                var imageUrl = productData['imageUrl'] ?? '';

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(
                      vertical: 4), // Reduced vertical margin
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
                            height:
                                200, // Increased height to make the image larger
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4), // Reduced space
                            // Product Name with stylized font
                            Text(
                              productName,
                              style: TextStyle(
                                fontSize: 20, // Reduced font size
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Divider(color: Colors.grey[300]),
                            SizedBox(height: 4), // Reduced space
                            // Start Date and End Date with Icons and Stylish Text
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.orangeAccent),
                                SizedBox(width: 6), // Reduced space
                                Text(
                                  'Start Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14, // Reduced font size
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
                            SizedBox(height: 2), // Reduced space
                            Row(
                              children: [
                                Icon(Icons.event, color: Colors.orangeAccent),
                                SizedBox(width: 6), // Reduced space
                                Text(
                                  'End Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14, // Reduced font size
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
                            SizedBox(height: 4), // Reduced space
                            // Exclusive Bundle with Icon and Accent Text
                            Row(
                              children: [
                                Icon(Icons.local_offer,
                                    color: Colors.greenAccent),
                                SizedBox(width: 6), // Reduced space
                                Text(
                                  'Exclusive Bundle:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14, // Reduced font size
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  exBundle,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                            Divider(color: Colors.grey[300]),
                            SizedBox(height: 4), // Reduced space
                            // Order Now Button with Style
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to OrderFeatured and pass the required parameters
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
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8), // Reduced padding
                                ),
                                child: Text(
                                  'Order Now',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced font size
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
            );
          },
        ),
      ],
    );
  }
}

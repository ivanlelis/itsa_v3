// trend_product.dart (Updated)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_trending.dart'; // Import the OrderTrending widget

class TrendProduct extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;

  const TrendProduct({
    super.key,
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
  _TrendProductState createState() => _TrendProductState();
}

class _TrendProductState extends State<TrendProduct> {
  Map<String, int> productCount = {};
  String? mostOrderedProduct;
  String? productImageUrl;
  String? productType;
  String? productDetail;
  String? featuredProductName;

  @override
  void initState() {
    super.initState();
    fetchMostOrderedProduct();
    fetchFeaturedProductName();
  }

  Future<void> fetchMostOrderedProduct() async {
    productCount.clear();

    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime tomorrowStart = todayStart.add(Duration(days: 1));

    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    for (var customerDoc in customerSnapshot.docs) {
      QuerySnapshot orderSnapshot =
          await customerDoc.reference.collection('orders').get();

      for (var orderDoc in orderSnapshot.docs) {
        Timestamp? timestamp = orderDoc['timestamp'];
        if (timestamp != null) {
          DateTime orderDate = timestamp.toDate();
          if (orderDate.isAfter(todayStart) &&
              orderDate.isBefore(tomorrowStart)) {
            List<dynamic> products = orderDoc['productNames'] ?? [];
            for (var product in products) {
              productCount[product] = (productCount[product] ?? 0) + 1;
            }
          }
        }
      }
    }

    String? mostOrdered;
    int maxCount = 0;
    productCount.forEach((product, count) {
      if (count > maxCount) {
        mostOrdered = product;
        maxCount = count;
      }
    });

    setState(() {
      mostOrderedProduct = mostOrdered;
    });

    if (mostOrdered != null) {
      await fetchProductDetails(mostOrdered!);
    }
  }

  Future<void> fetchProductDetails(String productName) async {
    QuerySnapshot productSnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    for (var productDoc in productSnapshot.docs) {
      if (productDoc['productName'] == productName) {
        setState(() {
          productImageUrl = productDoc['imageUrl'];
          productType = productDoc['productType'];
          if (productType == 'Milk Tea') {
            productDetail = productDoc['regular'];
          } else if (productType == 'Takoyaki') {
            productDetail = productDoc['4pc'];
          } else {
            productDetail = '';
          }
        });
        break;
      }
    }
  }

  Future<void> fetchFeaturedProductName() async {
    DocumentSnapshot featuredDoc = await FirebaseFirestore.instance
        .collection('featured')
        .doc('featured')
        .get();

    if (featuredDoc.exists) {
      setState(() {
        featuredProductName = featuredDoc['productName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Today!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF6E473B), // Updated color
                ),
                child: Text(
                  'View full menu',
                  style: TextStyle(fontSize: 15), // Set font size to 15
                ),
              ),
            ],
          ),
          Card(
            elevation: 4,
            margin: EdgeInsets.only(top: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (productImageUrl == null)
                      Center(child: CircularProgressIndicator())
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          productImageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mostOrderedProduct ?? '',
                                style: TextStyle(
                                  fontSize: (mostOrderedProduct ?? '')
                                              .split(' ')
                                              .length >=
                                          3
                                      ? 13
                                      : 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 10),
                              if (productDetail != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Starts at ₱$productDetail',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 5,
                  left: 272,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to OrderTrending and pass parameters
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrending(
                            userName: widget.userName,
                            emailAddress: widget.emailAddress,
                            email: widget.email,
                            imageUrl: widget.imageUrl,
                            uid: widget.uid,
                            userAddress: widget.userAddress,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            productName: mostOrderedProduct!,
                            productImageUrl: productImageUrl,
                            productType: productType,
                            productDetail: productDetail,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFFA78D78), // Updated background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  }
}

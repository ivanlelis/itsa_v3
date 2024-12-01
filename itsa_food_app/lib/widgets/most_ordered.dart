import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:itsa_food_app/widgets/feature_product.dart';

class MostOrderedCard extends StatefulWidget {
  final String userName;

  const MostOrderedCard({super.key, required this.userName});

  @override
  _MostOrderedCardState createState() => _MostOrderedCardState();
}

class _MostOrderedCardState extends State<MostOrderedCard> {
  String selectedFilter = 'Today'; // Default filter
  Map<String, int> productCount = {};
  String? mostOrderedProduct;
  String? mostOrderedProductImageUrl;

  String generateRandomText(String timeFrame, String mostOrderedProduct) {
    List<String> timeReferences = [
      "today",
      "this week",
      "in the last $timeFrame",
      "over the past $timeFrame",
      "during the past $timeFrame",
    ];

    List<String> actions = [
      "garnered the most orders",
      "was the most popular choice",
      "kept customers coming back",
      "topped the orders chart",
      "emerged as the favorite",
    ];

    String timeReference = timeFrame == 'Today'
        ? 'today'
        : timeReferences[Random().nextInt(timeReferences.length)];

    String action = actions[Random().nextInt(actions.length)];

    return "$mostOrderedProduct $action $timeReference!";
  }

  Future<void> fetchMostOrderedProduct() async {
    setState(() {
      mostOrderedProduct = null;
      mostOrderedProductImageUrl = null;
    });

    productCount.clear();

    // Get current date in UTC and adjust to Philippine Time (UTC+8)
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 8));

    // Define the start and end date based on the selected filter
    DateTime startDate;
    DateTime endDate;

    if (selectedFilter == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (selectedFilter == '3 days') {
      startDate = now.subtract(const Duration(days: 3));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = now.subtract(const Duration(days: 1));
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else if (selectedFilter == '1 week') {
      startDate = now.subtract(const Duration(days: 7));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = now.subtract(const Duration(days: 1));
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    try {
      // Determine branchID based on userName
      String? branchID;

      if (widget.userName == "Main Branch Admin") {
        branchID = "branch 1";
      } else if (widget.userName == "Sta. Cruz II Admin") {
        branchID = "branch 2";
      } else if (widget.userName == "San Dionisio Admin") {
        branchID = "branch 3";
      }

      if (branchID == null) {
        setState(() {
          mostOrderedProduct = 'User does not have access to any branch.';
          mostOrderedProductImageUrl = null;
        });
        return;
      }

      // Fetch all customer documents
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      // Fetch orders for all customers, filtered by branchID
      List<Future<QuerySnapshot>> orderFutures = customerSnapshot.docs.map(
        (customerDoc) {
          return customerDoc.reference
              .collection('orders')
              .where('branchID', isEqualTo: branchID)
              .get();
        },
      ).toList();

      List<QuerySnapshot> orderSnapshots = await Future.wait(orderFutures);

      // Process all orders
      for (var orderSnapshot in orderSnapshots) {
        for (var orderDoc in orderSnapshot.docs) {
          Timestamp orderTimestamp = orderDoc['timestamp'];
          DateTime orderDate =
              orderTimestamp.toDate().toUtc().add(const Duration(hours: 8));
          orderDate = DateTime(orderDate.year, orderDate.month, orderDate.day);

          if (orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              orderDate.isBefore(endDate.add(const Duration(days: 1)))) {
            List<dynamic> products = orderDoc['products'] ?? [];
            for (var product in products) {
              String productName = product['productName'];
              int quantity = product['quantity'] ?? 1;

              productCount[productName] =
                  (productCount[productName] ?? 0) + quantity;
            }
          }
        }
      }

      // Find the most ordered product
      String? mostOrdered;
      int maxCount = 0;
      productCount.forEach((product, count) {
        if (count > maxCount) {
          mostOrdered = product;
          maxCount = count;
        }
      });

      if (mostOrdered != null) {
        QuerySnapshot productsSnapshot =
            await FirebaseFirestore.instance.collection('products').get();

        for (var productDoc in productsSnapshot.docs) {
          final productData = productDoc.data() as Map<String, dynamic>?;

          if (productData != null &&
              productData['productName'] == mostOrdered) {
            mostOrderedProductImageUrl = productData['imageUrl'];
            break;
          }
        }
      }

      setState(() {
        mostOrderedProduct = mostOrdered;
      });

      debugPrint('Most Ordered Product: $mostOrdered');
    } catch (e) {
      setState(() {
        mostOrderedProduct = 'Error fetching data';
        mostOrderedProductImageUrl = null;
      });
      debugPrint('Error fetching most ordered product: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    selectedFilter = 'Today';
    fetchMostOrderedProduct();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's getting ordered the most?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: FilterButton(
                    label: 'Today',
                    isSelected: selectedFilter == 'Today',
                    onTap: () {
                      setState(() {
                        selectedFilter = 'Today';
                        fetchMostOrderedProduct();
                      });
                    },
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FilterButton(
                    label: '3 days',
                    isSelected: selectedFilter == '3 days',
                    onTap: () {
                      setState(() {
                        selectedFilter = '3 days';
                        fetchMostOrderedProduct();
                      });
                    },
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FilterButton(
                    label: '1 week',
                    isSelected: selectedFilter == '1 week',
                    onTap: () {
                      setState(() {
                        selectedFilter = '1 week';
                        fetchMostOrderedProduct();
                      });
                    },
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mostOrderedProduct == null)
              Center(
                child: Text(
                  "No most ordered product yet.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              )
            else if (mostOrderedProduct != null)
              Row(
                children: [
                  if (mostOrderedProductImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mostOrderedProductImageUrl!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image_not_supported, size: 120),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mostOrderedProduct ?? '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          generateRandomText(
                              selectedFilter, mostOrderedProduct!),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FeatureProduct(userName: widget.userName),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 12.0), // Smaller padding
                  backgroundColor: Colors.brown, // Button color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Feature a Product',
                  style: TextStyle(fontSize: 12), // Smaller font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  const FilterButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 14, // Default font size if not provided
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.brown : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 26.5), // Optional: Adjust padding if needed
      ),
      child: Text(
        label,
        maxLines: 1, // Ensure text stays on one line
        overflow:
            TextOverflow.ellipsis, // Truncate text with "..." if it overflows
        style: TextStyle(
          fontSize: fontSize, // Font size set dynamically
        ),
      ),
    );
  }
}

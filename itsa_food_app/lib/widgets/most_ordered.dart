import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:itsa_food_app/widgets/feature_product.dart';

class MostOrderedCard extends StatefulWidget {
  const MostOrderedCard({super.key});

  @override
  _MostOrderedCardState createState() => _MostOrderedCardState();
}

class _MostOrderedCardState extends State<MostOrderedCard> {
  String selectedFilter = 'Today'; // Default filter
  Map<String, int> productCount = {};
  String? mostOrderedProduct;
  String? mostOrderedProductImageUrl;

  String generateRandomText(String timeFrame, String mostOrderedProduct) {
    // Possible time references
    List<String> timeReferences = [
      "today",
      "this week",
      "in the last $timeFrame",
      "over the past $timeFrame",
      "during the past $timeFrame",
    ];

    // Possible actions
    List<String> actions = [
      "garnered the most orders",
      "was the most popular choice",
      "kept customers coming back",
      "topped the orders chart",
      "emerged as the favorite",
    ];

    // Use the actual most ordered product in place of generic terms
    List<String> subjects = [
      mostOrderedProduct, // No "this" prefix anymore
    ];

    // Ensure we don't use "in the past today" or "this week" awkwardly
    String timeReference = timeFrame == 'Today'
        ? 'today' // Special handling for "Today"
        : timeReferences[Random().nextInt(timeReferences.length)];

    // Choose a random action
    String action = actions[Random().nextInt(actions.length)];

    // We only have one subject: mostOrderedProduct
    String subject = subjects[0];

    // Combine them into a complete sentence
    return "$subject $action $timeReference!";
  }

  Future<void> fetchMostOrderedProduct() async {
    setState(() {
      mostOrderedProduct = null; // Show fetching state
      mostOrderedProductImageUrl = null;
    });

    productCount.clear();

    // Get current date in Philippine Time (UTC+8)
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 8));

    // Define the start and end time based on the selected filter
    DateTime startTime;
    DateTime endTime;

    if (selectedFilter == 'Today') {
      // Set to the start of the current day in Philippine Time (midnight)
      startTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
      endTime =
          DateTime(now.year, now.month, now.day, 23, 59, 59); // End of today
    } else if (selectedFilter == '3 days') {
      // Set to 3 days ago, at the same time of day
      startTime = now.subtract(const Duration(days: 3));
      startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0,
          0); // Midnight of that day
      endTime = now.subtract(
          const Duration(days: 2)); // End time is the day before yesterday
      endTime = DateTime(endTime.year, endTime.month, endTime.day, 23, 59,
          59); // End of that day
    } else if (selectedFilter == '1 week') {
      // Set to 1 week ago, at the same time of day
      startTime = now.subtract(const Duration(days: 7));
      startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0,
          0); // Midnight of that day
      endTime = now.subtract(const Duration(days: 1)); // End time is 1 day ago
      endTime = DateTime(endTime.year, endTime.month, endTime.day, 23, 59,
          59); // End of that day
    } else {
      // Fallback to 'Today' if no filter is selected
      startTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
      endTime =
          DateTime(now.year, now.month, now.day, 23, 59, 59); // End of today
    }

    try {
      // Fetch all customers
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      // Fetch all orders for all customers concurrently, applying both start and end times
      List<Future<QuerySnapshot>> orderFutures = customerSnapshot.docs.map(
        (customerDoc) {
          return customerDoc.reference
              .collection('orders')
              .where('timestamp', isGreaterThanOrEqualTo: startTime)
              .where('timestamp',
                  isLessThanOrEqualTo: endTime) // End time filter
              .get();
        },
      ).toList();

      List<QuerySnapshot> orderSnapshots = await Future.wait(orderFutures);

      // Process all orders
      for (var orderSnapshot in orderSnapshots) {
        for (var orderDoc in orderSnapshot.docs) {
          List<dynamic> products = orderDoc['productNames'] ?? [];
          for (var product in products) {
            productCount[product] = (productCount[product] ?? 0) + 1;
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
        // Search for the most ordered product in the "products" collection
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
                fontSize: 20, // Increased font size for the header
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Use Row with Flexible widgets to make the buttons smaller and responsive
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
                const SizedBox(width: 16), // Space between buttons
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
                    fontSize: 11, // Reduced font size for "3 days"
                  ),
                ),
                const SizedBox(width: 16), // Space between buttons
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
                    fontSize: 10, // Reduced font size for "1 week"
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mostOrderedProduct == null && selectedFilter == 'Today')
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
                        height: 120, // Increased image height
                        width: 120, // Increased image width
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
                            fontSize:
                                20, // Increased font size for most ordered product
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mostOrderedProduct != null
                              ? generateRandomText(
                                  selectedFilter, mostOrderedProduct!)
                              : '',
                          style: TextStyle(
                            fontSize: 16, // Increased font size for random text
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FeatureProduct()),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FrequentOrdersByTagsChart extends StatefulWidget {
  final String userName;

  const FrequentOrdersByTagsChart({super.key, required this.userName});

  @override
  _FrequentOrdersByTagsChartState createState() =>
      _FrequentOrdersByTagsChartState();
}

class _FrequentOrdersByTagsChartState extends State<FrequentOrdersByTagsChart> {
  Map<String, int> tagCounts = {};
  bool isLoading = true; // Flag to track loading state
  int selectedTimeRange = 0; // 0: Today, 1: 3 days, 2: 1 week

  @override
  void initState() {
    super.initState();
    fetchTagData(); // Initial fetch when the widget is first created
  }

  // Function to fetch orders based on the selected time range
  Future<void> fetchTagData() async {
    setState(() {
      tagCounts.clear(); // Reset tag counts
      isLoading = true; // Set loading to true while data is being fetched
    });

    Map<String, int> tempTagCounts = {};

    try {
      // Fetch all customer documents in parallel
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      String branchID;
      if (widget.userName == "Main Branch Admin") {
        branchID = "branch 1";
      } else if (widget.userName == "Sta. Cruz II Admin") {
        branchID = "branch 2";
      } else if (widget.userName == "San Dionisio Admin") {
        branchID = "branch 3";
      } else {
        branchID = ""; // Default or invalid branchID if needed
      }

      // Fetch orders for all customers in parallel
      List<Future> orderFetches = [];
      for (var customerDoc in customerSnapshot.docs) {
        orderFetches
            .add(fetchOrdersForCustomer(customerDoc, tempTagCounts, branchID));
      }

      // Wait for all order fetches to complete
      await Future.wait(orderFetches);

      // Update state with the computed tag counts
      setState(() {
        tagCounts = tempTagCounts;
        isLoading = false; // Set loading to false when data is fetched
      });
    } catch (e) {
      print('Error fetching tag data: $e');
      setState(() {
        isLoading = false; // Stop loading in case of error
      });
    }
  }

  // Function to fetch orders for a specific customer and process them
  Future<void> fetchOrdersForCustomer(DocumentSnapshot customerDoc,
      Map<String, int> tempTagCounts, String branchID) async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate;

      // Set start date based on selected time range
      if (selectedTimeRange == 0) {
        startDate = DateTime(now.year, now.month, now.day); // Today
      } else if (selectedTimeRange == 1) {
        startDate = now.subtract(Duration(days: 3)); // Last 3 days
      } else {
        startDate = now.subtract(Duration(days: 7)); // Last 7 days
      }

      // Fetch each customer's orders, filtered by timestamp and branchID
      QuerySnapshot orderSnapshot = await customerDoc.reference
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('branchID', isEqualTo: branchID) // Filter by branchID
          .get();

      for (var orderDoc in orderSnapshot.docs) {
        List<dynamic> products = orderDoc['products'] ?? [];
        for (var product in products) {
          if (product['productName'] != null && product['quantity'] != null) {
            String productName = product['productName'];
            int quantity = product['quantity'];

            // Fetch tags for each product
            try {
              QuerySnapshot productSnapshot = await FirebaseFirestore.instance
                  .collection('products')
                  .where('productName', isEqualTo: productName)
                  .get();

              if (productSnapshot.docs.isNotEmpty) {
                List<dynamic> tags = productSnapshot.docs.first['tags'] ?? [];
                for (var tag in tags) {
                  tempTagCounts[tag] = (tempTagCounts[tag] ?? 0) + quantity;
                }
                print(
                    'Fetching orders for customer: ${customerDoc.id} with branchID: $branchID and startDate: $startDate');
              }
            } catch (e) {
              print('Error fetching tags for product: $productName. $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching orders for customer: ${customerDoc.id}. $e');
    }
  }

  List<BarChartGroupData> _buildBarChartData() {
    if (tagCounts.isEmpty) {
      return [
        BarChartGroupData(x: 0, barRods: []),
      ]; // Empty bar when no data is available
    }

    int index = 0;
    return tagCounts.entries.map((entry) {
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.orangeAccent,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();
  }

  // Function to handle time range selection
  void onTimeRangeSelected(int index) {
    setState(() {
      selectedTimeRange = index;
      fetchTagData(); // Refetch the data based on the selected range
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequent Orders By Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTimeRangeButton('Today', 0),
                const SizedBox(width: 8),
                _buildTimeRangeButton('3 Days', 1),
                const SizedBox(width: 8),
                _buildTimeRangeButton('1 Week', 2),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: tagCounts.isNotEmpty
                      ? tagCounts.values.isNotEmpty
                          ? tagCounts.values
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() +
                              5
                          : 5
                      : 5, // Ensure maxY is set even with empty data
                  barGroups: _buildBarChartData(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          if (value.toInt() >= tagCounts.length) {
                            return const SizedBox.shrink();
                          }
                          final tag = tagCounts.keys.elementAt(value.toInt());
                          return Transform.rotate(
                            angle: -45 * 3.1415927 / 180,
                            child: Text(
                              tag.length > 10
                                  ? '${tag.substring(0, 10)}...'
                                  : tag,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barTouchData: BarTouchData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button for time range selection
  Widget _buildTimeRangeButton(String label, int index) {
    return ElevatedButton(
      onPressed: () => onTimeRangeSelected(index),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedTimeRange == index ? Colors.orange : Colors.grey,
      ),
      child: Text(label),
    );
  }
}

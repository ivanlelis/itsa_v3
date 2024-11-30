import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FrequentOrdersByTagsChart extends StatefulWidget {
  const FrequentOrdersByTagsChart({super.key});

  @override
  _FrequentOrdersByTagsChartState createState() =>
      _FrequentOrdersByTagsChartState();
}

class _FrequentOrdersByTagsChartState extends State<FrequentOrdersByTagsChart> {
  Map<String, int> tagCounts = {};

  @override
  void initState() {
    super.initState();
    fetchTagData();
  }

  Future<void> fetchTagData() async {
    Map<String, int> tempTagCounts = {};
    try {
      // Fetch all customers concurrently
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      // Collect all customer orders concurrently
      List<Future<QuerySnapshot>> customerOrderFetches =
          customerSnapshot.docs.map((customerDoc) {
        return customerDoc.reference.collection('orders').get();
      }).toList();

      // Wait for all customer orders to load concurrently
      List<QuerySnapshot> allOrdersSnapshots =
          await Future.wait(customerOrderFetches);

      // Process each order
      for (var ordersSnapshot in allOrdersSnapshots) {
        List<Future<void>> tagFetches = [];

        for (var orderDoc in ordersSnapshot.docs) {
          // Extract products array from each order
          List<dynamic> products = orderDoc['products'] ?? [];

          for (var product in products) {
            String productName = product['productName'] ?? '';
            int quantity = product['quantity'] ?? 0;

            // Match productName with the productName field in products collection
            tagFetches.add(FirebaseFirestore.instance
                .collection('products')
                .where('productName', isEqualTo: productName)
                .get()
                .then((productSnapshot) {
              if (productSnapshot.docs.isNotEmpty) {
                // Fetch tags from matched product document
                List<dynamic> tags = productSnapshot.docs.first['tags'] ?? [];
                for (var tag in tags) {
                  // Count tag occurrences, multiply by quantity
                  tempTagCounts[tag] = (tempTagCounts[tag] ?? 0) + quantity;
                }
              }
            }));
          }
        }

        // Wait for all tag data to be fetched concurrently
        await Future.wait(tagFetches);
      }

      // Update state with fetched tag counts
      setState(() {
        tagCounts = tempTagCounts;
      });
    } catch (e) {
      print('Error fetching tag data: $e');
    }
  }

  List<BarChartGroupData> _buildBarChartData() {
    return tagCounts.entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key.hashCode,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.orangeAccent,
                width: 15,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [], // Disable tooltips
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (tagCounts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
            SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: tagCounts.values
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble() +
                        5,
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
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, _) {
                            final tag = tagCounts.keys.firstWhere(
                              (key) => key.hashCode == value.toInt(),
                              orElse: () => '',
                            );
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
                    barTouchData: BarTouchData(enabled: false),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FrequentOrdersByTagsChart extends StatefulWidget {
  const FrequentOrdersByTagsChart({Key? key}) : super(key: key);

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
      // Get all customers
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      for (var customerDoc in customerSnapshot.docs) {
        // Get orders subcollection for each customer
        QuerySnapshot ordersSnapshot =
            await customerDoc.reference.collection('orders').get();

        for (var orderDoc in ordersSnapshot.docs) {
          // Extract productNames from each order
          List<dynamic> productNames = orderDoc['productNames'] ?? [];

          for (var productName in productNames) {
            // Match productName with productName field in products collection
            QuerySnapshot productSnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where('productName', isEqualTo: productName)
                .get();

            if (productSnapshot.docs.isNotEmpty) {
              // Fetch tags from matched product document
              List<dynamic> tags = productSnapshot.docs.first['tags'] ?? [];
              for (var tag in tags) {
                // Count tag occurrences
                tempTagCounts[tag] = (tempTagCounts[tag] ?? 0) + 1;
              }
            }
          }
        }
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
                // Remove labels above bars by setting no text
                rodStackItems: [],
              ),
            ],
            showingTooltipIndicators: [], // Ensure tooltips are disabled
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
                        sideTitles: SideTitles(
                            showTitles: false), // Disable right side numbers
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: false), // Disable top side numbers
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // Add more space for labels
                          getTitlesWidget: (value, _) {
                            final tag = tagCounts.keys.firstWhere(
                              (key) => key.hashCode == value.toInt(),
                              orElse: () => '',
                            );
                            return Transform.rotate(
                              angle: -45 *
                                  3.1415927 /
                                  180, // Rotate text by 45 degrees
                              child: Text(
                                tag.length > 10
                                    ? '${tag.substring(0, 10)}...'
                                    : tag, // Trim long tags
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
                    barTouchData:
                        BarTouchData(enabled: false), // Disable tooltips
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

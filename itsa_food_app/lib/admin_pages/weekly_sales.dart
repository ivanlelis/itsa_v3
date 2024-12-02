import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package

class WeeklySales extends StatefulWidget {
  final String userName;

  const WeeklySales({super.key, required this.userName});

  @override
  _WeeklySalesState createState() => _WeeklySalesState();
}

class _WeeklySalesState extends State<WeeklySales> {
  Future<List<Map<String, dynamic>>> fetchDailySales() async {
    List<Map<String, dynamic>> salesData = [];
    String branchID = '';

    try {
      // Determine the branchID based on the userName
      if (widget.userName == "Main Branch Admin") {
        branchID = "branch 1";
      } else if (widget.userName == "Sta. Cruz II Admin") {
        branchID = "branch 2";
      } else if (widget.userName == "San Dionisio Admin") {
        branchID = "branch 3";
      } else {
        print('Invalid userName');
        return salesData;
      }

      DateTime now = DateTime.now();

      // Loop through the last 7 days
      for (int i = 0; i < 7; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String collectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        // Debug print to show the collection being queried
        print('Fetching data from collection: $collectionName');

        var snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc('transactions')
            .collection(collectionName)
            .where('branchID', isEqualTo: branchID) // Filter by branchID
            .get();

        // Debug print to show the document being fetched
        print('Fetching documents with branchID: $branchID');

        if (snapshot.docs.isNotEmpty) {
          double totalProdCost = 0;

          // Sum up all the prodCost values for the filtered documents
          for (var doc in snapshot.docs) {
            if (doc.exists) {
              double prodCost = doc.data()['prodCost'] ?? 0.0;
              totalProdCost += prodCost;
            }
          }

          // Get the date for the sales data
          List<String> dateParts = collectionName.split('_');
          String formattedDate =
              '${dateParts[1]}-${dateParts[2]}-${dateParts[3]}';
          List<String> dateSplit = formattedDate.split('-');
          DateTime dateTime = DateTime(
            2000 + int.parse(dateSplit[2]),
            int.parse(dateSplit[0]),
            int.parse(dateSplit[1]),
          );

          // Format the date and add the data to the list
          DateFormat('dd/yy').format(dateTime);

          // Add sales data
          salesData.add({
            'dateTime': dateTime, // Store the actual DateTime object
            'sales': totalProdCost, // Sum of prodCost as the daily sales
          });
        }
      }
    } catch (e) {
      print("Error fetching sales data: $e");
    }

    return salesData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Sales Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDailySales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching sales data.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sales data found.'));
          } else {
            final salesData = snapshot.data!;

            // Reverse the data to have the oldest date first
            salesData.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));

            // Calculate max sales value to avoid bars going beyond the chart's roof
            double maxSales = 0;
            for (var sales in salesData) {
              double dailySales = sales['sales'];
              if (dailySales > maxSales) {
                maxSales = dailySales;
              }
            }

            // Set a reasonable margin above the max sales value
            double adjustedMaxY = maxSales * 1.2;

            // Prepare data for the Bar Chart
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Sales Data for the Week',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 320, // Increased height for better visibility
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: BarChart(
                            BarChartData(
                              maxY:
                                  adjustedMaxY, // Dynamically calculated max Y value
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: salesData.map((sales) {
                                double dailySales = sales['sales'];

                                return BarChartGroupData(
                                  x: salesData.indexOf(sales),
                                  barRods: [
                                    BarChartRodData(
                                      toY: dailySales,
                                      color: Colors.blueAccent,
                                      width:
                                          16, // Adjusted width for better look
                                    ),
                                  ],
                                );
                              }).toList(),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  axisNameWidget: const Text('Sales'),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 200,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Text('Date'),
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        DateFormat('dd MMM').format(
                                            salesData[value.toInt()]
                                                ['dateTime']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sales = salesData[index];
                      final salesValue = sales['sales'];

                      // Format the date for display
                      String fullDate =
                          DateFormat('dd MMMM yyyy').format(sales['dateTime']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              'Date: $fullDate', // Full date is now displayed
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            subtitle: Text(
                              'Sales: ₱$salesValue',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: salesData.length,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

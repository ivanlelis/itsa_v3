import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package

class WeeklySales extends StatefulWidget {
  @override
  _WeeklySalesState createState() => _WeeklySalesState();
}

class _WeeklySalesState extends State<WeeklySales> {
  Future<List<Map<String, dynamic>>> fetchDailySales() async {
    List<Map<String, dynamic>> salesData = [];

    try {
      DateTime now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String collectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        var snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc('transactions')
            .collection(collectionName)
            .doc('dailySales')
            .get();

        if (snapshot.exists) {
          Map<String, dynamic> sales = snapshot.data()!;
          List<String> dateParts = collectionName.split('_');
          String formattedDate =
              '${dateParts[1]}-${dateParts[2]}-${dateParts[3]}';

          List<String> dateSplit = formattedDate.split('-');
          DateTime dateTime = DateTime(
            2000 + int.parse(dateSplit[2]),
            int.parse(dateSplit[0]),
            int.parse(dateSplit[1]),
          );

          String readableDate = DateFormat('dd/yy').format(dateTime);

          // Add sales data
          salesData.add({
            'date': readableDate,
            'sales': sales, // Assuming sales is a number or can be parsed
          });
        }
      }
    } catch (e) {
      print("Error fetching sales data: $e");
    }

    print(
        "Fetched Sales Data: $salesData"); // Debug: Check the fetched sales data
    return salesData;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
            salesData.sort((a, b) => DateFormat('dd/yy')
                .parse(a['date']!)
                .compareTo(DateFormat('dd/yy').parse(b['date']!)));

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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 300, // Set a height for the chart
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Add horizontal padding
                          child: Center(
                            // Wrap the chart in a Center widget
                            child: BarChart(
                              BarChartData(
                                maxY:
                                    1000, // Set the maximum value of the y-axis to 1000
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: salesData.map((sales) {
                                  double dailySales = sales['sales'] is Map
                                      ? (sales['sales']['sales']?.toDouble() ??
                                          0.0)
                                      : 0.0;

                                  return BarChartGroupData(
                                    x: salesData.indexOf(sales),
                                    barRods: [
                                      BarChartRodData(
                                        toY: dailySales,
                                        color: Colors.blueAccent,
                                        width: 10,
                                      ),
                                    ],
                                  );
                                }).toList(),
                                gridData: FlGridData(
                                  drawVerticalLine:
                                      false, // Optional, for cleaner visualization
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const Text('Sales'),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval:
                                          200, // Maintain an interval of 200 between y-axis labels
                                      reservedSize:
                                          35, // Increase reserved space for y-axis labels
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
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
                                          salesData[value.toInt()]['date'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
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
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sales = salesData[index];
                      // Accessing sales value correctly
                      final salesValue = sales['sales'] is Map
                          ? sales['sales']['sales']
                          : sales[
                              'sales']; // Handles both Map and direct values

                      return ListTile(
                        title: Text('Date: ${sales['date']}'),
                        subtitle: Text('Sales: ₱$salesValue'),
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

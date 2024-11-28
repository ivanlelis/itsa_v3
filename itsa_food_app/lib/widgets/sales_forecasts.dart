import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:itsa_food_app/widgets/full_chartpage.dart';
import 'package:flutter/services.dart';

class SalesForecasts extends StatefulWidget {
  @override
  _SalesForecastsState createState() => _SalesForecastsState();
}

class _SalesForecastsState extends State<SalesForecasts> {
  List<Map<String, dynamic>> subcollectionDetails = [];
  bool isLoading = false;

  // Function to fetch each subcollection and its relevant documents
  Future<void> fetchTransactionDetails(String subcollectionName) async {
    try {
      final transactionsDocRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc('transactions');

      final dailySalesDoc = await transactionsDocRef
          .collection(subcollectionName)
          .doc('dailySales')
          .get();
      final dailyNetProfitDoc = await transactionsDocRef
          .collection(subcollectionName)
          .doc('dailyNetProfit')
          .get();

      subcollectionDetails.add({
        'subcollectionName': subcollectionName,
        'dailySales': dailySalesDoc.exists ? dailySalesDoc.data() : null,
        'dailyNetProfit':
            dailyNetProfitDoc.exists ? dailyNetProfitDoc.data() : null,
      });
    } catch (e) {
      print("Error fetching details for $subcollectionName: $e");
    }
  }

  String generateDateString(DateTime date) {
    return DateFormat('MM_dd_yy').format(date);
  }

  Future<void> _fetchSubcollections() async {
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime dayOfWeek =
          currentDate.subtract(Duration(days: currentDate.weekday % 7 - i));
      String formattedDate = generateDateString(dayOfWeek);
      await fetchTransactionDetails('transactions_$formattedDate');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    await _fetchSubcollections();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalWeeklySales = 0.0;
    double totalWeeklyNetProfit = 0.0;

    // Prepare data for the charts
    List<FlSpot> dailySalesData = [];
    List<FlSpot> dailyNetProfitData = [];

    List<String> dates = [];
    List<double> sales = [];
    List<double> netProfits = [];

    for (var details in subcollectionDetails) {
      dates.add(formatSubcollectionDate(details['subcollectionName']));
      double salesValue = (details['dailySales']?['sales'] ?? 0.0).toDouble();
      double netProfitValue =
          (details['dailyNetProfit']?['netProfit'] ?? 0.0).toDouble();

      sales.add(salesValue);
      netProfits.add(netProfitValue);

      totalWeeklySales += salesValue;
      totalWeeklyNetProfit += netProfitValue;

      dailySalesData.add(FlSpot(sales.length.toDouble(), salesValue));
      dailyNetProfitData
          .add(FlSpot(netProfits.length.toDouble(), netProfitValue));
    }

    String formatToTwoDecimals(dynamic value) {
      if (value == null) return 'No data';
      try {
        return double.parse(value.toString()).toStringAsFixed(2);
      } catch (e) {
        return value.toString();
      }
    }

    // Using MediaQuery to get the screen size for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Forecasts'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subcollectionDetails.isEmpty
              ? const Center(child: Text('No subcollections available'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(
                        screenWidth * 0.04), // Adjust padding dynamically
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weekly Summary Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          color: Colors.blueAccent,
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              children: [
                                const Text(
                                  "Weekly Summary",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Total Sales: ₱${formatToTwoDecimals(totalWeeklySales)}",
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.05, // Adjust font size dynamically
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "Total Net Profit: ₱${formatToTwoDecimals(totalWeeklyNetProfit)}",
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.05, // Adjust font size dynamically
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Daily Sales Chart in a Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: screenHeight *
                                      0.3, // Dynamic height based on screen size
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: LineChart(
                                      LineChartData(
                                          // Line chart data setup
                                          ),
                                    ),
                                  ),
                                ),
                                // Full View Button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullChartView(
                                          chartData:
                                              dailySalesData, // Pass data to the full view
                                          title: "Daily Sales Chart",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Full View"),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Daily Net Profit Chart in a Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: screenHeight *
                                      0.3, // Dynamic height based on screen size
                                  child: LineChart(
                                    LineChartData(
                                        // Line chart data setup
                                        ),
                                  ),
                                ),
                                // Full View Button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FullChartView(
                                          chartData:
                                              dailyNetProfitData, // Pass data to the full view
                                          title: "Daily Net Profit Chart",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Full View"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String formatSubcollectionDate(String subcollectionName) {
    final datePart = subcollectionName.replaceFirst('transactions_', '');
    try {
      final DateTime parsedDate = DateFormat('MM_dd_yy').parse(datePart);
      return DateFormat('MMMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return subcollectionName;
    }
  }
}

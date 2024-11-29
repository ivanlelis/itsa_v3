import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'weekly_sales.dart'; // Import the WeeklySales screen

class SalesTab extends StatefulWidget {
  @override
  _SalesTabState createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  double totalCurrentWeekSales = 0.0;
  double totalPreviousWeekSales = 0.0;
  List<Map<String, dynamic>> currentWeekSalesData = [];
  List<Map<String, dynamic>> previousWeekSalesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeeklySales();
  }

  Future<void> _fetchWeeklySales() async {
    List<Map<String, dynamic>> fetchedCurrentWeekSalesData = [];
    List<Map<String, dynamic>> fetchedPreviousWeekSalesData = [];

    try {
      DateTime now = DateTime.now();
      double currentWeekSales = 0.0;
      double previousWeekSales = 0.0;

      // Fetch sales for the current week (7 days)
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
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          double sales = data['sales'] != null
              ? double.parse(data['sales'].toString())
              : 0.0;
          String readableDate = DateFormat('MM/dd/yy').format(date);

          fetchedCurrentWeekSalesData
              .add({'date': readableDate, 'sales': sales});
          currentWeekSales += sales;
        }
      }

      // Fetch sales for the previous week (7 days before the current week)
      for (int i = 7; i < 14; i++) {
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
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          double sales = data['sales'] != null
              ? double.parse(data['sales'].toString())
              : 0.0;
          String readableDate = DateFormat('MM/dd/yy').format(date);

          fetchedPreviousWeekSalesData
              .add({'date': readableDate, 'sales': sales});
          previousWeekSales += sales;
        }
      }

      setState(() {
        currentWeekSalesData = fetchedCurrentWeekSalesData;
        previousWeekSalesData = fetchedPreviousWeekSalesData;
        totalCurrentWeekSales = currentWeekSales;
        totalPreviousWeekSales = previousWeekSales;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the target sales for next week
    double nextWeekTargetSales = totalCurrentWeekSales;

    // Calculate percentage change
    double salesChangePercentage = 0.0;
    if (totalPreviousWeekSales > 0) {
      salesChangePercentage =
          ((totalCurrentWeekSales - totalPreviousWeekSales) /
                  totalPreviousWeekSales) *
              100;
    }

    // Dynamic adjustment based on sales change
    if (salesChangePercentage > 0) {
      // Increase target by the percentage change, with a cap of 20%
      nextWeekTargetSales =
          totalCurrentWeekSales * (1 + (salesChangePercentage / 100));
      nextWeekTargetSales = nextWeekTargetSales > totalCurrentWeekSales * 1.20
          ? totalCurrentWeekSales * 1.20
          : nextWeekTargetSales; // Ensure no more than a 20% increase
    } else if (salesChangePercentage < 0) {
      // Decrease target by the percentage change, with a cap of 20%
      nextWeekTargetSales =
          totalCurrentWeekSales * (1 + (salesChangePercentage / 100));
      nextWeekTargetSales = nextWeekTargetSales < totalCurrentWeekSales * 0.80
          ? totalCurrentWeekSales * 0.80
          : nextWeekTargetSales; // Ensure no more than a 20% decrease
    } // else, keep the target the same (no change)

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklySales(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA78D78),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: Text(
              'View Weekly Sales Chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Next Week Target Sales Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Next Week's Target Sales:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E473B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${nextWeekTargetSales.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E473B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    salesChangePercentage > 0
                        ? 'Target for next week is ${salesChangePercentage.toStringAsFixed(2)}% higher (capped at 20%) than this week\'s sales.'
                        : salesChangePercentage < 0
                            ? 'Target for next week is ${salesChangePercentage.toStringAsFixed(2)}% lower (capped at 20%) than this week\'s sales.'
                            : 'Target for next week is the same as this week\'s sales.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E473B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Display sales change percentage
                  Text(
                    'Sales Change: ${salesChangePercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E473B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current Week Sales Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExpansionTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Week Sales:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${totalCurrentWeekSales.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                  ],
                ),
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment
                                  .centerLeft, // Ensures left alignment
                              child: Text(
                                'Daily Breakdown:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6E473B),
                                ),
                              ),
                            ),
                            ...currentWeekSalesData
                                .map(
                                  (data) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      '${data['date']}: ₱${data['sales'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Previous Week Sales Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExpansionTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Week Sales:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${totalPreviousWeekSales.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                  ],
                ),
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment
                                  .centerLeft, // Ensures left alignment
                              child: Text(
                                'Daily Breakdown:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6E473B),
                                ),
                              ),
                            ),
                            ...previousWeekSalesData
                                .map(
                                  (data) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      '${data['date']}: ₱${data['sales'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E473B),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'weekly_sales.dart'; // Import the WeeklySales screen
import 'dart:math';

class SalesTab extends StatefulWidget {
  final String userName;

  const SalesTab({super.key, required this.userName});

  @override
  _SalesTabState createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  double totalCurrentWeekSales = 0.0;
  double totalPreviousWeekSales = 0.0;
  List<Map<String, dynamic>> currentWeekSalesData = [];
  List<Map<String, dynamic>> previousWeekSalesData = [];
  bool isLoading = true;
  String branchID = '';

  @override
  void initState() {
    super.initState();
    _setBranchID(); // Set branchID based on userName
    _fetchWeeklySales();
  }

  void _setBranchID() {
    switch (widget.userName) {
      case 'Main Branch Admin':
        branchID = 'branch 1'; // Set to branch name instead of number
        break;
      case 'Sta. Cruz II Admin':
        branchID = 'branch 2'; // Set to branch name instead of number
        break;
      case 'San Dionisio Admin':
        branchID = 'branch 3'; // Set to branch name instead of number
        break;
      default:
        branchID =
            'branch 1'; // Default to "branch 1" if userName doesn't match
        break;
    }

    // Debug print for userName and branchID
    print('UserName: ${widget.userName}');
    print('BranchID set to: $branchID');
  }

  Future<void> _fetchWeeklySales() async {
    try {
      DateTime now = DateTime.now();
      double currentWeekProdCost = 0.0;
      double previousWeekProdCost = 0.0;

      // Fetch sales for the current week (7 days)
      for (int i = 0; i < 7; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String subCollectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        var snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc('transactions')
            .collection(subCollectionName)
            .get();

        double dailySales = 0.0;

        for (var doc in snapshot.docs) {
          var data = doc.data();
          if (data['branchID'] == branchID) {
            dailySales += (data['prodCost'] ?? 0).toDouble();
          }
        }

        // Add daily sales data to the list
        currentWeekSalesData.add({
          'date':
              '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'sales': dailySales,
        });

        // Accumulate current week total prodCost
        currentWeekProdCost += dailySales;
      }

      // Fetch sales for the previous week (7 days before the current week)
      for (int i = 7; i < 14; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String subCollectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        var snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc('transactions')
            .collection(subCollectionName)
            .get();

        double dailySales = 0.0;

        for (var doc in snapshot.docs) {
          var data = doc.data();
          if (data['branchID'] == branchID) {
            dailySales += (data['prodCost'] ?? 0).toDouble();
          }
        }

        // Add daily sales data to the previous week sales list
        previousWeekSalesData.add({
          'date':
              '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'sales': dailySales,
        });

        // Accumulate previous week total prodCost
        previousWeekProdCost += dailySales;
      }

      // Calculate WMA for the current week
      double wma = calculateWMA(currentWeekSalesData);

      // Calculate normalized sales change percentage between current and previous week
      double salesChangePercentage =
          ((currentWeekProdCost - previousWeekProdCost) /
                  previousWeekProdCost) *
              100;

      // Normalize the sales change factor to avoid large jumps (capping at ±20%)
      double normalizedSalesChange = salesChangePercentage.clamp(-20.0, 20.0);

      // Use the WMA and normalized sales change to compute the next week's target sales
      double nextWeekTargetSales = wma * (1 + normalizedSalesChange / 100);

      setState(() {
        totalCurrentWeekSales = currentWeekProdCost; // Use prodCost as sales
        totalPreviousWeekSales = previousWeekProdCost; // Use prodCost as sales
        isLoading = false;
      });

      // Debug prints
      print('Total Current Week ProdCost: $totalCurrentWeekSales');
      print('Total Previous Week ProdCost: $totalPreviousWeekSales');
      print('WMA (current week): $wma');
      print('Sales Change Percentage: $salesChangePercentage');
      print('Normalized Sales Change: $normalizedSalesChange');
      print('Next Week Target Sales: $nextWeekTargetSales');
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculateWMA(List<Map<String, dynamic>> salesData) {
    if (salesData.isEmpty) {
      return 0.0; // Return a default value if no data is available
    }

    List<int> weights = [7, 6, 5, 4, 3, 2, 1];
    double weightedSum = 0.0;
    int weightSum = 0;

    for (int i = 0; i < salesData.length; i++) {
      double sales = salesData[i]['sales'] ?? 0.0; // Ensure sales is not null
      weightedSum += sales * weights[i];
      weightSum += weights[i];
    }

    if (weightSum == 0) {
      return 0.0; // Prevent division by zero
    }

    return weightedSum / weightSum;
  }

  @override
  Widget build(BuildContext context) {
    double nextWeekTargetSales = totalCurrentWeekSales;

    // Calculate percentage change
    double salesChangePercentage = 0.0;
    if (totalPreviousWeekSales > 0) {
      salesChangePercentage =
          ((totalCurrentWeekSales - totalPreviousWeekSales) /
                  totalPreviousWeekSales) *
              100;
    }

    // Adjusted Sales Change Factor to smooth extreme changes, with a more restrictive cap
    double salesChangeFactor = 1 + (salesChangePercentage / 100);
    salesChangeFactor =
        salesChangeFactor.clamp(0.5, 1.5); // Clamped between 0.5 and 1.5

    // Calculate WMA for current week's sales data
    double weightedMovingAverage = calculateWMA(currentWeekSalesData);

    // Apply the revised hybrid formula
    nextWeekTargetSales = max(
        (weightedMovingAverage * 0.5) +
            (totalCurrentWeekSales * salesChangeFactor * 0.5),
        0.8 * totalCurrentWeekSales);

    // Debug prints after calculations
    print('Weighted Moving Average: $weightedMovingAverage');
    print('Sales Change Percentage: $salesChangePercentage');
    print('Sales Change Factor: $salesChangeFactor');
    print('Next Week Target Sales: $nextWeekTargetSales');

    // Displaying the results
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
                  builder: (context) => WeeklySales(userName: widget.userName),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA78D78),
              padding: const EdgeInsets.symmetric(
                  vertical: 12), // Remove horizontal padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            child: SizedBox(
              width: double.infinity, // Makes the button full-width
              child: Center(
                child: Text(
                  'View Weekly Sales Chart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Next Week Target Sales Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                        ? 'Target for next week is ${salesChangePercentage.toStringAsFixed(2)}% higher than this week\'s sales.'
                        : salesChangePercentage < 0
                            ? 'Target for next week is ${salesChangePercentage.toStringAsFixed(2)}% lower than this week\'s sales.'
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

          // Display Weighted Moving Average
          SizedBox(
            width:
                double.infinity, // Ensures the card takes full available width
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weighted Moving Average (WMA):",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${weightedMovingAverage.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Current Week Sales Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                            ...currentWeekSalesData.map(
                              (data) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  '${data['date']}: ₱${data['sales'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E473B),
                                  ),
                                ),
                              ),
                            ),
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
              borderRadius: BorderRadius.circular(10),
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
                            ...previousWeekSalesData.map(
                              (data) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  '${data['date']}: ₱${data['sales'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E473B),
                                  ),
                                ),
                              ),
                            ),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'weekly_sales.dart'; // Import the WeeklySales screen

class SalesTab extends StatefulWidget {
  @override
  _SalesTabState createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  double totalWeeklySales = 0.0;
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeeklySales();
  }

  Future<void> _fetchWeeklySales() async {
    List<Map<String, dynamic>> fetchedSalesData = [];

    try {
      DateTime now = DateTime.now();
      double totalSales = 0.0;

      for (int i = 0; i < 7; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String collectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        print(
            "Fetching collection: transactions/transactions/$collectionName/dailySales"); // Debug print

        // Fetch dailySales document
        var snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc('transactions') // Adjusted to include 'transactions' doc
            .collection(collectionName)
            .doc('dailySales')
            .get();

        if (snapshot.exists) {
          print(
              "Document found in transactions/transactions/$collectionName/dailySales"); // Debug print

          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          double sales = data['sales'] != null
              ? double.parse(data['sales'].toString())
              : 0.0;

          print("Sales for $collectionName: $sales"); // Debug print

          String readableDate = DateFormat('MM/dd/yy').format(date);

          // Add to fetched sales data
          fetchedSalesData.add({
            'date': readableDate,
            'sales': sales,
          });

          totalSales += sales;
        } else {
          print(
              "No document found in transactions/transactions/$collectionName/dailySales"); // Debug print
        }
      }

      // Update state
      setState(() {
        salesData = fetchedSalesData;
        totalWeeklySales = totalSales;
        isLoading = false;
      });

      print("Total Weekly Sales: $totalWeeklySales"); // Debug print
      print("Sales Data: $salesData"); // Debug print
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Forecast',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Button to navigate to WeeklySales
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklySales(),
                ),
              );
            },
            child: const Text('View Weekly Sales Chart'),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Weekly Sales: PHP ${totalWeeklySales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Daily Breakdown:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...salesData.map((entry) {
                      return Text(
                        '${entry['date']}: PHP ${entry['sales'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      );
                    }).toList(),
                  ],
                ),
        ],
      ),
    );
  }
}

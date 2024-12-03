import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fl_chart/fl_chart.dart'; // Importing the chart package

class OffersForecast extends StatefulWidget {
  final String userName;

  OffersForecast({super.key, required this.userName});

  @override
  _OffersForecastState createState() => _OffersForecastState();
}

class _OffersForecastState extends State<OffersForecast> {
  late String branchID;
  bool isLoading = false;
  Map<String, int> voucherUsageCount =
      {}; // Map to store the count of each voucher

  @override
  void initState() {
    super.initState();
    // Map userName to branchID
    branchID = _getBranchID(widget.userName);
    _fetchDocumentsForLast14Days(); // Fetch documents for the last 14 days
  }

  // Map userName to branchID
  String _getBranchID(String userName) {
    switch (userName) {
      case "Main Branch Admin":
        return "branch 1";
      case "Sta. Cruz II Admin":
        return "branch 2";
      case "San Dionisio Admin":
        return "branch 3";
      default:
        return "";
    }
  }

  Future<void> _fetchDocumentsForLast14Days() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get all subcollection names for the past 14 days
      List<String> subcollectionNames = _getLastTwoWeeksSubcollections();

      for (String subcollection in subcollectionNames) {
        print("Fetching data for subcollection: $subcollection");

        // Reference to the daily subcollection
        CollectionReference dailyCollection = FirebaseFirestore.instance
            .collection('transactions') // Root collection
            .doc('transactions') // Single document under root
            .collection(subcollection); // Subcollection for the day

        Query query = dailyCollection.where('branchID',
            isEqualTo: branchID); // Filter by branchID

        QuerySnapshot snapshot = await query.get();

        print("Fetched ${snapshot.docs.length} documents from $subcollection.");

        if (snapshot.docs.isNotEmpty) {
          // Process each document
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>?;
            String? voucherCode = data?.containsKey('voucherCode') == true
                ? data!['voucherCode']
                : null;

            // Count the usage of each voucher code
            if (voucherCode != null) {
              setState(() {
                // If voucherCode already exists, increment its count
                if (voucherUsageCount.containsKey(voucherCode)) {
                  voucherUsageCount[voucherCode] =
                      voucherUsageCount[voucherCode]! + 1;
                } else {
                  // Otherwise, add a new entry for the voucher code
                  voucherUsageCount[voucherCode] = 1;
                }
              });
            }
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching documents: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Change here to fetch subcollections for the last 14 days
  List<String> _getLastTwoWeeksSubcollections() {
    List<String> subcollections = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String subcollectionName =
          'transactions_${DateFormat('MM_dd_yy').format(date)}';
      subcollections.add(subcollectionName);
    }
    return subcollections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (voucherUsageCount.isEmpty)
              const Center(child: Text('No voucher usage found.'))
            else ...[
              // Displaying a bar chart for voucher usage
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Display voucherCode as x-axis titles
                              String voucherCode = voucherUsageCount.keys
                                  .elementAt(
                                      value.toInt() % voucherUsageCount.length);
                              return Text(
                                voucherCode,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      barGroups: voucherUsageCount.entries.map((entry) {
                        return BarChartGroupData(
                          x: voucherUsageCount.keys.toList().indexOf(
                              entry.key), // Set x to index of voucherCode
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Colors.blue,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Display voucher usage details
              Expanded(
                child: ListView.builder(
                  itemCount: voucherUsageCount.keys.length,
                  itemBuilder: (context, index) {
                    String voucherCode =
                        voucherUsageCount.keys.elementAt(index);
                    int usageCount = voucherUsageCount[voucherCode] ?? 0;

                    return ListTile(
                      title: Text('Voucher Code: $voucherCode'),
                      subtitle: Text('Used $usageCount times'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

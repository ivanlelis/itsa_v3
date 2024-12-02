import 'package:flutter/material.dart';

class OffersForecast extends StatelessWidget {
  final String userName;

  // Sample historical data (Replace with your actual data source)
  final List<Map<String, dynamic>> historicalData = [
    {"day": 1, "revenue": 500, "cost": 300, "discountUsed": 50},
    {"day": 2, "revenue": 450, "cost": 300, "discountUsed": 70},
    {"day": 3, "revenue": 400, "cost": 300, "discountUsed": 100},
    {"day": 4, "revenue": 350, "cost": 300, "discountUsed": 120},
  ];

  OffersForecast({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Calculate profitability and determine the threshold
    final List<Map<String, dynamic>> forecastData =
        _forecastProfitability(historicalData);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vouchers and Promos Forecasting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Vouchers and Promos Forecasting, $userName!',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            Text(
              'Profitability Forecast:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: forecastData.length,
                itemBuilder: (context, index) {
                  final entry = forecastData[index];
                  return ListTile(
                    title: Text('Day ${entry["day"]}:'),
                    subtitle: Text(
                      'Profit: ${entry["profit"].toStringAsFixed(2)}\nStatus: ${entry["status"]}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _forecastProfitability(
      List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> forecast = [];
    for (var entry in data) {
      // Ensure all numeric values are treated as doubles
      double revenue = entry["revenue"].toDouble();
      double cost = entry["cost"].toDouble();
      double discountUsed = entry["discountUsed"].toDouble();

      double profit = revenue - cost - discountUsed;
      String status = profit > 0 ? "Profitable" : "Diminishing Returns";

      forecast.add({
        "day": entry["day"], // No need to cast 'day' since it's just an int
        "profit": profit,
        "status": status,
      });
    }
    return forecast;
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProductOrderLineChart extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> productOrderHistory;

  ProductOrderLineChart({required this.productOrderHistory});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              top: BorderSide(color: Colors.transparent),
              right: BorderSide(color: Colors.transparent),
              bottom: BorderSide(color: Colors.black, width: 1),
              left: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          lineBarsData: _getLineBarsData(),
        ),
      ),
    );
  }

  List<LineChartBarData> _getLineBarsData() {
    // Convert each product's order history into a line on the graph
    return productOrderHistory.entries.map((entry) {
      final history = entry.value;

      return LineChartBarData(
        spots: history.map((point) {
          // Use time difference as X and count as Y
          final timeDifference = point['time']
              .difference(history.first['time'])
              .inMinutes
              .toDouble();
          return FlSpot(timeDifference, point['count'].toDouble());
        }).toList(),
        isCurved: true,
        color: Colors.blue, // Ensure lines have a visible color
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) => true,
        ),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.2), // Shaded area under the line
        ),
        barWidth: 3, // Adjusted line width for better visibility
        isStrokeCapRound: true, // Makes line edges rounded
      );
    }).toList();
  }
}

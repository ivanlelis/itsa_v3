import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class FullChartView extends StatefulWidget {
  final List<FlSpot> chartData;
  final String title;

  const FullChartView({required this.chartData, required this.title, Key? key})
      : super(key: key);

  @override
  _FullChartViewState createState() => _FullChartViewState();
}

class _FullChartViewState extends State<FullChartView> {
  @override
  void initState() {
    super.initState();
    // Lock screen orientation to landscape when the screen is created
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    // Reset the orientation to portrait mode when leaving the screen
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Reset the orientation to portrait mode when back is pressed
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        return true; // Allow the back action to proceed
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.04), // Dynamic padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart Container
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.70, // 80% of screen height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true, // Show vertical grid lines
                          drawHorizontalLine:
                              true, // Show horizontal grid lines
                          verticalInterval: 1, // Grid lines every 1 unit
                          horizontalInterval:
                              1, // Same for horizontal to form squares
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey
                                  .withOpacity(0.5), // Grid line color
                              strokeWidth: 1.0, // Grid line thickness
                            );
                          },
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey
                                  .withOpacity(0.5), // Grid line color
                              strokeWidth: 1.0, // Grid line thickness
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          // Set the following to false to hide top and right titles
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true, // Show border around the chart
                          border: Border.all(
                            color: Colors.grey.withOpacity(1), // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: widget.chartData,
                            isCurved: true,
                            color: Colors.blue, // Line color
                            dotData: FlDotData(show: false), // Hide dots
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHome extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const AdminHome({
    super.key,
    this.userName = "Admin",
    required this.email,
    this.imageUrl = '',
  });

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  String? mostOrderedProduct;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, int> productCount = {}; // Store product order counts

  @override
  void initState() {
    super.initState();
    fetchMostOrderedProduct();
  }

  Future<void> fetchMostOrderedProduct() async {
    productCount.clear(); // Clear existing data before fetching
    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    for (var customerDoc in customerSnapshot.docs) {
      QuerySnapshot orderSnapshot =
          await customerDoc.reference.collection('orders').get();

      for (var orderDoc in orderSnapshot.docs) {
        List<dynamic> products = orderDoc['productNames'] ?? [];
        for (var product in products) {
          productCount[product] = (productCount[product] ?? 0) + 1;
        }
      }
    }

    String? mostOrdered;
    int maxCount = 0;
    productCount.forEach((product, count) {
      if (count > maxCount) {
        mostOrdered = product;
        maxCount = count;
      }
    });

    setState(() {
      mostOrderedProduct = mostOrdered;
    });
  }

  Future<void> _onRefresh() async {
    await fetchMostOrderedProduct(); // Fetch new data on refresh
  }

  List<BarChartGroupData> _buildBarChartData() {
    return productCount.entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key.hashCode, // Unique identifier for each bar
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.blueAccent,
                width: 15,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [0],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminEmail = Provider.of<UserProvider>(context).adminEmail;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Call _onRefresh when pulled
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Add this line
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.imageUrl.isNotEmpty
                      ? NetworkImage(widget.imageUrl)
                      : const NetworkImage(
                          'https://example.com/placeholder.png'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome, ${widget.userName}!',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Email: $adminEmail',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (mostOrderedProduct != null)
                  Text(
                    "What's the most ordered product: $mostOrderedProduct",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 10),
                // Card containing the Horizontal Bar Chart
                if (productCount.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Order Count',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300, // Reduced height for the chart
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 100,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipRoundedRadius:
                                        4, // Reduced rounded radius
                                    tooltipPadding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2), // Reduced padding
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final productName = productCount.keys
                                          .elementAt(groupIndex);
                                      final orderCount = rod.toY.toInt();
                                      return BarTooltipItem(
                                        '$productName\n',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10, // Reduced font size
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$orderCount orders',
                                            style: const TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 8, // Reduced font size
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: 20,
                                      getTitlesWidget: (value, _) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      interval:
                                          2, // Show every other product name
                                      getTitlesWidget: (value, _) {
                                        final product =
                                            productCount.keys.firstWhere(
                                          (k) => k.hashCode == value.toInt(),
                                          orElse: () => '',
                                        );
                                        return Transform.rotate(
                                          angle:
                                              -0.45, // Rotate label to reduce crowding
                                          child: Text(
                                            product.length > 10
                                                ? '${product.substring(0, 10)}...'
                                                : product,
                                            style: const TextStyle(fontSize: 9),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: 20,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[300],
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: const Border(
                                    left: BorderSide(
                                        width: 1, color: Colors.black54),
                                    bottom: BorderSide(
                                        width: 1, color: Colors.black54),
                                  ),
                                ),
                                barGroups: _buildBarChartData(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      drawer: AdminSidebar(onLogout: _logout),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ProductOrder {
  final String productName;
  final int count;

  ProductOrder(this.productName, this.count);
}

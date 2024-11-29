import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itsa_food_app/widgets/tags_chart.dart';
import 'package:itsa_food_app/widgets/pending_orders.dart';
import 'package:itsa_food_app/widgets/total_orders.dart';
import 'package:itsa_food_app/widgets/most_ordered.dart';
import 'package:itsa_food_app/admin_pages/forecasting.dart';

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
  String? lastActiveTime;
  List<Map<String, dynamic>> orders = []; // Fetch this from Firestore
  String selectedFilter = 'Today';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMostOrderedProduct('Today'); // Pass a default filter
    _getLastActiveTime();
  }

  Future<void> _getLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastActiveTime = prefs.getString('last_active_time');
    });
  }

  Future<void> fetchMostOrderedProduct(String filter) async {
    setState(() {
      isLoading = true; // Set loading to true when fetching starts
    });

    productCount.clear(); // Clear existing data before fetching

    DateTime now = DateTime.now();
    DateTime startTime;

    if (filter == 'Today') {
      startTime = DateTime(now.year, now.month, now.day); // Midnight today
    } else if (filter == '3 Days') {
      startTime = now.subtract(Duration(days: 3));
    } else if (filter == '1 Week') {
      startTime = now.subtract(Duration(days: 7));
    } else {
      throw ArgumentError('Invalid filter: $filter');
    }

    // Fetch customer data
    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    for (var customerDoc in customerSnapshot.docs) {
      // Fetch orders for each customer
      QuerySnapshot orderSnapshot =
          await customerDoc.reference.collection('orders').get();

      for (var orderDoc in orderSnapshot.docs) {
        Timestamp timestamp = orderDoc['timestamp'];
        DateTime orderDate = timestamp.toDate();

        // Filter orders by the selected time range
        if (orderDate.isAfter(startTime)) {
          List<dynamic> products = orderDoc['productNames'] ?? [];
          for (var product in products) {
            productCount[product] = (productCount[product] ?? 0) + 1;
          }
        }
      }
    }

    setState(() {
      isLoading = false; // Set loading to false once the data is fetched
    });
  }

  Future<void> _onRefresh() async {
    await fetchMostOrderedProduct('Today'); // Fetch new data on refresh
  }

  List<BarChartGroupData> _buildBarChartData() {
    return productCount.entries.map((entry) {
      final index = productCount.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.blue, // Customize bar color
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  void _updateChartData(String filter) {
    fetchMostOrderedProduct(filter);
  }

  Widget _buildTimeFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: isSelected ? 4 : 0,
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalOrders = 372; // Example data, replace with dynamic data
    int deliveryOrders = 122; // Example data, replace with dynamic data
    int pickupOrders = 100; // Example data, replace with dynamic data

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE1D4C2), // Set the background color
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                // Existing Total Orders Card
                TotalOrdersCard(
                  totalOrders: totalOrders,
                  deliveryOrders: deliveryOrders,
                  pickupOrders: pickupOrders,
                ),
                // New Most Ordered Card
                const MostOrderedCard(),

                // New Card with Button to Forecasting
                SizedBox(
                  width: MediaQuery.of(context).size.width * 1,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forecasting',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to Forecasting page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForecastingPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14.0, horizontal: 30.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors
                                  .blue, // Use backgroundColor instead of primary
                            ),
                            child: const Text(
                              'Go to Forecasting',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const FrequentOrdersByTagsChart(),
              ],
            ),
          ),
        ),
      ),
      drawer: AdminSidebar(onLogout: _logout),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -10) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.95,
                        child: const PendingOrderNotifications(),
                      );
                    },
                  );
                }
              },
              child: MaterialButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.95,
                        child: const PendingOrderNotifications(),
                      );
                    },
                  );
                },
                color: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pending Orders for Approval',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AdminBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
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
    _updateLastActiveTime();
  }

  Future<void> _updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().toString();
    await prefs.setString('last_active_time', currentTime);
  }
}

class ProductOrder {
  final String productName;
  final int count;

  ProductOrder(this.productName, this.count);
}

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/admin_pages/order_details.dart';

class OrdersManagement extends StatefulWidget {
  const OrdersManagement({super.key});

  @override
  _OrdersManagementState createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // Fetch completed orders from "orders" subcollection
  Stream<List<DocumentSnapshot>> fetchCompletedOrders() {
    return FirebaseFirestore.instance
        .collection('customer')
        .snapshots()
        .asyncMap((snapshot) async {
      List<DocumentSnapshot> orders = [];
      for (var doc in snapshot.docs) {
        var orderSnapshot = await doc.reference.collection('orders').get();
        orders.addAll(orderSnapshot.docs);
      }
      return orders;
    });
  }

  // Fetch cancelled orders from "cancelled" subcollection
  Stream<List<DocumentSnapshot>> fetchCancelledOrders() {
    return FirebaseFirestore.instance
        .collection('customer')
        .snapshots()
        .asyncMap((snapshot) async {
      List<DocumentSnapshot> cancelledOrders = [];
      for (var doc in snapshot.docs) {
        var cancelledSnapshot =
            await doc.reference.collection('cancelled').get();
        cancelledOrders.addAll(cancelledSnapshot.docs);
      }
      return cancelledOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      drawer: AdminSidebar(onLogout: _onLogout),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Orders Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Completed Orders'),
              Tab(text: 'Cancelled Orders'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Completed Orders Tab
                StreamBuilder<List<DocumentSnapshot>>(
                  stream: fetchCompletedOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No completed orders'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var orderData = snapshot.data![index].data()
                            as Map<String, dynamic>;
                        var uid = snapshot.data![index].reference.parent.parent
                            ?.id; // Get the uid of the customer
                        var orderID = snapshot.data![index]
                            .id; // Get the document ID of the order
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text('Order ID: ${orderData['orderID']}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      uid: uid!,
                                      orderID: orderID,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Cancelled Orders Tab
                StreamBuilder<List<DocumentSnapshot>>(
                  stream: fetchCancelledOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No cancelled orders'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var cancelledOrderData = snapshot.data![index].data()
                            as Map<String, dynamic>;
                        var uid = snapshot.data![index].reference.parent.parent
                            ?.id; // Get the uid of the customer
                        var orderID = snapshot.data![index]
                            .id; // Get the document ID of the cancelled order
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text(
                                'Order ID: ${cancelledOrderData['orderID']}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      uid: uid!,
                                      orderID: orderID,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

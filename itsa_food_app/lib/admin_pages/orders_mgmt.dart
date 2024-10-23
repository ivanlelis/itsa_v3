import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';

class OrdersManagement extends StatefulWidget {
  const OrdersManagement({super.key});

  @override
  _OrdersManagementState createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Scaffold key
  int _selectedIndex = 1;

  // Function to handle item taps in the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the scaffold key here
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey), // Pass scaffold key
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Orders Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Add more widgets or functionality for managing orders here
            ElevatedButton(
              onPressed: () {
                // Placeholder action for adding a new order
                print('Add New Order button pressed');
              },
              child: const Text('Add New Order'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Placeholder action for viewing order history
                print('View Order History button pressed');
              },
              child: const Text('View Order History'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Placeholder action for managing orders
                print('Manage Orders button pressed');
              },
              child: const Text('Manage Orders'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex, // Pass the selected index
        onItemTapped: _onItemTapped, // Pass the onItemTapped function
      ), // Add Admin Bottom Nav Bar
    );
  }
}

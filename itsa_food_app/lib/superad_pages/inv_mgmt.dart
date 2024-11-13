import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/superad_navbar.dart';
import 'package:itsa_food_app/main_home/superad_home.dart';
import 'package:itsa_food_app/widgets/raw_stock.dart';
import 'package:itsa_food_app/widgets/products_stock.dart'; // Import the ProductsStock widget

class InvMgmt extends StatefulWidget {
  const InvMgmt({super.key});

  @override
  _InvMgmtState createState() => _InvMgmtState();
}

class _InvMgmtState extends State<InvMgmt> {
  int _selectedIndex = 2;
  String email = 'user@example.com';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      // Stay on Inventory screen
    } else if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return SuperAdminHome(
              email: email,
            );
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Add a scroll view to handle overflow
          child: Column(
            children: [
              RawStock(), // Displays the RawStock widget
              ProductsStock(), // Displays the ProductsStock widget
            ],
          ),
        ),
      ),
      bottomNavigationBar: SuperAdNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

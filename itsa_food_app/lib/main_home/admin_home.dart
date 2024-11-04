import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';

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

  @override
  void initState() {
    super.initState();
    fetchMostOrderedProduct();
  }

  Future<void> fetchMostOrderedProduct() async {
    Map<String, int> productCount = {};

    // Fetch all customers
    QuerySnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('customer').get();

    for (var customerDoc in customerSnapshot.docs) {
      // Fetch each customer's orders
      QuerySnapshot orderSnapshot =
          await customerDoc.reference.collection('orders').get();

      for (var orderDoc in orderSnapshot.docs) {
        List<dynamic> products = orderDoc['productNames'] ?? [];
        for (var product in products) {
          productCount[product] = (productCount[product] ?? 0) + 1;
        }
      }
    }

    // Find the product with the highest count
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final adminEmail = Provider.of<UserProvider>(context).adminEmail;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: _scaffoldKey),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.imageUrl.isNotEmpty
                    ? NetworkImage(widget.imageUrl)
                    : const NetworkImage('https://example.com/placeholder.png'),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${widget.userName}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            ],
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
}

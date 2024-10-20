import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';

class MainHome extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const MainHome({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const Center(child: Text('Menu Page')),
    const Center(child: Text('Favorites Page')),
    const Center(child: Text('User Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openCart() {
    print("Cart opened");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        onCartPressed: _openCart,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      drawer: Drawer(
        child: Sidebar(
          userName: widget.userName,
          email: widget.email,
          imageUrl: widget.imageUrl,
        ),
      ),
    );
  }
}

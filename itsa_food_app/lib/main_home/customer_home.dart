import 'package:flutter/material.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';

class CustomerMainHome extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const CustomerMainHome({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  State<CustomerMainHome> createState() => _CustomerMainHomeState();
}

class _CustomerMainHomeState extends State<CustomerMainHome> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Fetch the current user when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate based on the selected index
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Menu(
            userName: widget.userName,
            email: widget.email,
            imageUrl: widget.imageUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        onCartPressed: () {
          final user =
              Provider.of<UserProvider>(context, listen: false).currentUser;
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainCart(
                  userName: user.userName,
                  email: user.emailAddress,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please log in to access the cart")),
            );
          }
        },
        userName: user?.userName ?? '',
      ),
      body: Center(
        child: user != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Logged in as: ${widget.userName}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Email: ${widget.email}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Text(
                'No user is logged in',
                style: TextStyle(fontSize: 16),
              ),
      ),
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

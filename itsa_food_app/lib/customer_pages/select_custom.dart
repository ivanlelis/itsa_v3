import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/create_combo.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';
import 'package:itsa_food_app/customer_pages/personalize_order.dart'; // Import the new file

class SelectCustom extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? imageUrl;
  final String? uid;
  final String? email;
  final String? userAddress;
  final double latitude;
  final double longitude;
  final String? branchID;

  const SelectCustom({
    super.key,
    this.userName,
    this.emailAddress,
    this.imageUrl,
    this.uid,
    this.email,
    this.userAddress,
    required this.latitude,
    required this.longitude,
    this.branchID,
  });

  @override
  State<SelectCustom> createState() => _SelectCustomState();
}

class _SelectCustomState extends State<SelectCustom> {
  int _selectedIndex = 2; // Default index for "Build Your Meal"

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CustomerMainHome(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
              branchID: widget.branchID,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Menu
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Menu(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
              branchID: widget.branchID,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Build Your Meal
        // Stay on the current page
        break;
      case 3: // User Profile
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfileView(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
              branchID: widget.branchID,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        scaffoldKey:
            GlobalKey<ScaffoldState>(), // Replace with actual scaffoldKey
        onCartPressed: () {
          print('Cart button pressed');
        },
        userName: widget.userName,
        uid: widget.uid,
      ),
      body: Column(
        children: [
          // Row with buttons just below the appBar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120, // Fixed height for both buttons
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComboOrder(
                                userName: widget.userName,
                                emailAddress: widget.emailAddress,
                                imageUrl: widget.imageUrl,
                                uid: widget.uid,
                                email: widget.email,
                                userAddress: widget.userAddress,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                                branchID: widget.branchID,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.brown,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create Combo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 120, // Fixed height for both buttons
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          print("Personalize Order tapped");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalizeOrder(
                                userName: widget.userName,
                                emailAddress: widget.emailAddress,
                                imageUrl: widget.imageUrl,
                                uid: widget.uid,
                                email: widget.email,
                                userAddress: widget.userAddress,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.edit,
                              size: 40,
                              color: Colors.brown,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Personalize Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Add additional content to the body if needed, below the buttons
          Expanded(
            child: Center(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

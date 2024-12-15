import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/customer_pages/select_custom.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itsa_food_app/widgets/featured_products.dart';
import 'package:itsa_food_app/widgets/game_card.dart';
import 'package:itsa_food_app/widgets/trend_product.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';

class CustomerMainHome extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? email;
  final String? imageUrl;
  final String? uid;
  final String? userAddress;
  final double? latitude;
  final double? longitude;
  final String? branchID;

  const CustomerMainHome({
    super.key,
    this.userName,
    this.emailAddress,
    this.email,
    this.imageUrl,
    this.uid,
    this.userAddress,
    this.latitude,
    this.longitude,
    this.branchID,
  });

  @override
  State<CustomerMainHome> createState() => _CustomerMainHomeState();
}

class _CustomerMainHomeState extends State<CustomerMainHome> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DocumentSnapshot> _featuredProduct;

  // Define the color palette
  final Color backgroundColor = const Color(0xFFE1D4C2);
  final Color primaryAccentColor = const Color(0xFF6E473B);
  final Color highlightColor = const Color(0xFFA78D78);
  final Color inputBackgroundColor = const Color(0xFFBEB5A9);
  final Color lightTextColor = const Color(0xFFE1D4C2);
  late bool showLoginButton;

  @override
  void initState() {
    super.initState();
    _updateLastActiveTime();
    _featuredProduct = FirebaseFirestore.instance
        .collection('featured')
        .doc('featured')
        .get(); // Initialize once
    _fetchDataAndUpdateUI();
  }

  Future<bool> _checkOrderStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.uid;
    if (userId != null) {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .where('status', isEqualTo: 'on the way')
          .get();

      return orderSnapshot.docs.isNotEmpty;
    }
    return false;
  }

  Future<void> _fetchDataAndUpdateUI() async {
    await Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
  }

  Future<void> _updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt('lastLoginTime', currentTime);
    print("Last active time updated: $currentTime");
  }

  Future<void> _refreshData() async {
    await _fetchDataAndUpdateUI();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (index == 1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Menu(
            userName: userProvider.currentUser?.userName ?? '',
            emailAddress: userProvider.currentUser?.emailAddress ?? '',
            imageUrl: userProvider.currentUser?.imageUrl ?? '',
            uid: userProvider.currentUser?.uid ?? '',
            email: userProvider.currentUser?.email ?? '',
            userAddress: userProvider.currentUser?.userAddress ?? '',
            latitude: userProvider.currentUser?.latitude ?? 0.0,
            longitude: userProvider.currentUser?.longitude ?? 0.0,
            branchID: widget.branchID,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    if (index == 2) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SelectCustom(
            userName: userProvider.currentUser?.userName ?? '',
            emailAddress: userProvider.currentUser?.emailAddress ?? '',
            imageUrl: userProvider.currentUser?.imageUrl ?? '',
            uid: userProvider.currentUser?.uid ?? '',
            email: userProvider.currentUser?.email ?? '',
            userAddress: userProvider.currentUser?.userAddress ?? '',
            latitude: userProvider.currentUser?.latitude ?? 0.0,
            longitude: userProvider.currentUser?.longitude ?? 0.0,
            branchID: widget.branchID,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    if (index == 3) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProfileView(
            userName: userProvider.currentUser?.userName ?? '',
            emailAddress: userProvider.currentUser?.emailAddress ?? '',
            imageUrl: userProvider.currentUser?.imageUrl ?? '',
            uid: userProvider.currentUser?.uid ?? '',
            email: userProvider.currentUser?.email ?? '',
            userAddress: userProvider.currentUser?.userAddress ?? '',
            latitude: userProvider.currentUser?.latitude ?? 0.0,
            longitude: userProvider.currentUser?.longitude ?? 0.0,
            branchID: widget.branchID,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    showLoginButton = user?.userName == null || user?.emailAddress == null;

    // Get screen height and width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        onCartPressed: () {
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainCart(
                  userName: user.userName,
                  emailAddress: user.emailAddress,
                  uid: user.uid,
                  email: user.email,
                  imageUrl: user.imageUrl,
                  userAddress: user.userAddress,
                  latitude: user.latitude,
                  longitude: user.longitude,
                  branchID: widget.branchID,
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
        uid: user?.uid ?? '',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (user?.userName != null) SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (user?.userName == null) {
                        showDialog(
                          context: context,
                          barrierDismissible:
                              true, // Allows dismissing by tapping outside
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // Adjusts to the content's size
                                  children: [
                                    // Display the image at the top of the modal
                                    Image.asset(
                                      'assets/images/invite.png',
                                      height: 180, // Adjust height as needed
                                      width: 180, // Adjust width as needed
                                    ),

                                    SizedBox(height: 10),
                                    Text(
                                      "Enjoy amazing deals and vouchers so sign up now!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the modal
                                        Navigator.pushNamed(context,
                                            '/login'); // Navigate to login
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                      child: Text(
                                        "Log In / Sign Up",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        // Proceed with Scratch and Win functionality
                        print("Scratch and Win clicked");
                      }
                    },
                    child: AbsorbPointer(
                      absorbing: user?.userName ==
                          null, // Disable interaction if user is not logged in
                      child: GameCard(),
                    ),
                  ),
                  SizedBox(height: 20),
                  FutureBuilder<DocumentSnapshot>(
                    future: _featuredProduct,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(color: highlightColor);
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: lightTextColor),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Text(
                          'No featured product data',
                          style: TextStyle(color: lightTextColor),
                        );
                      }

                      return FeaturedProductWidget(
                        featuredProduct: _featuredProduct,
                        userName: user?.userName ?? '',
                        emailAddress: user?.emailAddress ?? '',
                        email: user?.email ?? '',
                        imageUrl: user?.imageUrl ?? '',
                        uid: user?.uid ?? '',
                        userAddress: user?.userAddress ?? '',
                        latitude: user?.latitude ?? 0.0,
                        longitude: user?.longitude ?? 0.0,
                        branchID: widget.branchID,
                      );
                    },
                  ),
                  SizedBox(height: 15),
                  TrendProduct(
                    userName: user?.userName ?? '',
                    emailAddress: user?.emailAddress ?? '',
                    email: user?.email ?? '',
                    imageUrl: user?.imageUrl ?? '',
                    uid: user?.uid ?? '',
                    userAddress: user?.userAddress ?? '',
                    latitude: user?.latitude ?? 0.0,
                    longitude: user?.longitude ?? 0.0,
                    branchID: widget.branchID,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (showLoginButton)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  1, // Small gap from BottomNavBar
              left: screenWidth * 0.05, // 5% padding from the left
              right: screenWidth * 0.05, // 5% padding from the right
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(8), // Same radius as button
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8), // Glow color
                      blurRadius: 20, // Spread of the glow
                      spreadRadius: 2, // Intensity of the glow
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to login/sign-up screen
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: primaryAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Reduced border radius
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Log In or Sign Up to Start Ordering!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      drawer: Drawer(
        child: Container(
          child: Sidebar(
            userName: user?.userName ?? '',
            emailAddress: user?.emailAddress ?? '',
            imageUrl: user?.imageUrl ?? '',
            uid: user?.uid ?? '',
            latitude: user?.latitude ?? 0.0,
            longitude: user?.longitude ?? 0.0,
            email: user?.email ?? '',
            userAddress: user?.userAddress ?? '',
          ),
        ),
      ),
    );
  }
}

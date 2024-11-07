import 'package:flutter/material.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';
import 'package:itsa_food_app/customer_pages/menu.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerMainHome extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;

  const CustomerMainHome({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.imageUrl,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CustomerMainHome> createState() => _CustomerMainHomeState();
}

class _CustomerMainHomeState extends State<CustomerMainHome> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _updateLastActiveTime();
  }

  Future<void> _updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt('lastLoginTime',
        currentTime); // Store current time in SharedPreferences
    print("Last active time updated: $currentTime");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDataAndUpdateUI();
  }

  Future<void> _fetchDataAndUpdateUI() async {
    await Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
    setState(() {}); // Update the UI after fetching data
  }

  Future<void> _refreshData() async {
    await _fetchDataAndUpdateUI();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Navigate based on the selected index
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

    return Scaffold(
      key: _scaffoldKey,
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: user != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logged in as: ${user.userName}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Email: ${user.emailAddress}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Address: ${user.userAddress}',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        Text(
                          'Latitude: ${user.latitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        Text(
                          'Longitude: ${user.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    )
                  : Text(
                      'No user is logged in',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      drawer: Drawer(
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
    );
  }
}

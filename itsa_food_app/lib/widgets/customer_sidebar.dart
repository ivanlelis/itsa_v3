import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Ensure you import the provider package
import 'package:itsa_food_app/user_provider/user_provider.dart'; // Import your UserProvider

class Sidebar extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String userAddress;
  final String imageUrl;
  final String uid;
  final double latitude;
  final double longitude;

  const Sidebar({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.userAddress,
    required this.imageUrl,
    required this.uid,
    required this.latitude,
    required this.longitude,
  });

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  void initState() {
    super.initState();
    // Fetch user data when the Sidebar is initialized
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider
        .fetchCurrentUser(); // Call your method to fetch user data
  }

  @override
  Widget build(BuildContext context) {
    // Access the UserProvider to get the current user
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    // Check if the current user is available
    if (currentUser == null) {
      return const Center(
          child:
              CircularProgressIndicator()); // Show a loading indicator or handle the case when the user is not available
    }

    const customColor = Color(0xFF6E473B); // Define your custom color

    return Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            currentUser.userName,
            style: const TextStyle(color: Colors.white),
          ),
          accountEmail: Text(
            currentUser.emailAddress,
            style: const TextStyle(color: Colors.white70),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundImage: currentUser.imageUrl.isNotEmpty
                ? NetworkImage(currentUser.imageUrl)
                : const NetworkImage('https://example.com/placeholder.png'),
          ),
          decoration: const BoxDecoration(
            color: customColor, // Change the header background to your color
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildSidebarItem(
                context,
                icon: Icons.history,
                title: 'Order History',
                customColor: customColor,
                onTap: () {
                  final args = _buildArguments();
                  Navigator.pushNamed(context, '/orderHistory',
                      arguments: args);
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.person,
                title: 'Profile',
                customColor: customColor,
                onTap: () {
                  final args = _buildArguments(includeEmail: true);
                  Navigator.pushNamed(context, '/profile', arguments: args);
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.location_on,
                title: 'Address',
                customColor: customColor,
                onTap: () {
                  final args = _buildArguments();
                  Navigator.pushNamed(context, '/address', arguments: args);
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.card_giftcard,
                title: 'Vouchers',
                customColor: customColor,
                onTap: () {
                  final args = _buildArguments();
                  Navigator.pushNamed(context, '/vouchers', arguments: args);
                },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.contact_mail,
                title: 'Contact Us',
                customColor: customColor,
                onTap: () {
                  Navigator.pushNamed(context, '/contactUs');
                },
              ),
              const Divider(),
              _buildSidebarItem(
                context,
                icon: Icons.logout,
                title: 'Log Out',
                customColor: customColor,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(BuildContext context,
      {required IconData icon,
      required String title,
      required Color customColor,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: customColor), // Apply your color to the icons
      title: Text(
        title,
        style: TextStyle(color: customColor), // Apply your color to the text
      ),
      onTap: onTap,
    );
  }

  Map<String, dynamic> _buildArguments({bool includeEmail = false}) {
    return {
      'emailAddress': widget.emailAddress,
      'userName': widget.userName,
      'email': includeEmail ? widget.email : null,
      'userAddress': widget.userAddress,
      'uid': widget.uid,
      'latitude': widget.latitude,
      'longitude': widget.longitude,
      'imageUrl': widget.imageUrl,
    };
  }
}

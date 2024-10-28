import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Ensure you import the provider package
import 'package:itsa_food_app/user_provider/user_provider.dart'; // Import your UserProvider

class Sidebar extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String imageUrl;

  const Sidebar({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.imageUrl,
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

    return Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(currentUser.userName),
          accountEmail: Text(currentUser.emailAddress),
          currentAccountPicture: CircleAvatar(
            backgroundImage: currentUser.imageUrl.isNotEmpty
                ? NetworkImage(currentUser
                    .imageUrl) // Use the imageUrl from the current user
                : const NetworkImage(
                    'https://example.com/placeholder.png'), // Use your placeholder image URL
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Order History'),
          onTap: () {
            // Navigate to Order History page
            Navigator.pushNamed(context, '/orderHistory');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {
            // Navigate to Profile page
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Address'),
          onTap: () {
            // Navigate to Address page
            Navigator.pushNamed(context, '/address');
          },
        ),
        ListTile(
          leading: const Icon(Icons.card_giftcard),
          title: const Text('Vouchers'),
          onTap: () {
            // Navigate to Vouchers page
            Navigator.pushNamed(context, '/vouchers');
          },
        ),
        ListTile(
          leading: const Icon(Icons.contact_mail),
          title: const Text('Contact Us'),
          onTap: () {
            // Navigate to Contact Us page
            Navigator.pushNamed(context, '/contactUs');
          },
        ),
        const Divider(), // Adds a divider line between sections
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            // Navigate back to Home page and clear all previous routes
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      ],
    );
  }
}

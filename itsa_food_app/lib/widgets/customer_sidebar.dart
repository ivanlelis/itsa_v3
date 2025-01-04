import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';

class Sidebar extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? email;
  final String? userAddress;
  final String? imageUrl;
  final String? uid;
  final double latitude;
  final double longitude;

  const Sidebar({
    super.key,
    this.userName,
    this.emailAddress,
    this.email,
    this.userAddress,
    this.imageUrl,
    this.uid,
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
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    final displayName = currentUser?.userName ?? 'Guest';
    final displayEmail = currentUser?.emailAddress ?? 'guest@example.com';
    final displayImageUrl =
        (currentUser != null && currentUser.imageUrl?.isNotEmpty == true)
            ? currentUser.imageUrl!
            : 'https://example.com/placeholder.png';

    const customColor = Color(0xFF6E473B);
    const disabledColor = Colors.grey;

    return Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            displayName,
            style: const TextStyle(color: Colors.white),
          ),
          accountEmail: Text(
            displayEmail,
            style: const TextStyle(color: Colors.white70),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundImage: NetworkImage(displayImageUrl),
          ),
          decoration: const BoxDecoration(
            color: customColor,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildSidebarItem(
                context,
                icon: Icons.history,
                title: 'Order History',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        final args = _buildArguments();
                        Navigator.pushNamed(context, '/orderHistory',
                            arguments: args);
                      },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.person,
                title: 'Profile',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        final args = _buildArguments(includeEmail: true);
                        Navigator.pushNamed(context, '/profile',
                            arguments: args);
                      },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.location_on,
                title: 'Address',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        final args = _buildArguments();
                        Navigator.pushNamed(context, '/address',
                            arguments: args);
                      },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.card_giftcard,
                title: 'Vouchers',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        final args = _buildArguments();
                        Navigator.pushNamed(context, '/vouchers',
                            arguments: args);
                      },
              ),
              // Add the Redeem Rewards item here
              _buildSidebarItem(
                context,
                icon: Icons.loyalty,
                title: 'Redeem Rewards',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/redeemRewards');
                      },
              ),
              _buildSidebarItem(
                context,
                icon: Icons.contact_mail,
                title: 'Contact Us',
                customColor: currentUser == null ? disabledColor : customColor,
                onTap: currentUser == null
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/contactUs');
                      },
              ),
              const Divider(),
              _buildSidebarItem(
                context,
                icon: currentUser == null ? Icons.login : Icons.logout,
                title: currentUser == null ? 'Login or Signup' : 'Log Out',
                customColor: customColor,
                onTap: currentUser == null
                    ? () {
                        Navigator.pushNamed(context, '/loginSignup');
                      }
                    : () async {
                        await FirebaseAuth.instance.signOut();

                        // Clear the current user in the UserProvider
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        userProvider.clearCurrentUser();

                        // Redirect to home and remove all previous routes
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
      required VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: customColor),
      title: Text(
        title,
        style: TextStyle(color: customColor),
      ),
      onTap: onTap,
      enabled: onTap != null,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:itsa_food_app/widgets/admin_appbar.dart'; // Import AdminAppBar
import 'package:itsa_food_app/widgets/admin_navbar.dart'; // Import AdminBottomNavBar
import 'package:itsa_food_app/widgets/admin_sidebar.dart'; // Import AdminSidebar
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for logout

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>(); // Scaffold key
  int _selectedIndex = 3; // Set the selected index to 3 for 'Users'

  Future<List<Map<String, dynamic>>>? _userListFuture; // Define _userListFuture

  @override
  void initState() {
    super.initState();
    // Automatically load customers when the page first displays
    _userListFuture = _loadUsers('customer');
  }

  // Handle tapping on the bottom nav bar items
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to load users based on the userType
  Future<List<Map<String, dynamic>>> _loadUsers(String userType) async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(userType).get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Function to handle logout
  void _onLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/home'); // Redirect to home.dart after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: scaffoldKey),
      drawer: AdminSidebar(
        onLogout: _onLogout, // Pass the _onLogout function to AdminSidebar
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userListFuture =
                            _loadUsers('customer'); // Load customers
                      });
                    },
                    child: const Text('Customers'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userListFuture = _loadUsers('rider'); // Load riders
                      });
                    },
                    child: const Text('Riders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _userListFuture, // Use the Future variable for the list
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  } else {
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(user['userName'] ?? 'No Name'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Placeholder for view action
                                // You can define a function or display a message for now
                                print(
                                    "View button clicked for ${user['userName']}");
                              },
                              child: const Text("View"),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

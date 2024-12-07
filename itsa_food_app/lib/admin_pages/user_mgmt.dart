import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/widgets/admin_appbar.dart';
import 'package:itsa_food_app/widgets/admin_navbar.dart';
import 'package:itsa_food_app/widgets/admin_sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itsa_food_app/admin_pages/view_user.dart';

class UserManagement extends StatefulWidget {
  final String userName;
  const UserManagement({super.key, required this.userName});

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<List<Map<String, dynamic>>> _loadUsers(String userType) async {
    String branchID = "";
    if (widget.userName == "Main Branch Admin") {
      branchID = "branch 1";
    } else if (widget.userName == "Sta. Cruz II Admin") {
      branchID = "branch 2";
    } else if (widget.userName == "San Dionisio Admin") {
      branchID = "branch 3";
    }

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(userType)
        .where('branchID', isEqualTo: branchID)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  void _onLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AdminAppBar(scaffoldKey: scaffoldKey),
      drawer: AdminSidebar(
        onLogout: _onLogout,
        userName: widget.userName,
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
                        _userListFuture = _loadUsers('customer');
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
                        _userListFuture = _loadUsers('rider');
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
                future: _userListFuture,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewUser(
                                      userName: user['userName'] ?? 'No Name',
                                    ),
                                  ),
                                );
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
        userName: widget.userName,
      ),
    );
  }
}

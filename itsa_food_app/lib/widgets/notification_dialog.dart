import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void showNotificationDialog(BuildContext context, String branchID,
    Function(void Function()) setState, Map<String, String>? selectedOrder, Null Function(dynamic newSelectedOrder) param4) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "Orders",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('customer')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final customerDocs = snapshot.data?.docs ?? [];

                  if (customerDocs.isEmpty) {
                    return Center(child: Text("No notifications available"));
                  }

                  return ListView(
                    children: customerDocs.map((customerDoc) {
                      final firstName = customerDoc['firstName'];
                      final lastName = customerDoc['lastName'];
                      final customerUid = customerDoc.id;

                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('customer')
                            .doc(customerUid)
                            .collection('orders')
                            .where('branchID', isEqualTo: branchID)
                            .where('status', isEqualTo: 'approved')
                            .get(),
                        builder: (context,
                            AsyncSnapshot<QuerySnapshot> orderSnapshot) {
                          if (orderSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (orderSnapshot.hasError) {
                            return Center(
                                child: Text('Error: ${orderSnapshot.error}'));
                          }

                          final orders = orderSnapshot.data?.docs ?? [];

                          return Column(
                            children: orders.map((orderDoc) {
                              final orderID = orderDoc.id;
                              final userAddress = (orderDoc.data()
                                      as Map<String, dynamic>)['userAddress'] ??
                                  'No address provided';

                              return Card(
                                elevation: 8,
                                margin: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Order ID: $orderID"),
                                      Text("Customer: $firstName $lastName"),
                                      Text("Address: $userAddress"),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('customer')
                                              .doc(customerUid)
                                              .collection('orders')
                                              .doc(orderID)
                                              .update({'status': 'on the way'});

                                          setState(() {
                                            selectedOrder = {
                                              'orderID': orderID,
                                              'firstName': firstName,
                                              'lastName': lastName,
                                              'userAddress': userAddress,
                                            };
                                          });

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Started delivery for Order ID: $orderID'),
                                            ),
                                          );
                                        },
                                        child: Text("Start Delivery"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

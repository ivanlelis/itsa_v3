import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for date formatting

class WeeklySales extends StatefulWidget {
  @override
  _WeeklySalesState createState() => _WeeklySalesState();
}

class _WeeklySalesState extends State<WeeklySales> {
  Future<List<Map<String, dynamic>>> fetchDailySales() async {
    List<Map<String, dynamic>> salesData = [];

    try {
      // Get the current date
      DateTime now = DateTime.now();

      // Iterate over the week to construct the dynamic collection names
      for (int i = 0; i < 7; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String collectionName =
            "transactions_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${date.year.toString().substring(2)}";

        // Debug: Log the collection name being checked
        print("Checking for collection: $collectionName");

        // Fetch the dailySales document inside the corresponding collection
        var snapshot = await FirebaseFirestore.instance
            .collection('transactions') // Root collection
            .doc('transactions') // Nested document
            .collection(collectionName) // Subcollection for the specific date
            .doc('dailySales') // Document inside the collection
            .get();

        if (snapshot.exists) {
          // If document exists, extract data from it and add to the list
          Map<String, dynamic> sales = snapshot.data()!;
          print("Sales data found for $collectionName: $sales");

          // Extract the date from the collection name
          // Collection name is "transactions_MM_DD_YY"
          List<String> dateParts = collectionName.split('_');
          String formattedDate =
              '${dateParts[1]}-${dateParts[2]}-${dateParts[3]}'; // Format as MM-DD-YY

          // Convert the date string to DateTime
          List<String> dateSplit = formattedDate.split('-');
          DateTime dateTime = DateTime(
            2000 + int.parse(dateSplit[2]), // Year
            int.parse(dateSplit[0]), // Month
            int.parse(dateSplit[1]), // Day
          );

          // Format the date to the desired format: "Month Day, Year"
          String readableDate = DateFormat('MMMM dd, yyyy').format(dateTime);

          salesData.add({
            'date': readableDate, // Storing the formatted date
            'sales': sales, // Storing the sales data
          });
        } else {
          // If document does not exist, log and continue
          print("No sales data found for $collectionName");
        }
      }
    } catch (e) {
      print("Error fetching sales data: $e");
    }

    return salesData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Sales Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Data for the Week',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDailySales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error fetching sales data.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No sales data found.'));
                  } else {
                    final salesData = snapshot.data!;
                    return ListView.builder(
                      itemCount: salesData.length,
                      itemBuilder: (context, index) {
                        final sales = salesData[index];
                        return ListTile(
                          title: Text(
                              'Date: ${sales['date']}'), // Display the formatted date
                          subtitle: Text('Sales: ${sales['sales']}'),
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
    );
  }
}

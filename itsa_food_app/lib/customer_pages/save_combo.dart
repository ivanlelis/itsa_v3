import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class SaveCombo extends StatefulWidget {
  final String? selectedProductID;
  final String? selectedMilkTeaID;
  final String? branchID;
  final String? userName;
  final String? emailAddress;
  final String? imageUrl;
  final String? uid;
  final String? email;
  final String? userAddress;
  final double latitude;
  final double longitude;

  const SaveCombo({
    super.key,
    this.selectedProductID,
    this.selectedMilkTeaID,
    this.branchID,
    this.userName,
    this.userAddress,
    this.email,
    this.emailAddress,
    this.uid,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  @override
  _SaveComboState createState() => _SaveComboState();
}

class _SaveComboState extends State<SaveCombo> {
  final TextEditingController comboNameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> tags = [];

  // For visibility selection (Private or Public)
  String visibility = 'Private'; // Default visibility

  String generateComboID() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random rand = Random();
    String comboID = '';
    for (int i = 0; i < 6; i++) {
      comboID += chars[rand.nextInt(chars.length)];
    }
    return comboID;
  }

  // Fetch product name and imageUrl by ID based on branchID from Firestore
  Future<Map<String, String>> fetchProductDetails(String? productID) async {
    if (productID == null) {
      return {'productName': 'Unknown Product', 'imageUrl': ''};
    }

    // Reference to the Firestore collection based on the branchID
    String collectionName = '';

    // Set collection name based on branchID
    if (widget.branchID == "branch 1") {
      collectionName = "products";
    } else if (widget.branchID == "branch 2") {
      collectionName = "products_branch1";
    } else if (widget.branchID == "branch 3") {
      collectionName = "products_branch2";
    } else {
      throw Exception('Invalid branch ID');
    }

    // Fetch the document based on the productID
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(productID)
        .get();

    if (snapshot.exists) {
      // Return product name and imageUrl from the document
      return {
        'productName': snapshot['productName'] ?? 'Unknown Product',
        'imageUrl': snapshot['imageUrl'] ?? '',
      };
    } else {
      return {
        'productName': 'Unknown Product',
        'imageUrl': ''
      }; // In case productID does not exist
    }
  }

  // Method to handle adding tags when space or enter is pressed
  void handleTagInput(String value) {
    if (value.trim().isEmpty) return; // Ignore empty input

    // Split the input value when space or enter is pressed
    List<String> newTags = value.trim().split(RegExp(r'\s+'));

    // If tags exceed 3, ignore the extra
    if (tags.length + newTags.length > 3) {
      newTags = newTags.sublist(0, 3 - tags.length); // Limit to 3 tags
    }

    setState(() {
      tags.addAll(newTags);
      tagController.clear(); // Clear the input field after adding tags
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6E473B),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
      ),
      body: SingleChildScrollView(
        // Wrap the body content with a SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Combo Details:",
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // Responsive spacing
              // FutureBuilder to fetch product details for selectedProductID and selectedMilkTeaID
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align all items at the top
                children: [
                  // Left Card for selected Product
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: fetchProductDetails(widget.selectedProductID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('Error: No product details');
                        } else {
                          final product = snapshot.data!;
                          return Column(
                            children: [
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded corners
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      8), // Match the card radius
                                  child: Image.network(
                                    product['imageUrl']!,
                                    fit: BoxFit.cover,
                                    height: screenHeight *
                                        0.2, // Consistent image height
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01), // Spacing
                              Container(
                                alignment: Alignment.center, // Center the text
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02),
                                child: Text(
                                  product['productName']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.045, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04), // Responsive spacing
                  // Right Card for selected Milk Tea
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: fetchProductDetails(widget.selectedMilkTeaID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('Error: No product details');
                        } else {
                          final product = snapshot.data!;
                          return Column(
                            children: [
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded corners
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      8), // Match the card radius
                                  child: Image.network(
                                    product['imageUrl']!,
                                    fit: BoxFit.cover,
                                    height: screenHeight *
                                        0.2, // Consistent image height
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01), // Spacing
                              Container(
                                alignment: Alignment.center, // Center the text
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02),
                                child: Text(
                                  product['productName']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.045, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height:
                      screenHeight * 0.03), // Spacing below the product cards
              // Combo Name TextField
              TextField(
                controller: comboNameController,
                decoration: InputDecoration(
                  hintText: "Combo Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ), // Padding inside the text field
                ),
                style: TextStyle(
                  fontSize: screenWidth * 0.045, // Responsive font size
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // Spacing between fields
              // Tag Input TextField
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  hintText: "Add Tags (max 3)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                ),
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                ),
                onChanged: (value) {
                  // Handle the space or enter input
                  if (value.contains(RegExp(r'\s|\n'))) {
                    handleTagInput(value);
                  }
                },
                onSubmitted: (value) {
                  handleTagInput(value); // When enter is pressed
                },
              ),
              SizedBox(height: screenHeight * 0.02), // Spacing between fields

              // Display Tags
              Wrap(
                spacing: 5.0,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: Icon(Icons.close),
                        onDeleted: () {
                          setState(() {
                            tags.remove(tag);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              SizedBox(
                width: double
                    .infinity, // Make the dropdown as wide as the other fields
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: "Visibility",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.003,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: visibility,
                    onChanged: (String? newValue) {
                      setState(() {
                        visibility = newValue!;
                      });
                    },
                    isExpanded:
                        true, // Ensure the dropdown button takes up the full width
                    items: [
                      DropdownMenuItem(
                        value: 'Private',
                        child: Row(
                          children: [
                            Icon(Icons.lock),
                            SizedBox(width: 8),
                            Text('Private'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Public',
                        child: Row(
                          children: [
                            Icon(Icons.public),
                            SizedBox(width: 8),
                            Text('Public'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "Enter a description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.040,
                  ),
                ),
                style: TextStyle(
                  fontSize: screenWidth * 0.045, // Responsive font size
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // Spacing between fields
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: SizedBox(
          width: double.infinity,
          height: screenHeight * 0.08, // Large button height
          child: ElevatedButton(
            onPressed: () async {
              // Generate a comboID
              String comboID = generateComboID();

              try {
                // Reference to the current user's document inside "customer" collection
                DocumentReference userDocRef = FirebaseFirestore.instance
                    .collection('customer')
                    .doc(widget
                        .uid); // Get the current user's UID from the widget

                // Fetch product details for selectedProductID and selectedMilkTeaID
                Map<String, String> productDetails =
                    await fetchProductDetails(widget.selectedProductID);
                Map<String, String> milkTeaDetails =
                    await fetchProductDetails(widget.selectedMilkTeaID);

                // Get the current local time in Philippine time zone (UTC+8)
                final now = DateTime.now();
                final philippinesTime = now.toUtc().add(Duration(hours: 8));
                final formattedTimestamp =
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(philippinesTime);

                // Add combo details with product names in the same document
                await userDocRef.collection('combos').doc(comboID).set({
                  'comboID': comboID,
                  'comboName': comboNameController.text,
                  'tags': tags,
                  'description': descriptionController.text,
                  'visibility': visibility,
                  'productName1':
                      productDetails['productName'], // First product name
                  'productName2':
                      milkTeaDetails['productName'], // Second product name
                  'createdAt':
                      formattedTimestamp, // Save timestamp in local PH time
                });

                // Optionally, show a success message or pop the screen
                Navigator.pop(context);
              } catch (e) {
                // Handle any errors during the save process
                print("Error saving combo: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded button
              ),
              backgroundColor: Color(0xFF6E473B), // Updated button color
            ),
            child: Text(
              "Save Combo",
              style: TextStyle(
                fontSize: screenWidth * 0.05, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color set to white
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PersonalizeOrder extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? imageUrl;
  final String? uid;
  final String? email;
  final String? userAddress;
  final double latitude;
  final double longitude;

  const PersonalizeOrder({
    super.key,
    this.userName,
    this.emailAddress,
    this.imageUrl,
    this.uid,
    this.email,
    this.userAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  _PersonalizeOrderState createState() => _PersonalizeOrderState();
}

class _PersonalizeOrderState extends State<PersonalizeOrder> {
  String mainProduct = '';
  String productImageUrl = '';
  String selectedOption = '';
  List<String> leftOptions = [
    '40% sugar',
    '60% sugar',
    '80% sugar',
    '90% sugar'
  ];
  List<String> rightOptions = [
    'Less ice',
    'Additional pearls',
    'More nata de coco',
    'More coffee jelly'
  ];

  Future<void> _selectProduct() async {
    // Fetch product names and images from Firestore
    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    // Change to List<Map<String, dynamic>> or cast the values explicitly
    List<Map<String, String>> products = snapshot.docs.map((doc) {
      return {
        'productName': doc['productName'] as String,
        'imageUrl': doc['imageUrl'] as String,
      };
    }).toList();

    // Show the list of products in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select a Product"),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(products[index]['productName']!),
                  onTap: () {
                    setState(() {
                      mainProduct = products[index]['productName']!;
                      productImageUrl = products[index]['imageUrl']!;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Personalize Order")),
      body: SafeArea(
        child: Column(
          children: [
            // Header text
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Personalizing order for: ${widget.userName}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Product selection and customization row
            Expanded(
              child: Column(
                children: [
                  // Select a product button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _selectProduct,
                      child: Text(
                        mainProduct.isEmpty ? 'Select a Product' : mainProduct,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  // Row layout: food in center with options on both sides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left options (4 cards)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: leftOptions.map((option) {
                              return Draggable<String>(
                                data: option,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(option),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Card(
                                  color: Colors.grey[300],
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(option),
                                  ),
                                ),
                                child: Card(
                                  elevation: 4.0,
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Central product (Milk Tea or selected product)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width:
                              screenWidth * 0.4, // Make the central product fit
                          child: DragTarget<String>(
                            onAcceptWithDetails:
                                (DragTargetDetails<String> details) {
                              setState(() {
                                selectedOption =
                                    details.data; // Extract the string data
                                mainProduct =
                                    '$mainProduct with ${details.data}';
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Card(
                                color: Colors.blueAccent,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // Display image of the selected product
                                      productImageUrl.isNotEmpty
                                          ? Image.network(
                                              productImageUrl,
                                              height: screenWidth *
                                                  0.25, // Image size adjusted
                                              width: screenWidth * 0.25,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(), // Empty container if no product selected
                                      const SizedBox(height: 8),
                                      Text(
                                        mainProduct.isEmpty
                                            ? 'Select a Product'
                                            : mainProduct,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (selectedOption.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Customizations: $selectedOption',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Right options (4 cards)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: rightOptions.map((option) {
                              return Draggable<String>(
                                data: option,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(option),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Card(
                                  color: Colors.grey[300],
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(option),
                                  ),
                                ),
                                child: Card(
                                  elevation: 4.0,
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

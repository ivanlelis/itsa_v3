import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  String mainProduct = 'Choose Product';
  String productImageUrl = '';
  List<Map<String, String>> products = [];
  String? selectedProduct;
  bool isLoading = true;

  // Track selected options
  List<String> selectedOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .get();

      if (!customerDoc.exists || !customerDoc.data()!.containsKey('branchID')) {
        throw Exception("Branch ID not found for this customer");
      }

      String branchID = customerDoc['branchID'];

      String productCollection;
      if (branchID == "branch 1") {
        productCollection = 'products';
      } else if (branchID == "branch 2") {
        productCollection = 'products_branch1';
      } else if (branchID == "branch 3") {
        productCollection = 'products_branch2';
      } else {
        throw Exception("Invalid branch ID");
      }

      final productSnapshot =
          await FirebaseFirestore.instance.collection(productCollection).get();

      products = productSnapshot.docs.map((doc) {
        return {
          'productName': doc['productName']?.toString() ?? 'Unnamed Product',
          'imageUrl': doc['imageUrl']?.toString() ?? '',
          'productType': doc['productType']?.toString() ?? '',
        };
      }).toList();

      setState(() {
        isLoading = false;
        if (products.isNotEmpty) {
          mainProduct = 'Choose Product';
        } else {
          mainProduct = 'No Products Available';
        }
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        mainProduct = 'Error Loading Products';
      });
      print("Error fetching products: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final selectedProductType = selectedProduct != null
        ? products.firstWhere(
            (p) => p['productName'] == selectedProduct)['productType']
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar with back button and info icon
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.info_outline, color: Colors.black),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image with shadow and rounded corners
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              productImageUrl.isNotEmpty
                                  ? productImageUrl
                                  : 'https://via.placeholder.com/300',
                              height: screenWidth * 0.6,
                              width: screenWidth * 0.6,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown for product selection
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              child: DropdownButtonFormField<String>(
                                value: selectedProduct,
                                items: products.map((product) {
                                  return DropdownMenuItem<String>(
                                    value: product['productName'],
                                    child: Text(
                                      product['productName']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    // Update the selected product and related fields
                                    selectedProduct = value;
                                    mainProduct = value ?? 'Choose Product';
                                    productImageUrl = products.firstWhere((p) =>
                                        p['productName'] == value)['imageUrl']!;

                                    // Reset the selected options when the product type changes
                                    selectedOptions.clear();
                                  });
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  labelText: 'Select Product',
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 12.0,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                      // Customization section
                      if (selectedProductType != null)
                        _buildCustomizationCards(selectedProductType),
                    ],
                  ),
                ),
              ),
            ),

            // Buy Now Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (selectedOptions.isEmpty) {
                    // Show dialog if no options are selected
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('No Options Selected'),
                          content: const Text(
                              'Please choose at least one option before proceeding.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Proceed with Buy Now action
                    // Your logic here
                    print('Proceeding with selected options: $selectedOptions');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E0B0D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOption(String option, String productType) {
    setState(() {
      // Ensure single selection for sugar options
      if (productType == "Milk Tea" &&
          ["25% Sugar", "50% Sugar", "75% Sugar", "100% Sugar"]
              .contains(option)) {
        if (selectedOptions.contains(option)) {
          selectedOptions.remove(option); // Deselect if already selected
        } else {
          // Remove other sugar options and select the new one
          selectedOptions.removeWhere((opt) => [
                "25% Sugar",
                "50% Sugar",
                "75% Sugar",
                "100% Sugar"
              ].contains(opt));
          selectedOptions.add(option);
        }
      }
      // Ensure single selection for veggie options
      else if (productType == "Takoyaki" &&
          ["No Veggies", "Less Veggies", "With Veggies"].contains(option)) {
        if (selectedOptions.contains(option)) {
          selectedOptions.remove(option); // Deselect if already selected
        } else {
          // Remove other veggie options and select the new one
          selectedOptions.removeWhere((opt) =>
              ["No Veggies", "Less Veggies", "With Veggies"].contains(opt));
          selectedOptions.add(option);
        }
      } else {
        // Allow multiple selections for other options
        if (selectedOptions.contains(option)) {
          selectedOptions.remove(option);
        } else {
          selectedOptions.add(option);
        }
      }
    });
  }

  Widget _buildCustomizationCards(String productType) {
    List<String> options = [];

    if (productType == "Milk Tea") {
      options = [
        "25% Sugar",
        "50% Sugar",
        "75% Sugar",
        "100% Sugar",
        "Less Ice",
        "More Pearls"
      ];
    } else if (productType == "Takoyaki") {
      options = [
        "No Veggies",
        "Less Veggies",
        "With Veggies",
        "No Mayo",
        "No Dried Seaweed",
        "No Bonito Flakes"
      ];
    } else if (productType == "Meals") {
      options = ["Add Rice", "Chili Flakes", "Soy Sauce"];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            "Customize Your Order",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Carousel for options
        CarouselSlider(
          options: CarouselOptions(
            height: 150,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            autoPlay: false,
          ),
          items: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  selectedOptions.remove(option);
                } else {
                  selectedOptions.add(option);
                }
              }),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                color: isSelected
                    ? Colors.greenAccent.withOpacity(0.7)
                    : Colors.white,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Display selected options
        const Text(
          "Selected Customizations:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Wrap(
          spacing: 8,
          children: selectedOptions
              .map((option) => Chip(
                    label: Text(option),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() {
                      selectedOptions.remove(option);
                    }),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

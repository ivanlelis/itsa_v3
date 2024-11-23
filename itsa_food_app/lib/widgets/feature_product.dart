import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feature_modal.dart';


class FeatureProduct extends StatefulWidget {
  const FeatureProduct({super.key});

  @override
  State<FeatureProduct> createState() => _FeatureProductState();
}

class _FeatureProductState extends State<FeatureProduct> {
  final Map<String, int> productCount = {};
  String? mostOrderedProduct;
  List<String> allProducts = [];
  String? selectedProduct;
  bool isLoading = true;
  String? mostOrderedProductImageUrl;

  @override
  void initState() {
    super.initState();
    fetchMostOrderedProduct();
  }

  Future<void> fetchMostOrderedProduct() async {
    try {
      setState(() => isLoading = true);
      productCount.clear();

      // Fetch customers and orders
      QuerySnapshot customerSnapshot =
          await FirebaseFirestore.instance.collection('customer').get();

      for (var customerDoc in customerSnapshot.docs) {
        QuerySnapshot orderSnapshot =
            await customerDoc.reference.collection('orders').get();

        for (var orderDoc in orderSnapshot.docs) {
          List<dynamic> products = orderDoc['productNames'] ?? [];
          for (var product in products) {
            productCount[product] = (productCount[product] ?? 0) + 1;
          }
        }
      }

      // Find the most ordered product
      String? mostOrdered;
      int maxCount = 0;
      productCount.forEach((product, count) {
        if (count > maxCount) {
          mostOrdered = product;
          maxCount = count;
        }
      });

      // Fetch the product with the most ordered product name
      String? imageUrl;
      if (mostOrdered != null) {
        QuerySnapshot productSnapshot =
            await FirebaseFirestore.instance.collection('products').get();

        for (var productDoc in productSnapshot.docs) {
          if (productDoc['productName'] == mostOrdered) {
            imageUrl = productDoc['imageUrl']; // Extract the imageUrl field
            break; // Exit the loop once a match is found
          }
        }
      }

      QuerySnapshot productSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      allProducts = productSnapshot.docs
          .map((doc) => doc['productName'].toString())
          .toList();

      setState(() {
        mostOrderedProduct = mostOrdered;
        isLoading = false;
      });

      // Set state with the fetched data
      setState(() {
        mostOrderedProduct = mostOrdered;
        mostOrderedProductImageUrl = imageUrl; // Store the imageUrl here
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void featureProduct(String product) async {
    try {
      await FirebaseFirestore.instance
          .collection('featured')
          .doc('currentFeatured')
          .set({'featuredProduct': product});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "$product" is now featured!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error featuring product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Feature a Product",
          style: TextStyle(color: Color(0xFFE1D4C2)),
        ),
        backgroundColor: const Color(0xFF291C0E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFFAF3E0), // Dirty white color for background
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF291C0E),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),

                    // Most Ordered Product Card
                    if (mostOrderedProduct != null)
                      Card(
                        color: const Color(
                            0xFFE1D4C2), // Dirty white background for card
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Most Ordered Product",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6E473B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mostOrderedProduct!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF291C0E),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Display the image if the imageUrl is not null with border radius
                              if (mostOrderedProductImageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        16), // Apply border radius
                                    child: Image.network(
                                      mostOrderedProductImageUrl!,
                                      height: 200, // Adjust as needed
                                      width: double.infinity,
                                      fit: BoxFit
                                          .cover, // Adjust to maintain aspect ratio
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Row to position buttons at bottom left and bottom right
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Modify Feature Button (bottom left)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Trigger the feature modal when the modify button is clicked
                                      FeatureProductModal.showFeatureModal(
                                          context);
                                    },
                                    icon: const Icon(Icons.edit,
                                        size: 16), // Smaller icon size
                                    label: const Text(
                                      "Modify    ",
                                      style: TextStyle(
                                          fontSize: 14), // Smaller font size
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6E473B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 14), // Reduced padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),

                                  // Feature This Product Button (bottom right)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      featureProduct(mostOrderedProduct!);
                                    },
                                    icon: const Icon(Icons.star,
                                        size: 16), // Smaller icon size
                                    label: const Text(
                                      "Feature This",
                                      style: TextStyle(
                                          fontSize: 14), // Smaller font size
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6E473B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 14), // Reduced padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      "OR",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6E473B),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dropdown Section
                    const Text(
                      "Select a Product to Feature",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6E473B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFE1D4C2), // Dirty white for dropdown container
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedProduct,
                        items: allProducts.map((product) {
                          return DropdownMenuItem<String>(
                            value: product,
                            child: Text(
                              product,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedProduct = value;
                          });
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Feature Button
                    ElevatedButton(
                      onPressed: selectedProduct == null
                          ? null
                          : () {
                              featureProduct(selectedProduct!);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF291C0E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Feature Selected Product",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        // Add the functionality for changing the feature parameters here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E473B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Modify Feature Parameters",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

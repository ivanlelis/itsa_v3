import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itsa_food_app/customer_pages/save_combo.dart';

class ComboOrder extends StatefulWidget {
  final String? userName;
  final String? emailAddress;
  final String? imageUrl;
  final String? uid;
  final String? email;
  final String? userAddress;
  final double latitude;
  final double longitude;
  final String? branchID;

  const ComboOrder({
    super.key,
    this.userName,
    this.emailAddress,
    this.imageUrl,
    this.uid,
    this.email,
    this.userAddress,
    required this.latitude,
    required this.longitude,
    this.branchID,
  });

  @override
  _ComboOrderState createState() => _ComboOrderState();
}

class _ComboOrderState extends State<ComboOrder> with TickerProviderStateMixin {
  String? selectedItem; // To track the selected item (dumplings or takoyaki)
  String? productType; // To store productType (Meals or Takoyaki)
  String? collectionPath;
  String? selectedProductID;
  String? selectedMilkTeaID;
  late Future<QuerySnapshot> productFuture;
  late Future<QuerySnapshot> milkTeaFuture; // Add this line

  @override
  void initState() {
    super.initState();
    collectionPath = getCollectionPath();
  }

  String getCollectionPath() {
    if (widget.branchID == "branch 1") {
      return "products";
    } else if (widget.branchID == "branch 2") {
      return "products_branch1";
    } else if (widget.branchID == "branch 3") {
      return "products_branch2";
    }
    return "products"; // Default case
  }

  void updateProductType(String item) {
    setState(() {
      selectedItem = item;
      // Update the productType based on the selected item
      productType = item == "dumplings" ? "Meals" : "Takoyaki";

      // Fetch products based on the selected category
      productFuture = FirebaseFirestore.instance
          .collection(collectionPath!)
          .where("productType", isEqualTo: productType)
          .get(); // Fetch filtered products for the selected type

      // Fetch Milk Tea products as well
      milkTeaFuture = FirebaseFirestore.instance
          .collection(collectionPath!)
          .where("productType", isEqualTo: "Milk Tea")
          .get(); // Fetch Milk Tea products
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFBE9E7), Color(0xFFFCE4EC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2E0B0D)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 100),
                const Text(
                  "Do you want dumplings or takoyaki?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E0B0D),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => updateProductType("dumplings"),
                      icon: const Text("🥟", style: TextStyle(fontSize: 28)),
                      label: const Text("Dumplings"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedItem == "dumplings"
                            ? const Color(
                                0xFF2E7D32) // Darker green when selected
                            : const Color(
                                0xFF81C784), // Light green when not selected
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selectedItem == "dumplings"
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => updateProductType("takoyaki"),
                      icon: const Text("🐙", style: TextStyle(fontSize: 28)),
                      label: const Text("Takoyaki"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedItem == "takoyaki"
                            ? const Color(
                                0xFF3E2723) // Darker brown when selected
                            : const Color(
                                0xFF8D6E63), // Rich light brown when not selected
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selectedItem == "takoyaki"
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Dynamic label based on selected item
                selectedItem != null
                    ? Text(
                        selectedItem == "dumplings"
                            ? "Pick your dumplings:"
                            : "Pick your takoyaki:",
                        key: ValueKey(selectedItem),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E0B0D),
                        ),
                      )
                    : const SizedBox(),
                // Display product cards
                Expanded(
                  child: selectedItem == null
                      ? const Center(
                          child: Text(
                            "Please select an option to view products.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2E0B0D),
                            ),
                          ),
                        )
                      : FutureBuilder<QuerySnapshot>(
                          future: productFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}",
                                    style: const TextStyle(color: Colors.red)),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text("No products available",
                                      style: TextStyle(fontSize: 18)));
                            }

                            final products = snapshot.data!.docs;

                            return Column(
                              children: [
                                // Product cards for the selected type (Pick your...)
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: (products.length / 2).ceil(),
                                  itemBuilder: (context, rowIndex) {
                                    final startIndex = rowIndex * 2;
                                    final endIndex =
                                        (startIndex + 2 <= products.length)
                                            ? startIndex + 2
                                            : products.length;
                                    final rowProducts =
                                        products.sublist(startIndex, endIndex);

                                    return SizedBox(
                                      height:
                                          150, // Ensure the height of the scrollable area
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: rowProducts.length,
                                        itemBuilder: (context, index) {
                                          final product = rowProducts[index];
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedProductID = product
                                                    .id; // Select product under Pick your...
                                                selectedItem = product[
                                                    "productName"]; // Save the selected product's name
                                              });
                                            },
                                            child: Column(
                                              children: [
                                                // Display the product image covering the card
                                                Container(
                                                  margin:
                                                      const EdgeInsets.all(8.0),
                                                  width:
                                                      120, // Fixed width for each product card
                                                  height:
                                                      110, // Reduced height to fix overflow issue
                                                  decoration: BoxDecoration(
                                                    color: selectedProductID ==
                                                            product.id
                                                        ? Colors.blue[100]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black26,
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(2, 2),
                                                      ),
                                                    ],
                                                    border: Border.all(
                                                      color:
                                                          selectedProductID ==
                                                                  product.id
                                                              ? Colors.blue
                                                              : Colors
                                                                  .transparent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: product[
                                                                "imageUrl"] !=
                                                            null
                                                        ? Image.network(
                                                            product["imageUrl"],
                                                            fit: BoxFit
                                                                .cover, // Image will cover the whole card
                                                            width:
                                                                double.infinity,
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 60,
                                                          ),
                                                  ),
                                                ),
                                                // Padding for the product name below the image
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: Text(
                                                    product["productName"],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                // Show "Choose your milktea:" label only after a product is selected
                                if (selectedProductID != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                      "Choose your milk tea:",
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E0B0D),
                                      ),
                                    ),
                                  ),
                                // Show Milk Tea products only after a product is selected
                                if (selectedProductID != null)
                                  FutureBuilder<QuerySnapshot>(
                                    future:
                                        milkTeaFuture, // Use the milkTeaFuture for Milk Tea products
                                    builder: (context, milkTeaSnapshot) {
                                      if (milkTeaSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (milkTeaSnapshot.hasError) {
                                        return Center(
                                          child: Text(
                                              "Error: ${milkTeaSnapshot.error}",
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                        );
                                      } else if (!milkTeaSnapshot.hasData ||
                                          milkTeaSnapshot.data!.docs.isEmpty) {
                                        return const Center(
                                            child: Text(
                                                "No Milk Tea products available",
                                                style:
                                                    TextStyle(fontSize: 18)));
                                      }

                                      final milkTeaProducts =
                                          milkTeaSnapshot.data!.docs;

                                      return Column(
                                        children: [
                                          // Horizontal scrollable row for Milk Tea products
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: milkTeaProducts
                                                  .map((product) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedMilkTeaID = product
                                                          .id; // Select product under Choose your milktea:
                                                    });
                                                  },
                                                  child: Column(
                                                    children: [
                                                      // Display the product image covering the card
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .all(8.0),
                                                        width: 120,
                                                        height: 120,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              selectedMilkTeaID ==
                                                                      product.id
                                                                  ? Colors
                                                                      .blue[100]
                                                                  : Colors
                                                                      .white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black26,
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      2, 2),
                                                            ),
                                                          ],
                                                          border: Border.all(
                                                            color: selectedMilkTeaID ==
                                                                    product.id
                                                                ? Colors.blue
                                                                : Colors
                                                                    .transparent,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          child: product[
                                                                      "imageUrl"] !=
                                                                  null
                                                              ? Image.network(
                                                                  product[
                                                                      "imageUrl"],
                                                                  fit: BoxFit
                                                                      .cover, // Image will cover the whole card
                                                                  width: double
                                                                      .infinity,
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .image_not_supported,
                                                                  size: 60,
                                                                ),
                                                        ),
                                                      ),
                                                      // Product name outside the card
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Text(
                                                          product[
                                                              "productName"],
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                const SizedBox(
                                  height: 130,
                                ),
                                if (selectedMilkTeaID != null &&
                                    selectedProductID !=
                                        null) // Ensure both are selected
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 24.0),
                                    child: SizedBox(
                                      width: double
                                          .infinity, // Makes the button take up the full width
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                              0xFF2E7D32), // Set to the desired green color
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          // Navigate to SaveCombo and pass the selectedItem and selectedMilkTeaID
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => SaveCombo(
                                                      selectedProductID:
                                                          selectedProductID,
                                                      selectedMilkTeaID:
                                                          selectedMilkTeaID,
                                                      branchID: widget.branchID,
                                                      latitude: widget.latitude,
                                                      longitude:
                                                          widget.longitude,
                                                      userAddress:
                                                          widget.userAddress,
                                                      userName: widget.userName,
                                                      uid: widget.uid,
                                                      imageUrl: widget.imageUrl,
                                                      email: widget.email,
                                                      emailAddress:
                                                          widget.emailAddress,
                                                    )),
                                          );
                                        },
                                        child: const Text(
                                          "Proceed",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure to import Firestore
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';
import 'package:itsa_food_app/customer_pages/product_view.dart';
import 'package:itsa_food_app/user_provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:itsa_food_app/customer_pages/main_cart.dart';
import 'package:itsa_food_app/customer_pages/profile.dart';

class Menu extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String imageUrl;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;

  const Menu({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.imageUrl,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
  });
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _selectedIndex = 1; // Set the default to Menu (index 1)
  int _selectedCategoryIndex = 0; // Default category index
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CustomerMainHome(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Menu(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Favorites
        // Navigate to the Favorites screen (replace with your actual screen)
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfileView(
              userName: widget.userName,
              emailAddress: widget.emailAddress,
              imageUrl: widget.imageUrl,
              uid: widget.uid,
              email: widget.email,
              userAddress: widget.userAddress,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  Stream<QuerySnapshot> _getProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        onCartPressed: () {
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainCart(
                  userName: user.userName,
                  emailAddress: user.emailAddress,
                  uid: widget.uid,
                  email: widget.email,
                  imageUrl: widget.imageUrl,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  userAddress: widget.userAddress,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please log in to access the cart")),
            );
          }
        },
        userName: user?.userName ?? '',
        uid: user?.uid ?? '',
      ),
      drawer: Drawer(
        child: Sidebar(
          userName: widget.userName,
          emailAddress: widget.emailAddress,
          imageUrl: widget.imageUrl,
          uid: widget.uid,
          latitude: widget.latitude,
          longitude: widget.longitude,
          email: widget.email,
          userAddress: widget.userAddress,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CategoryButton(
                  label: 'All', // Use text for 'All'
                  index: 0,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 0;
                    });
                  },
                ),
                CategoryButton(
                  label: 'Takoyaki', // Use text for 'Takoyaki'
                  index: 1,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 1;
                    });
                  },
                ),
                CategoryButton(
                  label: 'Milk Tea', // Use text for 'Milk Tea'
                  index: 2,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 2;
                    });
                  },
                ),
                CategoryButton(
                  label: 'Meals', // Use text for 'Meals'
                  index: 3,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 3;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // StreamBuilder to listen to products in Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading products'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs;

                  // Filter products based on selected category
                  final filteredProducts = products.where((product) {
                    if (_selectedCategoryIndex == 0) return true; // All
                    if (_selectedCategoryIndex == 1 &&
                        product['productType'] == 'Takoyaki') return true;
                    if (_selectedCategoryIndex == 2 &&
                        product['productType'] == 'Milk Tea') return true;
                    if (_selectedCategoryIndex == 3 &&
                        product['productType'] == 'Meals') return true;
                    return false;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products available'));
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      childAspectRatio:
                          0.75, // Adjust the aspect ratio as needed
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      // Ensure to access fields safely
                      String? takoyakiPrice4 =
                          product['productType'] == 'Takoyaki'
                              ? product['4pc']?.toString()
                              : null;
                      String? takoyakiPrice8 =
                          product['productType'] == 'Takoyaki'
                              ? product['8pc']?.toString()
                              : null;
                      String? takoyakiPrice12 =
                          product['productType'] == 'Takoyaki'
                              ? product['12pc']?.toString()
                              : null;
                      String? milkTeaRegular =
                          product['productType'] == 'Milk Tea'
                              ? product['regular']?.toString()
                              : null;
                      String? milkTeaLarge =
                          product['productType'] == 'Milk Tea'
                              ? product['large']?.toString()
                              : null;
                      String? mealsPrice = product['productType'] == 'Meals'
                          ? product['price']?.toString()
                          : null;

                      return ProductCard(
                        productID: product['productID'] ??
                            '', // Pass the productID here
                        productName:
                            product['productName'] ?? 'Unknown Product',
                        imageUrl: product['imageUrl'] ?? '',
                        takoyakiPrices: takoyakiPrice4,
                        takoyakiPrices8: takoyakiPrice8,
                        takoyakiPrices12: takoyakiPrice12,
                        milkTeaRegular: milkTeaRegular,
                        milkTeaLarge: milkTeaLarge,
                        mealsPrice: mealsPrice,
                        userName: widget.userName,
                        emailAddress: widget.emailAddress,
                        uid: widget.uid,
                        userAddress: widget.userAddress,
                        latitude: widget.latitude,
                        longitude: widget.longitude,
                        email: widget.email,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final String productID; // Updated to use productID
  final String productName;
  final String imageUrl;
  final String? takoyakiPrices;
  final String? takoyakiPrices8;
  final String? takoyakiPrices12;
  final String? milkTeaRegular;
  final String? milkTeaLarge;
  final String? mealsPrice;
  final String userName;
  final String emailAddress;
  final String uid;
  final String userAddress;
  final double latitude;
  final double longitude;
  final String email;

  const ProductCard({
    super.key,
    required this.productID,
    required this.productName,
    required this.imageUrl,
    this.takoyakiPrices,
    this.takoyakiPrices8,
    this.takoyakiPrices12,
    this.milkTeaRegular,
    this.milkTeaLarge,
    this.mealsPrice,
    required this.userName,
    required this.emailAddress,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
    required this.email,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  List<Map<String, String>> ingredientsStatus = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIngredientsAndStock();
  }

  Future<void> _fetchIngredientsAndStock() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch product's ingredients field using productID as document ID
      final productDoc =
          await firestore.collection('products').doc(widget.productID).get();
      final List<dynamic> ingredients = productDoc.data()!['ingredients'] ?? [];

      // Check stock status for each ingredient in rawStock
      List<Map<String, String>> fetchedIngredientsStatus = [];

      for (var ingredient in ingredients) {
        final String ingredientName =
            ingredient['name']; // Assuming each ingredient has a name field

        // Fetch raw stock document using ingredient name as the document ID
        final rawStockQuery = await firestore
            .collection('rawStock')
            .where('matName', isEqualTo: ingredientName)
            .get();

        if (rawStockQuery.docs.isNotEmpty) {
          // Retrieve the quantity value from the raw stock document
          final int quantity = rawStockQuery.docs.first.data()['quantity'] ?? 0;

          // Determine stock status based on quantity
          final bool inStock = quantity >= 1;

          // Add ingredient status to the list
          fetchedIngredientsStatus.add({
            'name': ingredientName,
            'status': inStock ? 'In Stock' : 'Out of Stock',
          });
        } else {
          // If no matching ingredient is found in rawStock, mark as Out of Stock
          fetchedIngredientsStatus.add({
            'name': ingredientName,
            'status': 'Out of Stock',
          });
        }
      }

      setState(() {
        ingredientsStatus = fetchedIngredientsStatus;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ingredients or stock: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String productType;
    String startingPriceText = "Starts at ₱";

    if (widget.takoyakiPrices != null) {
      productType = 'takoyaki';
      startingPriceText += widget.takoyakiPrices!;
    } else if (widget.milkTeaRegular != null) {
      productType = 'milktea';
      startingPriceText += widget.milkTeaRegular!;
    } else if (widget.mealsPrice != null) {
      productType = 'meal';
      startingPriceText = 'Price: ₱${widget.mealsPrice}';
    } else {
      productType = 'unknown';
      startingPriceText = 'Price Unavailable';
    }

    // Check if any ingredient is out of stock
    bool isOutOfStock = ingredientsStatus
        .any((ingredient) => ingredient['status'] == 'Out of Stock');

    return GestureDetector(
      onTap: () {
        if (isOutOfStock) {
          // Show the dialog when the product is out of stock
          _showOutOfStockDialog(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductView(
                productName: widget.productName,
                imageUrl: widget.imageUrl,
                takoyakiPrices: widget.takoyakiPrices,
                takoyakiPrices8: widget.takoyakiPrices8,
                takoyakiPrices12: widget.takoyakiPrices12,
                milkTeaRegular: widget.milkTeaRegular,
                milkTeaLarge: widget.milkTeaLarge,
                mealsPrice: widget.mealsPrice,
                userName: widget.userName,
                emailAddress: widget.emailAddress,
                productType: productType,
                uid: widget.uid,
                userAddress: widget.userAddress,
                email: widget.email,
                latitude: widget.latitude,
                longitude: widget.longitude,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack to dim the image if any ingredient is out of stock
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    width: double.infinity,
                    height: 160, // Set a fixed height or adjust as needed
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                if (isOutOfStock)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: double.infinity,
                      height: 160, // Match the height of the image
                      color: Colors.black.withOpacity(0.5), // Dim the image
                      child: Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildPriceContainer(startingPriceText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the out-of-stock dialog
  void _showOutOfStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Product Unavailable"),
          content: Text("This product is currently unavailable."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceContainer(String price) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        price,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onPressed;

  const CategoryButton({
    super.key,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = index == selectedIndex;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 4.0), // Space between buttons
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.purple : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0), // Uniform padding
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

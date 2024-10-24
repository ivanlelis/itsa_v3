import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure to import Firestore
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:itsa_food_app/widgets/customer_appbar.dart';
import 'package:itsa_food_app/widgets/customer_navbar.dart';
import 'package:itsa_food_app/widgets/customer_sidebar.dart';
import 'package:itsa_food_app/customer_pages/product_view.dart';

class Menu extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const Menu({
    Key? key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  }) : super(key: key);

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
          MaterialPageRoute(
            builder: (context) => CustomerMainHome(
              userName: widget.userName,
              email: widget.email,
              imageUrl: widget.imageUrl,
            ),
          ),
        );
        break;
      case 1: // Menu
        break;
      case 2: // Favorites
        // Navigate to the Favorites screen (replace with your actual screen)
        break;
      case 3: // User
        // Navigate to the User screen (replace with your actual screen)
        break;
    }
  }

  Stream<QuerySnapshot> _getProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        onCartPressed: () {
          // Implement your cart logic here
        },
      ),
      drawer: Drawer(
        child: Sidebar(
          userName: widget.userName,
          email: widget.email,
          imageUrl: widget.imageUrl,
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
                  title: 'All',
                  index: 0,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 0;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Takoyaki',
                  index: 1,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 1;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Milk Tea',
                  index: 2,
                  selectedIndex: _selectedCategoryIndex,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryIndex = 2;
                    });
                  },
                ),
                CategoryButton(
                  title: 'Meals',
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
                      String? milkTeaSmall =
                          product['productType'] == 'Milk Tea'
                              ? product['small']?.toString()
                              : null;
                      String? milkTeaMedium =
                          product['productType'] == 'Milk Tea'
                              ? product['medium']?.toString()
                              : null;
                      String? milkTeaLarge =
                          product['productType'] == 'Milk Tea'
                              ? product['large']?.toString()
                              : null;
                      String? mealsPrice = product['productType'] == 'Meals'
                          ? product['price']?.toString()
                          : null;

                      return ProductCard(
                        productName:
                            product['productName'] ?? 'Unknown Product',
                        imageUrl: product['imageUrl'] ?? '',
                        takoyakiPrices: takoyakiPrice4,
                        takoyakiPrices8: takoyakiPrice8,
                        takoyakiPrices12: takoyakiPrice12,
                        milkTeaSmall: milkTeaSmall,
                        milkTeaMedium: milkTeaMedium,
                        milkTeaLarge: milkTeaLarge,
                        mealsPrice: mealsPrice,
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

class ProductCard extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final String? takoyakiPrices;
  final String? takoyakiPrices8;
  final String? takoyakiPrices12;
  final String? milkTeaSmall;
  final String? milkTeaMedium;
  final String? milkTeaLarge;
  final String? mealsPrice;

  const ProductCard({
    Key? key,
    required this.productName,
    required this.imageUrl,
    this.takoyakiPrices,
    this.takoyakiPrices8,
    this.takoyakiPrices12,
    this.milkTeaSmall,
    this.milkTeaMedium,
    this.milkTeaLarge,
    this.mealsPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the ProductView page and pass product details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductView(
              productName: productName,
              imageUrl: imageUrl,
              takoyakiPrices: takoyakiPrices,
              takoyakiPrices8: takoyakiPrices8,
              takoyakiPrices12: takoyakiPrices12,
              milkTeaSmall: milkTeaSmall,
              milkTeaMedium: milkTeaMedium,
              milkTeaLarge: milkTeaLarge,
              mealsPrice: mealsPrice,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Rounded all corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(16.0), // Rounded all corners
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (takoyakiPrices != null &&
                      takoyakiPrices8 != null &&
                      takoyakiPrices12 != null) ...[
                    _buildPriceContainer('4pc: $takoyakiPrices'),
                    _buildPriceContainer('8pc: $takoyakiPrices8'),
                    _buildPriceContainer('12pc: $takoyakiPrices12'),
                  ] else if (mealsPrice != null) ...[
                    _buildPriceContainer('Price: $mealsPrice'),
                  ] else if (milkTeaSmall != null &&
                      milkTeaMedium != null &&
                      milkTeaLarge != null) ...[
                    _buildPriceContainer('Small: $milkTeaSmall'),
                    _buildPriceContainer('Medium: $milkTeaMedium'),
                    _buildPriceContainer('Large: $milkTeaLarge'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceContainer(String price) {
    return Container(
      margin:
          const EdgeInsets.symmetric(vertical: 4.0), // Margin between prices
      padding: const EdgeInsets.symmetric(
          horizontal: 12.0, vertical: 6.0), // Padding inside the rectangle
      decoration: BoxDecoration(
        color: Colors.green, // Green background
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
      ),
      child: Text(
        price,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0, // Adjust the font size to make it smaller
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onPressed;

  const CategoryButton({
    super.key,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedIndex == index ? Colors.deepPurple : Colors.grey[300],
      ),
      onPressed: onPressed,
      child: Text(
        title,
        style: TextStyle(
          color: selectedIndex == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

// admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureConfigPage extends StatefulWidget {
  const FeatureConfigPage({super.key});

  @override
  _FeatureConfigPageState createState() => _FeatureConfigPageState();
}

class _FeatureConfigPageState extends State<FeatureConfigPage>
    with SingleTickerProviderStateMixin {
  // State variables to hold checkbox selections and the slider value
  bool isDiscountChecked = false;
  bool isPromoCodeChecked = false;
  bool isExclusiveBundleChecked = false;
  double discountValue = 0; // Slider value for discount
  bool isLoyaltyPointsChecked = false;
  bool isFeaturedDurationChecked = false;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  Map<String, int> productCount = {};
  String? mostOrderedProduct;
  Map<String, dynamic>? productDetails;
  String? selectedBundleOption;
  final TextEditingController _loyaltyPointsController =
      TextEditingController();
  double totalRawMaterialCost = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the initial value of the slider
    _discountController.text = discountValue.toStringAsFixed(0);
    fetchMostOrderedProduct();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed
    _discountController.dispose();
    super.dispose();
  }

  // Method to format a date string into MM/dd/yyyy format
  String _formatDate(String dateString) {
    try {
      DateTime date;

      // Check if the input date is in MMddyy format (6 characters)
      if (dateString.length == 6) {
        // Parse MMddyy format
        date = DateFormat('MMddyy').parse(dateString);
      } else {
        // Otherwise, treat it as ISO format
        date = DateTime.parse(dateString);
      }

      // Return formatted date as MM/dd/yyyy
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      return 'No Date Chosen';
    }
  }

// Convert the raw date to local time and set time to midnight
  DateTime _convertToLocalTime(String rawDate, {bool setToMidnight = false}) {
    try {
      DateTime date;

      // Check if the input date is in MMddyy format (6 characters)
      if (rawDate.length == 6) {
        // Parse MMddyy format
        date = DateFormat('MMddyy').parse(rawDate);
      } else {
        // Otherwise, treat it as ISO format
        date = DateTime.parse(rawDate);
      }

      if (setToMidnight) {
        // Set time to midnight (00:00:00) for both start and end dates
        return DateTime(date.year, date.month, date.day, 16, 0, 0); // Midnight
      }

      return date; // Return the date with the same time if no change required
    } catch (e) {
      throw FormatException("Invalid date format: $rawDate");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      // Ensure that the date is valid (no date before the year 2000)
      if (picked.isBefore(DateTime(2000))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select a valid date after the year 2000')),
        );
        return;
      }

      setState(() {
        // Convert the picked date to local time, with time set to midnight
        DateTime localTime = _convertToLocalTime(
          picked.toIso8601String(),
          setToMidnight: true, // Set to midnight for both start and end dates
        );

        // Store the selected date as ISO 8601 string (with the appropriate time set)
        String isoDate = localTime.toIso8601String();

        // Use the ISO formatted string for the start or end date
        if (isStartDate) {
          startDateController.text = isoDate;
        } else {
          endDateController.text = isoDate;
        }
      });
    } else {
      // Handle case where no date was selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No date selected')),
      );
    }
  }

  Future<void> fetchMostOrderedProduct() async {
    productCount.clear(); // Clear existing data before fetching
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

    String? mostOrdered;
    int maxCount = 0;
    productCount.forEach((product, count) {
      if (count > maxCount) {
        mostOrdered = product;
        maxCount = count;
      }
    });

    setState(() {
      mostOrderedProduct = mostOrdered;
    });

    // Fetch product details for the most ordered product
    if (mostOrderedProduct != null) {
      fetchProductDetails(mostOrderedProduct!);
    }
  }

  Future<void> fetchProductDetails(String productName) async {
    QuerySnapshot productSnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    for (var productDoc in productSnapshot.docs) {
      if (productDoc['productName'] == productName) {
        setState(() {
          productDetails = productDoc.data() as Map<String, dynamic>;
        });
        break; // Stop once we find the product
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRawMaterialCosts(
      List<dynamic> ingredients) async {
    List<Map<String, dynamic>> costs = [];

    for (var ingredient in ingredients) {
      String ingredientName = ingredient['name'];
      String quantityString = ingredient['quantity'];

      // Extract numeric value from the quantity string (e.g., "120 ml" -> 120)
      double quantity = _parseQuantity(quantityString);

      // Fetch raw material cost from Firestore for the ingredient
      var rawStockSnapshot = await FirebaseFirestore.instance
          .collection('rawStock')
          .where('matName', isEqualTo: ingredientName) // Search for matName
          .limit(1)
          .get();

      if (rawStockSnapshot.docs.isNotEmpty) {
        var rawMaterial = rawStockSnapshot.docs.first.data();
        double totalCost = 0.0;

        // Check for different cost types based on the ingredient
        if (rawMaterial.containsKey('costPerMl') &&
            !ingredientName.contains('Ice')) {
          // If it's not Ice and it has a cost per ml, calculate accordingly
          totalCost = _parseCost(rawMaterial['costPerMl']) * quantity;
        } else if (rawMaterial.containsKey('costPerGram') ||
            ingredientName.contains('Ice')) {
          // If it's Ice or if it has a cost per gram, calculate accordingly
          totalCost = _parseCost(rawMaterial['costPerGram']) * quantity;
        }

        // Add the ingredient cost to the list
        costs.add({
          'ingredientName': ingredientName,
          'cost': totalCost,
        });
      }
    }

    return costs;
  }

  // Helper function to parse quantity (e.g., "120 ml" -> 120.0)
  double _parseQuantity(String quantityString) {
    // Remove any non-numeric characters (e.g., 'ml', 'g', etc.)
    RegExp regExp = RegExp(r'(\d+(\.\d+)?)');
    Match? match = regExp.firstMatch(quantityString);

    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  // Helper function to parse cost (e.g., "costPerMl" or "costPerGram")
  double _parseCost(dynamic cost) {
    return double.tryParse(cost.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20), // Rounded corners for the top
        ),
        child: Container(
            color: const Color(0xFFE1D4C2),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Discount checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: isDiscountChecked,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isDiscountChecked = newValue ?? false;
                                  });
                                },
                              ),
                              Text("Discount"),
                            ],
                          ),

                          // AnimatedSwitcher for the card
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              // Bounce effect with ScaleTransition
                              Animation<double> bounceAnimation =
                                  CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              );
                              return ScaleTransition(
                                scale: bounceAnimation,
                                child: child,
                              );
                            },
                            child: isDiscountChecked
                                ? Padding(
                                    key: ValueKey<bool>(isDiscountChecked),
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Discount Percentage",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF291C0E),
                                              ),
                                            ),
                                            Slider(
                                              value: discountValue.clamp(1,
                                                  100), // Clamp slider to 1-100
                                              min: 1,
                                              max: 100,
                                              divisions: 100,
                                              label:
                                                  '${discountValue.toStringAsFixed(0)}%',
                                              onChanged: (double newValue) {
                                                setState(() {
                                                  discountValue =
                                                      newValue.clamp(1, 100);
                                                  _discountController.text =
                                                      discountValue
                                                          .toStringAsFixed(0);
                                                });
                                              },
                                            ),
                                            Text(
                                              "*This slider determines how much discount this product will get during the featured duration",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Text(
                                                  "Enter Discount (%): ",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF291C0E),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _discountController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 10,
                                                      ),
                                                      hintText: "Enter 1-100",
                                                    ),
                                                    onChanged: (String value) {
                                                      double? parsedValue =
                                                          double.tryParse(
                                                              value);
                                                      if (parsedValue != null) {
                                                        setState(() {
                                                          // Clamp the value between 1 and 100
                                                          discountValue =
                                                              parsedValue.clamp(
                                                                  1, 100);
                                                          _discountController
                                                                  .text =
                                                              discountValue
                                                                  .toStringAsFixed(
                                                                      0);
                                                        });
                                                      }
                                                    },
                                                    onSubmitted:
                                                        (String value) {
                                                      double? parsedValue =
                                                          double.tryParse(
                                                              value);
                                                      if (parsedValue == null ||
                                                          parsedValue < 1) {
                                                        setState(() {
                                                          discountValue = 1;
                                                          _discountController
                                                                  .text =
                                                              discountValue
                                                                  .toStringAsFixed(
                                                                      0);
                                                        });
                                                      } else if (parsedValue >
                                                          100) {
                                                        setState(() {
                                                          discountValue = 100;
                                                          _discountController
                                                                  .text =
                                                              discountValue
                                                                  .toStringAsFixed(
                                                                      0);
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(
                                    key: ValueKey<bool>(isDiscountChecked),
                                  ),
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: isExclusiveBundleChecked,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isExclusiveBundleChecked =
                                        newValue ?? false;
                                  });
                                },
                              ),
                              Text("Exclusive Bundle"),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              // Bounce effect with ScaleTransition
                              Animation<double> bounceAnimation =
                                  CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              );
                              return ScaleTransition(
                                scale: bounceAnimation,
                                child: child,
                              );
                            },
                            child: isExclusiveBundleChecked
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Card(
                                      key: ValueKey<bool>(
                                          isExclusiveBundleChecked),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 12,
                                            ),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value:
                                                  'Buy 1 Regular, Get 1 Regular',
                                              child: Text(
                                                  'Buy 1 Regular, Get 1 Regular'),
                                            ),
                                            DropdownMenuItem(
                                              value: '1 Free Regular Milktea',
                                              child: Text(
                                                  '1 Free Regular Milktea'),
                                            ),
                                            DropdownMenuItem(
                                              value: '1 Free 4 pc Takoyaki',
                                              child:
                                                  Text('1 Free 4 pc Takoyaki'),
                                            ),
                                          ],
                                          hint: Text("Select a Bundle"),
                                          onChanged: (String? value) {
                                            // Update state to capture the selected bundle option
                                            setState(() {
                                              selectedBundleOption = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox
                                    .shrink(), // Render nothing when unchecked
                            // Empty widget when unchecked
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: isLoyaltyPointsChecked,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isLoyaltyPointsChecked = newValue ?? false;
                                  });
                                },
                              ),
                              Text("Loyalty Points"),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              // Bounce effect with ScaleTransition
                              Animation<double> bounceAnimation =
                                  CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              );
                              return ScaleTransition(
                                scale: bounceAnimation,
                                child: child,
                              );
                            },
                            child: isLoyaltyPointsChecked
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Card(
                                      key: ValueKey<bool>(
                                          isLoyaltyPointsChecked),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: TextField(
                                          controller:
                                              _loyaltyPointsController, // Added controller
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly, // Allow only digits
                                          ],
                                          decoration: InputDecoration(
                                            labelText: "Enter Loyalty Points",
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 10),
                                          ),
                                          onChanged: (value) {
                                            // Handle input, if needed
                                            print("Loyalty Points: $value");
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox
                                    .shrink(), // Empty widget when unchecked
                          ),

                          Row(
                            children: [
                              Checkbox(
                                value: isFeaturedDurationChecked,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isFeaturedDurationChecked =
                                        newValue ?? false;
                                  });
                                },
                              ),
                              Text("Featured Duration"),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              Animation<double> bounceAnimation =
                                  CurvedAnimation(
                                parent: animation,
                                curve: Curves.elasticOut,
                              );
                              return ScaleTransition(
                                scale: bounceAnimation,
                                child: child,
                              );
                            },
                            child: isFeaturedDurationChecked
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Card(
                                      key: ValueKey<bool>(
                                          isFeaturedDurationChecked),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "Start Date: ",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _selectDate(context,
                                                        true); // Select start date
                                                  },
                                                  child: Text("Select Date"),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatDate(startDateController
                                                  .text), // Format and display the start date
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Text(
                                                  "End Date: ",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _selectDate(context,
                                                        false); // Select end date
                                                  },
                                                  child: Text("Select Date"),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatDate(endDateController
                                                  .text), // Format and display the end date
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          productDetails == null
                              ? CircularProgressIndicator() // Show loading until product details are fetched
                              : FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _fetchRawMaterialCosts(
                                      productDetails!['ingredients']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child:
                                              CircularProgressIndicator()); // Show loading while fetching raw material costs
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    } else if (snapshot.hasData) {
                                      List<Map<String, dynamic>>
                                          rawMaterialCosts = snapshot.data!;
                                      double totalRawMaterialCost = 0;

                                      // Sum up the costs of all ingredients
                                      for (var cost in rawMaterialCosts) {
                                        totalRawMaterialCost +=
                                            (double.tryParse(
                                                    cost['cost'].toString()) ??
                                                0);
                                      }

                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Product Details Card
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.9, // Adjust width as needed
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                elevation: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Product Name: ${productDetails!['productName']}',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        'Product ID: ${productDetails!['productID']}',
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                      SizedBox(height: 10),
                                                      productDetails![
                                                                  'productType'] ==
                                                              'Milk Tea'
                                                          ? Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Regular: ₱${(double.tryParse(productDetails!['regular'].toString()) ?? 0).toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          16),
                                                                ),
                                                                SizedBox(
                                                                    height: 5),
                                                                Text(
                                                                  'Large: ₱${(double.tryParse(productDetails!['large'].toString()) ?? 0).toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          16),
                                                                ),
                                                              ],
                                                            )
                                                          : Text(
                                                              'Price: ₱${(double.tryParse(productDetails!['price'].toString()) ?? 0).toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                  fontSize: 16),
                                                            ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        'Category: ${productDetails!['productType']}',
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                      SizedBox(height: 10),
                                                      isDiscountChecked &&
                                                              productDetails![
                                                                      'productType'] ==
                                                                  'Milk Tea'
                                                          ? Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                            )
                                                          : SizedBox.shrink(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 20),
                                            // Insights Card
                                            Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              elevation: 4,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Insights',
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 10),
                                                    productDetails?[
                                                                'productType'] ==
                                                            'Milk Tea'
                                                        ? Builder(
                                                            builder: (_) {
                                                              double
                                                                  regularPrice =
                                                                  double.tryParse(
                                                                          productDetails?['regular']?.toString() ??
                                                                              '0') ??
                                                                      0;
                                                              double
                                                                  largePrice =
                                                                  double.tryParse(
                                                                          productDetails?['large']?.toString() ??
                                                                              '0') ??
                                                                      0;
                                                              double
                                                                  regularPriceWithDiscount =
                                                                  regularPrice -
                                                                      (regularPrice *
                                                                          discountValue /
                                                                          100);
                                                              double
                                                                  largePriceWithDiscount =
                                                                  largePrice -
                                                                      (largePrice *
                                                                          discountValue /
                                                                          100);

                                                              // Determine if discount is profitable by comparing to raw material cost
                                                              double
                                                                  regularProfitMargin =
                                                                  regularPriceWithDiscount -
                                                                      totalRawMaterialCost;
                                                              double
                                                                  largeProfitMargin =
                                                                  largePriceWithDiscount -
                                                                      totalRawMaterialCost;

                                                              String
                                                                  regularMessage =
                                                                  (regularProfitMargin >
                                                                          0)
                                                                      ? 'Discount is profitable with a profit of ₱${regularProfitMargin.toStringAsFixed(2)}!'
                                                                      : 'Discount is not profitable.';

                                                              String
                                                                  largeMessage =
                                                                  (largeProfitMargin >
                                                                          0)
                                                                      ? 'Discount is profitable with a profit of ₱${largeProfitMargin.toStringAsFixed(2)}!'
                                                                      : 'Discount is not profitable.';

                                                              // Exclusive Bundle Insights Logic
                                                              String
                                                                  bundleMessage =
                                                                  '';
                                                              double
                                                                  bundleProfit =
                                                                  0;

                                                              if (isExclusiveBundleChecked &&
                                                                  selectedBundleOption !=
                                                                      null) {
                                                                if (selectedBundleOption ==
                                                                    'Buy 1 Regular, Get 1 Regular') {
                                                                  double
                                                                      totalCost =
                                                                      totalRawMaterialCost *
                                                                          2;
                                                                  bundleProfit =
                                                                      regularPrice -
                                                                          totalCost;
                                                                  bundleMessage =
                                                                      (bundleProfit >
                                                                              0)
                                                                          ? 'Exclusive Bundle "${selectedBundleOption}" is profitable with a profit of ₱${bundleProfit.toStringAsFixed(2)}.'
                                                                          : 'Exclusive Bundle "${selectedBundleOption}" results in a loss of ₱${bundleProfit.abs().toStringAsFixed(2)}.';
                                                                } else if (selectedBundleOption ==
                                                                    '1 Free Regular Milktea') {
                                                                  double
                                                                      totalCost =
                                                                      totalRawMaterialCost *
                                                                          2;
                                                                  double
                                                                      regularPrice =
                                                                      55; // Hardcoded value for regular price
                                                                  bundleProfit =
                                                                      regularPrice -
                                                                          totalCost;
                                                                  bundleMessage =
                                                                      (bundleProfit >
                                                                              0)
                                                                          ? 'Exclusive Bundle "${selectedBundleOption}" is profitable with a profit of ₱${bundleProfit.toStringAsFixed(2)}.'
                                                                          : 'Exclusive Bundle "${selectedBundleOption}" results in a loss of ₱${bundleProfit.abs().toStringAsFixed(2)}.';
                                                                } else if (selectedBundleOption ==
                                                                    '1 Free 4 pc Takoyaki') {
                                                                  double
                                                                      takoyakiCost =
                                                                      30; // Assume cost of 4 pcs Takoyaki
                                                                  double
                                                                      totalCost =
                                                                      totalRawMaterialCost +
                                                                          takoyakiCost;
                                                                  double
                                                                      regularPrice =
                                                                      45; // Hardcoded value for regular price
                                                                  bundleProfit =
                                                                      regularPrice -
                                                                          totalCost;
                                                                  bundleMessage =
                                                                      (bundleProfit >
                                                                              0)
                                                                          ? 'Exclusive Bundle "${selectedBundleOption}" is profitable with a profit of ₱${bundleProfit.toStringAsFixed(2)}.'
                                                                          : 'Exclusive Bundle "${selectedBundleOption}" results in a loss of ₱${bundleProfit.abs().toStringAsFixed(2)}.';
                                                                }
                                                              }

                                                              return Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    'Regular Price after Discount: ₱${regularPriceWithDiscount.toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          5),
                                                                  Text(
                                                                    regularMessage,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      color: (regularProfitMargin >
                                                                              0)
                                                                          ? Colors
                                                                              .green
                                                                          : Colors
                                                                              .red,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          5),
                                                                  Text(
                                                                    'Large Price after Discount: ₱${largePriceWithDiscount.toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          5),
                                                                  Text(
                                                                    largeMessage,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      color: (largeProfitMargin >
                                                                              0)
                                                                          ? Colors
                                                                              .green
                                                                          : Colors
                                                                              .red,
                                                                    ),
                                                                  ),
                                                                  if (isExclusiveBundleChecked &&
                                                                      selectedBundleOption !=
                                                                          null)
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                            height:
                                                                                10),
                                                                        Text(
                                                                          'Exclusive Bundle Insights:',
                                                                          style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                        SizedBox(
                                                                            height:
                                                                                5),
                                                                        Text(
                                                                          bundleMessage,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            color: (bundleProfit > 0)
                                                                                ? Colors.green
                                                                                : Colors.red,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                ],
                                                              );
                                                            },
                                                          )
                                                        : Text(
                                                            'No insights available for this product type.',
                                                            style: TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Center(
                                          child: Text('No data available'));
                                    }
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final selectedCategory =
                                productDetails?['productType'];

                            double regularProfitMargin = 0;
                            double largeProfitMargin = 0;

                            final featuredCollection = FirebaseFirestore
                                .instance
                                .collection('featured');

                            try {
                              // Convert start and end dates to Philippine time
                              DateTime? startDate = isFeaturedDurationChecked
                                  ? _convertToLocalTime(
                                      startDateController.text)
                                  : null;
                              DateTime? endDate = isFeaturedDurationChecked
                                  ? _convertToLocalTime(endDateController.text,
                                      setToMidnight: true)
                                  : null;

                              // Prepare the dynamic data
                              final data = {
                                'discount':
                                    isDiscountChecked ? discountValue : null,
                                'exBundle': isExclusiveBundleChecked
                                    ? selectedBundleOption
                                    : null,
                                'loyaltyPoints': isLoyaltyPointsChecked
                                    ? _loyaltyPointsController.text
                                    : null,
                                'startDate':
                                    startDate, // Save as actual DateTime object
                                'endDate':
                                    endDate, // Save as actual DateTime object
                              };

                              // Add Milk Tea-specific fields if discount is checked
                              if (isDiscountChecked &&
                                  selectedCategory == 'Milk Tea') {
                                data.addAll({
                                  'regularNewPrice': regularProfitMargin,
                                  'largeNewPrice': largeProfitMargin,
                                });
                              }

                              // Save the data to Firestore
                              await featuredCollection
                                  .doc('featured')
                                  .set(data);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Configuration saved successfully!')),
                              );
                            } catch (e) {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to save configuration: $e')),
                              );
                            }
                          },
                          child: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Closes the modal
                          },
                          child: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

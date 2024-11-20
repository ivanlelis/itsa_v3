import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ConfirmPayment extends StatefulWidget {
  final List<dynamic> cartItems;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmount;
  final String uid; // Current customer’s ID
  final String userName;
  final String userAddress;
  final String emailAddress;
  final double latitude;
  final double longitude;
  final String orderType;
  final String email;
  final String imageUrl;

  const ConfirmPayment({
    super.key,
    required this.cartItems,
    required this.deliveryType,
    required this.paymentMethod,
    required this.voucherCode,
    required this.totalAmount,
    required this.uid,
    required this.userName,
    required this.userAddress,
    required this.emailAddress,
    required this.latitude,
    required this.longitude,
    required this.orderType,
    required this.email,
    required this.imageUrl,
  });

  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  String discountDescription = '';
  File? _receiptImage; // To store the selected receipt image

  final ImagePicker _picker = ImagePicker();

  // Function to pick an image for the receipt
  Future<void> _pickReceiptImage() async {
    // Pick an image from the gallery
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchVoucherDetails();
  }

  // Fetch voucher details from Firestore
  Future<void> _fetchVoucherDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('voucher')
        .doc(widget.voucherCode)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        final discountAmt = data['discountAmt'];
        final discountType = data['discountType'];

        // Format discount string based on type
        if (discountType == "Fixed Amount") {
          discountDescription = '₱$discountAmt off';
        } else if (discountType == "Percentage") {
          discountDescription = '$discountAmt% off';
        }

        setState(() {}); // Update the UI with the fetched discount
      }
    }
  }

  // Generate a random 8-character order ID
  String _generateOrderID() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(
        8, (index) => characters[random.nextInt(characters.length)]).join();
  }

  // Extract product names from cartItems
  List<String> _getProductNames() {
    return widget.cartItems
        .map((item) => item['productName'] as String)
        .toList();
  }

  Future<void> _deleteCart() async {
    final cartRef = FirebaseFirestore.instance
        .collection('customer')
        .doc(widget.uid)
        .collection('cart');

    final cartItems = await cartRef.get();

    for (var doc in cartItems.docs) {
      await doc.reference.delete();
    }
  }

  // Function to handle the confirm payment button press
  void _onConfirmPaymentPressed() {
    if (widget.orderType.toLowerCase() == 'delivery' && _receiptImage == null) {
      // If the order type is delivery and no receipt is attached, show an error
      _showErrorDialog(
          'Please attach your payment receipt before confirming the payment.');
    } else {
      // Proceed with the payment confirmation logic (e.g., creating the order)
      _createOrder();
    }
  }

  // Function to display an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrder() async {
    String orderID = _generateOrderID();

    // Use the current date and time in the Philippines
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 8));
    Timestamp timestamp = Timestamp.fromDate(now);

    // Format the date for the transactions collection
    String currentDate = DateFormat('MM-dd-yy').format(now);
    String transactionsCollectionName = 'transactions_$currentDate';

    // Order data to be saved in customer orders
    Map<String, dynamic> orderData = {
      'deliveryType': widget.deliveryType,
      'orderID': orderID,
      'orderType': widget.orderType,
      'paymentMethod': widget.paymentMethod,
      'productNames':
          widget.cartItems.map((item) => item['productName']).toList(),
      'timestamp': timestamp,
      'total': widget.totalAmount,
      'voucherCode': widget.voucherCode,
    };

    try {
      // Create the order in Firestore
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('orders')
          .doc(orderID)
          .set(orderData);

      // Create the notification in Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(orderID)
          .set(orderData);

      // Calculate raw material costs and profit for each product
      List<Map<String, dynamic>> rawMatCostPerProd =
          await _calculateRawMatCosts(
              widget.cartItems.cast<Map<String, dynamic>>());

      // Calculate the total raw material cost, product cost, and total net profit
      double totalRawMatCost =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['rawMatCost']);
      double totalProdCost =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['prodCost']);

      // Calculate total net profit by summing the netProfit of each product
      double totalNetProfit =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['netProfit']);

      // Create the transaction document
      Map<String, dynamic> transactionData = {
        'totalRawMatCost': totalRawMatCost,
        'prodCost': totalProdCost,
        'totalNetProfit':
            totalNetProfit, // Add totalNetProfit to transaction data
        'matCostPerProduct': rawMatCostPerProd,
      };

      // Save the transaction data in Firestore
      await FirebaseFirestore.instance
          .collection(transactionsCollectionName)
          .doc(orderID)
          .set(transactionData);

      // Update the dailySales document in the same transactions collection
      await _updateDailySales(currentDate, totalProdCost);

      // Update the dailyNetProfit document in the same transactions collection
      await _updateDailyNetProfit(currentDate, totalNetProfit);

      // Update stock from cart items
      await _updateStockFromCartItems();

      // Delete the cart items after order creation
      await _deleteCart();

      // Show success modal directly after completing Firestore operations
      _showPaymentSuccessModal();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to confirm order: $e')));
    }
  }

// Function to update daily sales within the same transactions collection
  Future<void> _updateDailySales(
      String currentDate, double totalProdCost) async {
    // Reference to the document within the transactions collection
    DocumentReference dailySalesDoc = FirebaseFirestore.instance
        .collection('transactions_$currentDate')
        .doc('dailySales');

    try {
      // Fetch the existing daily sales document
      DocumentSnapshot snapshot = await dailySalesDoc.get();

      if (snapshot.exists) {
        // If document exists, update the sales field by adding the new totalProdCost
        double existingSales = snapshot['sales'] ?? 0.0;
        await dailySalesDoc.update({
          'sales': existingSales + totalProdCost,
        });
      } else {
        // If document doesn't exist, create a new document with the sales value
        await dailySalesDoc.set({
          'sales': totalProdCost,
        });
      }
    } catch (e) {
      print('Error updating daily sales: $e');
    }
  }

// Function to update daily net profit within the same transactions collection
  Future<void> _updateDailyNetProfit(
      String currentDate, double totalNetProfit) async {
    // Reference to the document within the transactions collection
    DocumentReference dailyNetProfitDoc = FirebaseFirestore.instance
        .collection('transactions_$currentDate')
        .doc('dailyNetProfit');

    try {
      // Fetch the existing daily net profit document
      DocumentSnapshot snapshot = await dailyNetProfitDoc.get();

      if (snapshot.exists) {
        // If document exists, update the netProfit field by adding the new totalNetProfit
        double existingNetProfit = snapshot['netProfit'] ?? 0.0;
        await dailyNetProfitDoc.update({
          'netProfit': existingNetProfit + totalNetProfit,
        });
      } else {
        // If document doesn't exist, create a new document with the netProfit value
        await dailyNetProfitDoc.set({
          'netProfit': totalNetProfit,
        });
      }
    } catch (e) {
      print('Error updating daily net profit: $e');
    }
  }

// Helper function to calculate raw material costs for each product
  Future<List<Map<String, dynamic>>> _calculateRawMatCosts(
      List<Map<String, dynamic>> cartItems) async {
    List<Map<String, dynamic>> costs = [];

    for (var item in cartItems) {
      String productName = item['productName'];
      double prodCost = item['total'] ?? 0.0; // Total from buildCartItems

      // Fetch product details from Firestore
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productName', isEqualTo: productName)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        DocumentSnapshot productDoc = productSnapshot.docs.first;

        List ingredients = productDoc['ingredients'];
        double rawMatCost = 0.0;

        List<Map<String, dynamic>> productIngredients = [];

        for (var ingredient in ingredients) {
          String ingredientName = ingredient['name'];
          String quantityString = ingredient['quantity'];
          double quantity = double.tryParse(quantityString.split(' ')[0]) ?? 0;

          // Extract unit from the quantity (e.g., "ml", "grams", "liters")
          String unit = quantityString.split(' ')[1];

          // Log ingredient and quantity
          print('Ingredient: ${ingredient['name']}, Quantity: $quantity $unit');

          // Fetch raw material details
          DocumentSnapshot rawMaterialDoc = await FirebaseFirestore.instance
              .collection('rawStock')
              .doc(ingredientName)
              .get();

          if (rawMaterialDoc.exists) {
            double costPerMl = rawMaterialDoc['costPerMl'] ?? 0.0; // costPerMl
            double costPerGram =
                rawMaterialDoc['costPerGram'] ?? 0.0; // costPerGram
            double costPerLiter =
                rawMaterialDoc['costPerLiter'] ?? 0.0; // costPerLiter
            double pricePerUnit = rawMaterialDoc['pricePerUnit'] ?? 0.0;
            double conversionRate = rawMaterialDoc['conversionRate'] ?? 1.0;

            // Log raw material document values
            print(
                'Raw Material: $ingredientName, Unit: ${rawMaterialDoc['unit']}');
            print(
                'costPerMl: $costPerMl, costPerGram: $costPerGram, costPerLiter: $costPerLiter');

            double cost = 0.0;

            // Calculate cost based on unit
            if (unit == 'ml') {
              cost = (quantity * costPerMl); // Calculate cost using costPerMl
              print('Cost for $ingredientName (ml): $cost');
            } else if (unit == 'grams') {
              cost =
                  (quantity * costPerGram); // Calculate cost using costPerGram
              print('Cost for $ingredientName (grams): $cost');
            } else if (unit == 'liters') {
              cost = (quantity *
                  costPerLiter); // Calculate cost using costPerLiter
              print('Cost for $ingredientName (liters): $cost');
            } else {
              // Fallback to the existing logic for other units
              cost = (quantity / conversionRate) * pricePerUnit;
              print('Fallback cost for $ingredientName: $cost');
            }

            rawMatCost += cost;

            productIngredients.add({
              'name': ingredientName,
              'quantity': ingredient[
                  'quantity'], // Keep the full quantity string like "150 ml"
              'cost': cost,
            });
          }
        }

        double netProfit = prodCost - rawMatCost;

        costs.add({
          'productName': productName,
          'rawMatCost': rawMatCost,
          'prodCost': prodCost,
          'netProfit': netProfit,
          'productIngredients': productIngredients,
        });
      }
    }

    return costs;
  }

  Future<void> _updateStockFromCartItems() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Step 1: Fetch all product names from cart items
    List<String> productNames = _getProductNames();

    // Step 2: Fetch all product details in parallel
    List<QuerySnapshot> productSnapshots = await Future.wait(
      productNames.map(
        (productName) => FirebaseFirestore.instance
            .collection('products')
            .where('productName', isEqualTo: productName)
            .limit(1)
            .get(),
      ),
    );

    // Step 3: Collect all raw material stock IDs needed
    Set<String> rawStockIds = {};
    for (var productSnapshot in productSnapshots) {
      if (productSnapshot.docs.isNotEmpty) {
        var productDoc = productSnapshot.docs.first;
        var ingredients = productDoc['ingredients'];
        for (var ingredient in ingredients) {
          rawStockIds.add(ingredient['name']);
        }
      }
    }

    // Step 4: Fetch all required raw material documents in one query
    List<DocumentSnapshot> rawMaterialDocs = await Future.wait(
      rawStockIds.map(
        (matName) => FirebaseFirestore.instance
            .collection('rawStock')
            .doc(matName)
            .get(),
      ),
    );

    // Convert raw material docs to a map for quick access
    Map<String, DocumentSnapshot> rawMaterialMap = {
      for (var doc in rawMaterialDocs) doc.id: doc,
    };

    // Step 5: Process and prepare stock updates
    for (var productSnapshot in productSnapshots) {
      if (productSnapshot.docs.isNotEmpty) {
        var productDoc = productSnapshot.docs.first;
        var ingredients = productDoc['ingredients'];

        for (var ingredient in ingredients) {
          String matName = ingredient['name'];
          String ingredientQuantityStr = ingredient['quantity'];
          List<String> quantityParts = ingredientQuantityStr.split(' ');
          double ingredientQuantity = double.tryParse(quantityParts[0]) ?? 0.0;
          String ingredientUnit = quantityParts[1];

          if (rawMaterialMap.containsKey(matName)) {
            var rawMaterialDoc = rawMaterialMap[matName]!;
            double availableStock =
                double.tryParse(rawMaterialDoc['quantity'].toString()) ?? 0.0;
            String stockUnit = rawMaterialDoc['unit'];
            double conversionRate =
                double.tryParse(rawMaterialDoc['conversionRate'].toString()) ??
                    1.0;

            // Handle unit conversion
            double ingredientQuantityInStockUnit = (stockUnit != ingredientUnit)
                ? ingredientQuantity / conversionRate
                : ingredientQuantity;

            if (availableStock >= ingredientQuantityInStockUnit) {
              batch.update(
                FirebaseFirestore.instance.collection('rawStock').doc(matName),
                {'quantity': availableStock - ingredientQuantityInStockUnit},
              );
            } else {
              print(
                  "Insufficient stock for $matName. Needed: $ingredientQuantityInStockUnit, Available: $availableStock.");
            }
          }
        }
      }
    }

    // Step 6: Commit all updates in a single batch
    await batch.commit();
  }

  void _showPaymentSuccessModal() {
    if (!mounted) return; // Check if the widget is still mounted
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to take more space if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment Successful',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Your order is now being processed.'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      // Navigate to Track Order page (you might need to create this page)
                    },
                    child: Text('Track Order', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerMainHome(
                            userName: widget.userName,
                            emailAddress: widget.emailAddress,
                            email: widget.email,
                            imageUrl: widget.imageUrl,
                            uid: widget.uid,
                            userAddress: widget.userAddress,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                        ),
                      );
                    },
                    child: Text('Back to Home', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Payment'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Order Summary Title
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15),

            // Cart Items
            _buildSectionTitle('Cart Items'),
            _buildCartItems(),

            SizedBox(height: 20),

            // Delivery and Payment Details
            _buildSectionTitle('Order & Payment Details'),
            _buildDetailsRow('Order Type:', widget.deliveryType),
            _buildDetailsRow('Payment Method:', widget.paymentMethod),
            if (widget.voucherCode.isNotEmpty) ...[
              _buildDetailsRow('Voucher Code:', widget.voucherCode),
            ],
            _buildDetailsRow(
                'Total Amount:', '₱${widget.totalAmount.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            // User Information
            _buildSectionTitle('User Information'),
            _buildDetailsRow('Name:', widget.userName),
            _buildDetailsRow('Address:', widget.userAddress),
            _buildDetailsRow('Email:', widget.emailAddress),

            SizedBox(height: 20),

            // Order Information
            _buildSectionTitle('Order Information'),
            _buildDetailsRow('Order Type:', widget.orderType),

            SizedBox(height: 30),

            // If Order Type is Delivery, show payment receipt section
            if (widget.orderType.toLowerCase() == 'delivery') ...[
              _buildSectionTitle('Attach Payment Receipt'),
              _buildPaymentReceiptSection(),
            ],

            SizedBox(height: 30),

            // Confirm Payment Button
            ElevatedButton(
              onPressed: _onConfirmPaymentPressed, // Validate before confirming
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[300]!, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: widget.cartItems.map((item) {
          final total = item['total'] ?? 0.0;
          final sizeQuantity = item['sizeQuantity'] ?? 'N/A';
          final quantity = item['quantity'] ?? 1;

          final size = (sizeQuantity == 'Small' ||
                  sizeQuantity == 'Medium' ||
                  sizeQuantity == 'Large')
              ? sizeQuantity
              : item['size'] ?? 'N/A';

          final variant = (sizeQuantity == '4 pcs' ||
                  sizeQuantity == '8 pcs' ||
                  sizeQuantity == '12 pcs')
              ? sizeQuantity
              : 'N/A';

          final productName = item['productName']; // Get the productName
          List<dynamic> ingredients = [];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .where('productName',
                      isEqualTo: productName) // Query by productName
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // While waiting for data
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('Product not found');
                }

                // Now that we have the correct document, fetch its productID
                DocumentSnapshot productDoc = snapshot.data!.docs.first;
                Map<String, dynamic> productData =
                    productDoc.data() as Map<String, dynamic>;

                // Fetch ingredients
                ingredients = productData['ingredients'] ?? [];

                // Pass the ingredients to _calculateRawMatCosts
                _calculateRawMatCosts([
                  {
                    'productName': productName,
                    'total': total,
                    'ingredients': ingredients,
                    'quantity': quantity,
                  }
                ]);

                return ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    item['productName'],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    if (variant != 'N/A')
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Variant: $variant',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    if (size != 'N/A')
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Size: $size',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Qty: $quantity',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Total: ₱${total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    if (ingredients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ingredients:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              ...ingredients.map<Widget>((ingredient) {
                                final ingredientName =
                                    ingredient['name'] ?? 'Unknown';
                                final ingredientQuantity =
                                    ingredient['quantity'] ?? 'N/A';
                                return Text(
                                  '- $ingredientName: $ingredientQuantity',
                                  style: TextStyle(fontSize: 14),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // New section for attaching payment receipt
  Widget _buildPaymentReceiptSection() {
    return Column(
      children: [
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _pickReceiptImage, // Handle image picking
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Attach GCash Receipt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (_receiptImage != null) ...[
          SizedBox(height: 15),
          Image.file(_receiptImage!), // Display the selected image
        ]
      ],
    );
  }
}

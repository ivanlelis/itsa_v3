import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:itsa_food_app/main_home/customer_home.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ConfirmPayment extends StatefulWidget {
  final List<dynamic> cartItems;
  final String deliveryType;
  final String paymentMethod;
  final String voucherCode;
  final double totalAmount;
  final String? uid;
  final String? userName;
  final String? userAddress;
  final String? emailAddress;
  final double latitude;
  final double longitude;
  final String orderType;
  final String? email;
  final String? imageUrl;
  final String? selectedItemName;
  final String? branchID;

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
    this.selectedItemName,
    required this.branchID,
  });

  @override
  _ConfirmPaymentState createState() => _ConfirmPaymentState();
}

class _ConfirmPaymentState extends State<ConfirmPayment> {
  String discountDescription = '';
  String? selectedItemName;
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

  void _onConfirmPaymentPressed() {
    if ((widget.orderType.toLowerCase() == 'delivery' ||
            widget.orderType.toLowerCase() == 'pickup') &&
        widget.paymentMethod.toLowerCase() == 'gcash' &&
        _receiptImage == null) {
      // If order type is delivery or pickup, payment method is GCash, and no receipt is attached, show an error
      _showErrorDialog(
          'Please attach your payment receipt before confirming the payment.');
    } else {
      // No need to pass selectedItemName anymore, use the class-level variable directly
      _createOrder(_receiptImage);
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

  Future<void> _createOrder(File? paymentReceiptImage) async {
    String orderID = _generateOrderID();
    String documentName = widget.selectedItemName == null
        ? orderID
        : "exBundle-$orderID"; // Access widget.selectedItemName

    // Use the current date and time in the Philippines
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 8));
    Timestamp timestamp = Timestamp.fromDate(now);

    // Format the date for the transactions subcollection
    String currentDate = DateFormat('MM_dd_yy').format(now);
    String transactionsSubCollectionName = 'transactions_$currentDate';

    try {
      String paymentReceiptUrl = '';

      // Only upload the payment receipt if order type is "delivery" or "pickup" and payment method is "GCash"
      if ((widget.orderType.toLowerCase() == 'delivery' ||
              widget.orderType.toLowerCase() == 'pickup') &&
          widget.paymentMethod.toLowerCase() == 'gcash' &&
          paymentReceiptImage != null) {
        // Step 1: Upload the payment receipt to Firebase Storage
        String userName = widget.userName ?? 'Guest'; // Assuming user's name is available
        String fileName =
            '$userName-${DateFormat('yyyyMMdd_HHmmss').format(now)}.png';

        // Upload the file
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('payment_receipts')
            .child(fileName);
        UploadTask uploadTask = storageRef.putFile(paymentReceiptImage);
        TaskSnapshot snapshot = await uploadTask;

        // Get the download URL
        paymentReceiptUrl = await snapshot.ref.getDownloadURL();
      }

      // Step 2: Prepare the order data with quantity and branchID
      Map<String, dynamic> orderData = {
        'deliveryType': widget.deliveryType,
        'orderID': orderID,
        'orderType': widget.orderType,
        'paymentMethod': widget.paymentMethod,
        'products': widget.cartItems.map((item) {
          return {
            'productName': item['productName'],
            'quantity': item['quantity'], // Include the quantity
          };
        }).toList(),
        'timestamp': timestamp,
        'total': widget.totalAmount,
        'voucherCode': widget.voucherCode,
        'status': 'pending',
        if ((widget.orderType.toLowerCase() == 'delivery' ||
                widget.orderType.toLowerCase() == 'pickup') &&
            widget.paymentMethod.toLowerCase() == 'gcash')
          'paymentReceipt': paymentReceiptUrl,
        if (widget.selectedItemName != null)
          'exBundle': widget.selectedItemName, // Use widget.selectedItemName
        'branchID': widget.branchID, // Add branchID to the order data
      };

      // Step 3: Create the order in Firestore
      await FirebaseFirestore.instance
          .collection('customer')
          .doc(widget.uid)
          .collection('orders')
          .doc(documentName) // Use dynamic document name
          .set(orderData);

      // Step 4: Create the notification in Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(documentName) // Use dynamic document name
          .set(orderData);

      // Step 5: Calculate raw material costs and save the transaction
      List<Map<String, dynamic>> rawMatCostPerProd =
          await _calculateRawMatCosts(
              widget.cartItems.cast<Map<String, dynamic>>());

      double totalRawMatCost =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['rawMatCost']);
      double totalProdCost =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['prodCost']);
      double totalNetProfit =
          rawMatCostPerProd.fold(0, (sum, item) => sum + item['netProfit']);

      Map<String, dynamic> transactionData = {
        'totalRawMatCost': totalRawMatCost,
        'prodCost': totalProdCost,
        'totalNetProfit': totalNetProfit,
        'matCostPerProduct': rawMatCostPerProd,
      };

      // Save the transaction data in the transactions collection and subcollection
      await FirebaseFirestore.instance
          .collection('transactions') // Top-level collection
          .doc('transactions') // Use a placeholder for the top-level document
          .collection(transactionsSubCollectionName) // Subcollection
          .doc(orderID) // Document created inside the subcollection
          .set(transactionData);

      await _updateDailySales(currentDate, totalProdCost);
      await _updateDailyNetProfit(currentDate, totalNetProfit);

      // Step 6: Update stock and clear the cart
      await _updateStockFromCartItems();
      await _deleteCart();

      // Step 7: Show success modal
      _showPaymentSuccessModal();
    } catch (e) {
      print('Error creating order: $e');
    }
  }

  Future<void> _updateDailySales(
      String currentDate, double totalProdCost) async {
    // Reference to the document within the 'transactions' collection
    DocumentReference dailySalesDoc = FirebaseFirestore.instance
        .collection('transactions') // Top-level collection
        .doc('transactions') // Using the orderID as the document ID
        .collection(
            'transactions_$currentDate') // Subcollection with the current date
        .doc('dailySales');

    try {
      // Fetch the existing daily sales document
      DocumentSnapshot snapshot = await dailySalesDoc.get();

      if (snapshot.exists) {
        // If document exists, update the sales field by adding the new totalProdCost
        double existingSales = (snapshot['sales'] ?? 0.0).toDouble();
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

  Future<void> _updateDailyNetProfit(
      String currentDate, double totalNetProfit) async {
    // Reference to the document within the 'transactions' collection
    DocumentReference dailyNetProfitDoc = FirebaseFirestore.instance
        .collection('transactions') // Top-level collection
        .doc('transactions') // Using the orderID as the document ID
        .collection(
            'transactions_$currentDate') // Subcollection with the current date
        .doc('dailyNetProfit');

    try {
      // Fetch the existing daily net profit document
      DocumentSnapshot snapshot = await dailyNetProfitDoc.get();

      if (snapshot.exists) {
        // If document exists, update the netProfit field by adding the new totalNetProfit
        double existingNetProfit = (snapshot['netProfit'] ?? 0.0).toDouble();
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

  Future<List<Map<String, dynamic>>> _calculateRawMatCosts(
      List<Map<String, dynamic>> cartItems) async {
    List<Map<String, dynamic>> costs = [];

    // Determine collections based on branchID
    String productsCollection = 'products';
    String rawStockCollection = 'rawStock';
    if (widget.branchID == 'branch 2') {
      productsCollection = 'products_branch1';
      rawStockCollection = 'rawStock_branch1';
    } else if (widget.branchID == 'branch 3') {
      productsCollection = 'products_branch2';
      rawStockCollection = 'rawStock_branch2';
    }

    for (var item in cartItems) {
      String productName = item['productName'];
      double prodCost =
          item['total']?.toDouble() ?? 0.0; // Ensure prodCost is a double

      // Fetch product details from Firestore based on branchID
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection(productsCollection)
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
          // Extracting quantity and unit
          String quantityString = ingredient['quantity'];
          double quantity =
              double.tryParse(quantityString.split(' ')[0]) ?? 0.0;
          String unit = quantityString.split(' ')[1];

// Log ingredient and quantity
          print('Ingredient: ${ingredient['name']}, Quantity: $quantity $unit');

// Check raw material cost calculation
          DocumentSnapshot rawMaterialDoc = await FirebaseFirestore.instance
              .collection(rawStockCollection)
              .doc(ingredientName)
              .get();

          if (rawMaterialDoc.exists) {
            double costPerUnit =
                (rawMaterialDoc['pricePerUnit'] ?? 0.0).toDouble();

            double cost = 0.0;

            if (unit == 'pcs') {
              // If unit is pcs (pieces), directly calculate based on pricePerUnit
              cost = quantity * costPerUnit;
            } else if (unit == 'grams') {
              cost = quantity * (rawMaterialDoc['costPerGram'] ?? 0.0);
            } else if (unit == 'ml') {
              cost = quantity * (rawMaterialDoc['costPerMl'] ?? 0.0);
            } else if (unit == 'liters') {
              cost = quantity * (rawMaterialDoc['costPerLiter'] ?? 0.0);
            } else {
              cost = (quantity / (rawMaterialDoc['conversionRate'] ?? 1.0)) *
                  costPerUnit;
            }

            rawMatCost += cost; // Add to the total raw material cost
            productIngredients.add({
              'name': ingredientName,
              'quantity': ingredient['quantity'],
              'cost': cost,
            });
          }
        }

        // Calculate net profit: Product cost - Raw material cost
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

  Future<Map<String, dynamic>> freeRawMatCost(String selectedItemName) async {
    // Determine collections based on branchID
    String productsCollection = 'products';
    String rawStockCollection = 'rawStock';
    if (widget.branchID == 'branch 2') {
      productsCollection = 'products_branch1';
      rawStockCollection = 'rawStock_branch1';
    } else if (widget.branchID == 'branch 3') {
      productsCollection = 'products_branch2';
      rawStockCollection = 'rawStock_branch2';
    }

    // Fetch product details from Firestore for the selected item
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collection(productsCollection)
        .where('productName', isEqualTo: selectedItemName)
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

        String unit = quantityString.split(' ')[1];

        // Log ingredient and quantity
        print('Ingredient: ${ingredient['name']}, Quantity: $quantity $unit');

        // Fetch raw material details based on branchID
        DocumentSnapshot rawMaterialDoc = await FirebaseFirestore.instance
            .collection(rawStockCollection)
            .doc(ingredientName)
            .get();

        if (rawMaterialDoc.exists) {
          double costPerMl = rawMaterialDoc['costPerMl'] ?? 0.0;
          double costPerGram = rawMaterialDoc['costPerGram'] ?? 0.0;
          double costPerLiter = rawMaterialDoc['costPerLiter'] ?? 0.0;
          double pricePerUnit = rawMaterialDoc['pricePerUnit'] ?? 0.0;
          double conversionRate = rawMaterialDoc['conversionRate'] ?? 1.0;

          double cost = 0.0;

          if (unit == 'ml') {
            cost = quantity * costPerMl;
          } else if (unit == 'grams') {
            cost = quantity * costPerGram;
          } else if (unit == 'liters') {
            cost = quantity * costPerLiter;
          } else {
            cost = (quantity / conversionRate) * pricePerUnit;
          }

          rawMatCost += cost;

          productIngredients.add({
            'name': ingredientName,
            'quantity': ingredient['quantity'],
            'cost': cost,
          });
        }
      }

      return {
        'freeItem': selectedItemName,
        'freeRawMatCost': rawMatCost,
        'productIngredients': productIngredients,
      };
    } else {
      throw Exception(
          'Product with name $selectedItemName not found in Firestore');
    }
  }

  Future<void> _updateStockFromCartItems({String? selectedItemName}) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Step 1: Fetch all product names from cart items
    List<String> productNames = _getProductNames();

    // Step 2: Include selectedItemName if provided
    if (selectedItemName != null) {
      productNames.add(selectedItemName);
    }

    // Step 3: Determine the correct collection names based on branchID
    String productsCollection = 'products';
    String rawStockCollection = 'rawStock';

    if (widget.branchID == "branch 2") {
      productsCollection = 'products_branch1';
      rawStockCollection = 'rawStock_branch1';
    } else if (widget.branchID == "branch 3") {
      productsCollection = 'products_branch2';
      rawStockCollection = 'rawStock_branch2';
    }

    // Step 4: Fetch all product details in parallel
    List<QuerySnapshot> productSnapshots = await Future.wait(
      productNames.map(
        (productName) => FirebaseFirestore.instance
            .collection(productsCollection)
            .where('productName', isEqualTo: productName)
            .limit(1)
            .get(),
      ),
    );

    // Step 5: Collect all raw material stock IDs needed
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

    // Step 6: Fetch all required raw material documents in one query
    List<DocumentSnapshot> rawMaterialDocs = await Future.wait(
      rawStockIds.map(
        (matName) => FirebaseFirestore.instance
            .collection(rawStockCollection)
            .doc(matName)
            .get(),
      ),
    );

    // Convert raw material docs to a map for quick access
    Map<String, DocumentSnapshot> rawMaterialMap = {
      for (var doc in rawMaterialDocs) doc.id: doc,
    };

    // Step 7: Process and prepare stock updates
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
                FirebaseFirestore.instance
                    .collection(rawStockCollection)
                    .doc(matName),
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

    // Step 8: Commit all updates in a single batch
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
                            branchID: widget.branchID,
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
        title: Text(
          'Confirm Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
            color: Colors.white, // Sets the text color to white
          ),
        ),
        backgroundColor: Color(0xFF6E473B), // Set AppBar color to #6E473B
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
                color: Color(0xFF6E473B), // Title color set to #6E473B
              ),
            ),
            SizedBox(height: 15),

            // Cart Items
            _buildSectionTitle('Cart Items'),
            _buildCartItems(widget.selectedItemName ?? '',
                widget.branchID ?? ''), // Pass selectedItemName here

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
            _buildDetailsRow('Name:', widget.userName ?? ''),
            _buildDetailsRow('Address:', widget.userAddress ?? ''),
            _buildDetailsRow('Email:', widget.emailAddress ?? ''),
            _buildDetailsRow(
                'Selected Item:', widget.selectedItemName ?? 'none'),

            SizedBox(height: 20),

            // Order Information
            _buildSectionTitle('Order Information'),
            _buildDetailsRow('Order Type:', widget.orderType),

            SizedBox(height: 30),

            // Show payment receipt section if order type is "delivery" or "pickup" and payment method is "GCash"
            if ((widget.orderType.toLowerCase() == 'delivery' ||
                    widget.orderType.toLowerCase() == 'pickup') &&
                widget.paymentMethod.toLowerCase() == 'gcash') ...[
              _buildSectionTitle('Attach Payment Receipt'),
              _buildPaymentReceiptSection(),
            ],

            SizedBox(height: 30),

            // Confirm Payment Button
            ElevatedButton(
              onPressed: () {
                // No need to pass selectedItemName anymore
                _onConfirmPaymentPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color(0xFF6E473B), // Set button color to #A78D78
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for button
                ),
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

  Widget _buildCartItems(String? selectedItemName, String branchID) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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

          // Determine the collection name based on branchID
          String productsCollection = 'products'; // Default to 'products'
          if (branchID == "branch 2") {
            productsCollection = 'products_branch1';
          } else if (branchID == "branch 3") {
            productsCollection = 'products_branch2';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection(productsCollection) // Use dynamic collection name
                  .where('productName', isEqualTo: productName)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Product not found');
                }

                DocumentSnapshot productDoc = snapshot.data!.docs.first;
                Map<String, dynamic> productData =
                    productDoc.data() as Map<String, dynamic>;

                ingredients = productData['ingredients'] ?? [];

                _calculateRawMatCosts([
                  {
                    'productName': productName,
                    'total': total,
                    'ingredients': ingredients,
                    'quantity': quantity,
                  }
                ]);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        item['productName'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        // Display Selected Item inside the ExpansionTile
                        if (selectedItemName != null &&
                            selectedItemName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Exclusive Bundle: Free $selectedItemName Regular Milktea',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        if (variant != 'N/A')
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, bottom: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Variant: $variant',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        if (size != 'N/A')
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, bottom: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Size: $size',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 16.0, bottom: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quantity: $quantity',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 16.0, bottom: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Total: ₱${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        if (ingredients.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, bottom: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ingredients:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...ingredients.map<Widget>((ingredient) {
                                    final ingredientName =
                                        ingredient['name'] ?? 'Unknown';
                                    final ingredientQuantity =
                                        ingredient['quantity'] ?? 'N/A';
                                    return Text(
                                      '- $ingredientName: $ingredientQuantity',
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                      ],
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

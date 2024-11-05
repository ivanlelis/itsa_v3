import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductAnalyticsService {
  final _firestore = FirebaseFirestore.instance;
  final Map<String, List<Map<String, dynamic>>> _productOrderHistory =
      {}; // To store history of product orders over time
  final _productOrderCountsController =
      StreamController<Map<String, List<Map<String, dynamic>>>>.broadcast();

  ProductAnalyticsService() {
    _initializeListener();
  }

  // Real-time listener for Firestore changes across all customer orders
  void _initializeListener() {
    _firestore.collection('customer').snapshots().listen((customerSnapshot) {
      for (var customerDoc in customerSnapshot.docs) {
        customerDoc.reference
            .collection('orders')
            .snapshots()
            .listen((orderSnapshot) {
          for (var docChange in orderSnapshot.docChanges) {
            final data = docChange.doc.data();
            if (data != null) {
              _updateProductCount(data['productNames']);
            }
          }
          _productOrderCountsController.add(_productOrderHistory);
        });
      }
    });
  }

  void _updateProductCount(List<dynamic> productNames) {
    final timestamp = DateTime.now();
    for (var productName in productNames) {
      final productId = productName as String;

      // Ensure the list for this productId is initialized
      _productOrderHistory.putIfAbsent(productId, () => []);

      // Retrieve the current count, if there is any history data for this product
      int currentCount = (_productOrderHistory[productId] != null &&
              _productOrderHistory[productId]!.isNotEmpty)
          ? _productOrderHistory[productId]!.last['count']
          : 0;

      // Add the new entry with incremented count
      _productOrderHistory[productId]!.add({
        'time': timestamp,
        'count': currentCount + 1,
      });
    }
  }

  Stream<Map<String, List<Map<String, dynamic>>>>
      get productOrderCountsStream => _productOrderCountsController.stream;

  void dispose() {
    _productOrderCountsController.close();
  }
}

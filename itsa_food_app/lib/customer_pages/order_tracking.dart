import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTracking extends StatefulWidget {
  final String orderID;

  const OrderTracking({super.key, required this.orderID});

  @override
  _OrderTrackingState createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTracking> {
  late GoogleMapController _mapController;
  late LatLng _riderLocation;
  late LatLng _destinationLocation;
  late String _riderName;
  late String _estimatedTime;

  @override
  void initState() {
    super.initState();
    _riderLocation = LatLng(0.0, 0.0); // Default location
    _destinationLocation = LatLng(0.0, 0.0); // Default destination
    _riderName = '';
    _estimatedTime = '';
    _getOrderTrackingDetails();
  }

  // Fetch order details from Firestore
  Future<void> _getOrderTrackingDetails() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderID)
          .get();

      if (orderSnapshot.exists) {
        var orderData = orderSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _riderLocation = LatLng(orderData['riderLocation']['latitude'],
              orderData['riderLocation']['longitude']);
          _destinationLocation = LatLng(
              orderData['destinationLocation']['latitude'],
              orderData['destinationLocation']['longitude']);
          _riderName = orderData['riderName'];
          _estimatedTime = orderData['estimatedDelivery'];
        });

        _mapController.animateCamera(CameraUpdate.newLatLng(_riderLocation));

        // Listen for rider location updates
        FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderID)
            .snapshots()
            .listen((orderSnapshot) {
          var updatedData = orderSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _riderLocation = LatLng(updatedData['riderLocation']['latitude'],
                updatedData['riderLocation']['longitude']);
          });
          _mapController.animateCamera(CameraUpdate.newLatLng(_riderLocation));
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Tracking'),
        backgroundColor: Color(0xFF6E473B),
      ),
      body: Column(
        children: [
          // Display Rider and Order Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rider: $_riderName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Estimated Delivery: $_estimatedTime',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Destination: $_destinationLocation',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // Google Maps widget
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _riderLocation,
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: MarkerId('rider'),
                  position: _riderLocation,
                  infoWindow: InfoWindow(title: 'Rider Location'),
                ),
                Marker(
                  markerId: MarkerId('destination'),
                  position: _destinationLocation,
                  infoWindow: InfoWindow(title: 'Destination'),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: PolylineId('route'),
                  points: [_riderLocation, _destinationLocation],
                  color: Colors.blue,
                  width: 5,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiderDashboard extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const RiderDashboard({
    Key? key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _RiderDashboardState createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  late GoogleMapController mapController;

  final LatLng _initialPosition =
      LatLng(37.7749, -122.4194); // Default location

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Rider Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildRiderInfo(),
          _buildMapView(),
          _buildOrderList(),
        ],
      ),
    );
  }

  // Rider Information Card
  Widget _buildRiderInfo() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(widget.imageUrl),
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          widget.email,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings, color: Colors.deepOrangeAccent),
          onPressed: () {
            // Navigate to settings or profile edit screen
          },
        ),
      ),
    );
  }

  // Map View with Custom Map Styling
  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 250,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              mapController.setMapStyle(_mapStyle);
            },
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
        ),
      ),
    );
  }

  // Custom Styling for Google Maps
  final String _mapStyle = '''[
    {
      "featureType": "all",
      "elementType": "all",
      "stylers": [
        { "saturation": -80 },
        { "lightness": 10 }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        { "color": "#ff9800" }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        { "color": "#81c784" }
      ]
    }
  ]''';

  // Order List Section
  Widget _buildOrderList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Current Orders",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrangeAccent,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildOrderCard("Order #1", "Delivery to Main Street"),
                  _buildOrderCard("Order #2", "Delivery to 2nd Avenue"),
                  _buildOrderCard("Order #3", "Delivery to 5th Street"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Single Order Card Widget
  Widget _buildOrderCard(String orderId, String destination) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepOrangeAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Icon(Icons.delivery_dining, color: Colors.deepOrangeAccent),
        ),
        title: Text(
          orderId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(destination),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            // Navigate to order details
          },
          child: const Text("View"),
        ),
      ),
    );
  }
}

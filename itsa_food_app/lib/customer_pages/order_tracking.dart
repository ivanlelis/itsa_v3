import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTracking extends StatelessWidget {
  const OrderTracking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Tracking')),
      body: Stack(
        children: [
          // Google map with default location
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  14.4218, 120.9310), // Default location set to Imus, Cavite
              zoom: 14.0,
            ),
            zoomControlsEnabled: false, // Disable zoom in/out buttons
            compassEnabled: false, // Disable compass icon
            markers: {
              Marker(
                markerId: MarkerId('rider'),
                position: LatLng(14.4218, 120.9310), // Rider location
                infoWindow: InfoWindow(title: 'Rider'),
              ),
            },
            myLocationEnabled: true,
          ),
          // Card at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'No rider available in your area right now.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

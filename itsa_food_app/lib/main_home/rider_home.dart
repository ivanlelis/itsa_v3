import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:itsa_food_app/widgets/rider_sidebar.dart';

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

  final LatLng _initialPosition = LatLng(14.5314, 120.9832);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      drawer: RiderDrawer(
        userName: widget.userName,
        email: widget.email,
        imageUrl: widget.imageUrl,
      ),
      body: Stack(
        children: [
          _buildMapView(),
          _buildTopBar(),
          _buildNavigateButton(),
          _buildOrderDetailCard(),
        ],
      ),
    );
  }

  // Map View with Custom Map Styling
  Widget _buildMapView() {
    return Positioned.fill(
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
    );
  }

  // Top bar with Rider status, smaller menu button in a square container, and notification icon in a circular container
  Widget _buildTopBar() {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Smaller Menu Icon in White Rounded Square Container
          Container(
            width: 40, // Set a smaller fixed width and height
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu,
                  color: Colors.deepOrangeAccent,
                  size: 20), // Reduced icon size
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          // Rider Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 8),
                Text("Online", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Notification Icon in White Circular Container
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width:
                    40, // Set a smaller fixed width and height for the circular container
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications,
                  color: Colors.deepOrangeAccent,
                  size: 20, // Reduced icon size
                ),
              ),
              // Optional: Small red dot for notification badge
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigate button
  Widget _buildNavigateButton() {
    return Positioned(
      bottom: 210,
      left: 16,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate action
        },
        icon: const Icon(Icons.navigation, color: Colors.white),
        label: const Text("Navigate"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent, // Updated from 'primary'
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  // Order Detail Card
  Widget _buildOrderDetailCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "No current order",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Accept an order first",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        "No location pinned yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.phone, color: Colors.deepOrangeAccent),
                    onPressed: () {
                      // Phone action
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "#2326",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey[200], // Updated from 'primary'
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Placeholder action for "No current orders"
                    },
                    child: const Text(
                      "1 item",
                      style: TextStyle(color: Colors.deepOrangeAccent),
                    ),
                  )
                ],
              ),
            ],
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
        { "color": "#a1887f" }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        { "color": "#388e3c" }
      ]
    }
  ]''';
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:itsa_food_app/widgets/rider_sidebar.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // For debouncing
import 'package:geolocator/geolocator.dart';

class RiderDashboard extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;

  const RiderDashboard({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
  });

  @override
  _RiderDashboardState createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  late GoogleMapController mapController;
  final LatLng _initialPosition =
      LatLng(14.5314, 120.9832); // Philippines coordinates
  LatLng? _pinnedLocation;
  LocationData? _currentLocation;
  final Set<Marker> _markers = {};
  final Location _locationService = Location();
  List<LatLng> _routePoints = [];
  final String _apiKey =
      "AIzaSyAvT85VgPqti1JQEr_ca4cV4bZ8xuKrnXA"; // Add your API key here
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  late Timer _debounce; // Timer for debouncing
  String? _routeDuration;
  late LatLng _routeMidpoint;
  ScreenCoordinate? _durationPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Map<String, dynamic>> _routeSteps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _debounce = Timer(Duration.zero, () {});
    _subscribeToLocationChanges();
  }

  void _subscribeToLocationChanges() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = LocationData.fromMap({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });

      // Check if re-routing is needed
      _rerouteIfNeeded(currentLatLng);

      if (_currentLocation != null && _routeSteps.isNotEmpty) {
        // Check if rider is near the current step and move to next step if so
        if (_isRiderNearStep(currentLatLng)) {
          _nextStep();
        }

        // Move the map camera to the updated position
        mapController.animateCamera(
          CameraUpdate.newLatLng(currentLatLng),
        );
      }
    });
  }

  bool _isRiderNearStep(LatLng riderPosition) {
    if (_currentStepIndex >= _routeSteps.length) return false;

    // Assuming route step contains a "location" key with lat/lng values
    final stepLocation = _routePoints[_currentStepIndex];
    const double distanceThreshold = 30.0; // Distance in meters

    final distance = Geolocator.distanceBetween(
      riderPosition.latitude,
      riderPosition.longitude,
      stepLocation.latitude,
      stepLocation.longitude,
    );

    return distance <= distanceThreshold;
  }

  void _rerouteIfNeeded(LatLng currentLatLng) async {
    const double rerouteDistanceThreshold =
        50.0; // Distance threshold in meters

    // Find the closest point on the route to the current location
    double minDistance = double.infinity;
    for (LatLng routePoint in _routePoints) {
      double distance = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If the rider is too far from the route, trigger a re-route
    if (minDistance > rerouteDistanceThreshold) {
      await _calculateRoute(); // Recalculate route from current location to pinned location
      setState(() {
        _currentStepIndex = 0; // Reset to the first step of the new route
      });
    }
  }

  void _initializeLocation() async {
    final permissionGranted = await _locationService.requestPermission();
    if (permissionGranted == PermissionStatus.granted) {
      _locationService.onLocationChanged.listen((locationData) {
        setState(() {
          _currentLocation = locationData;
          _updateCurrentLocationMarker();
        });
      });
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation != null) {
      final riderPosition =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      _markers
          .removeWhere((marker) => marker.markerId.value == "currentLocation");

      _markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: riderPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Your Location"),
      ));

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: riderPosition,
            zoom: 17, // Zoom level for a closer view
            tilt: 60, // Tilt the camera for a 3D effect
            bearing: 192.833, // Set the bearing to simulate forward direction
          ),
        ),
      );
    }
  }

  void _setPinnedLocation(LatLng position) {
    setState(() {
      _pinnedLocation = position;
      _markers.add(Marker(
        markerId: const MarkerId("pinnedLocation"),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Pinned Location"),
      ));
    });
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _pinnedLocation == null) return;

    // Define the current location as the origin for re-routing
    final String directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_pinnedLocation!.latitude},${_pinnedLocation!.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(directionsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Decode the new polyline for the route overview
      final route = data['routes'][0];
      final polyline = route['overview_polyline']['points'];
      _routePoints = _decodePolyline(polyline);

      // Extract total route duration
      final duration = route['legs'][0]['duration']['text'];

      // Parse each step in the new route
      final steps = route['legs'][0]['steps'];
      _routeSteps = steps.map<Map<String, dynamic>>((step) {
        return {
          'instruction': step['html_instructions'],
          'distance': step['distance']['text'],
        };
      }).toList();

      setState(() {
        _routeDuration = duration;
      });

      // Calculate new route midpoint for displaying duration
      if (_routePoints.isNotEmpty) {
        final firstPoint = _routePoints.first;
        final lastPoint = _routePoints.last;
        _routeMidpoint = LatLng(
          (firstPoint.latitude + lastPoint.latitude) / 2,
          (firstPoint.longitude + lastPoint.longitude) / 2,
        );

        mapController
            .getScreenCoordinate(_routeMidpoint)
            .then((screenCoordinate) {
          setState(() {
            _durationPosition = screenCoordinate;
          });
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStepIndex < _routeSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    for (var point in result) {
      points.add(LatLng(point.latitude, point.longitude));
    }
    return points;
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
      });
      return;
    }

    final String searchUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&components=country:PH&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(searchUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API Response: $data"); // Debugging API response
        if (data['status'] == 'OK') {
          setState(() {
            _placeSuggestions = data['predictions'];
          });
        } else {
          print("Error: ${data['status']}"); // Show error if status is not OK
        }
      } else {
        print(
            "Failed to fetch suggestions. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _selectPlace(String placeId) async {
    final String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
    final response = await http.get(Uri.parse(detailsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      final newLocation = LatLng(lat, lng);

      // Move the map to the selected location
      mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
      _setPinnedLocation(newLocation);

      // Close the suggestions after a place is selected
      setState(() {
        _placeSuggestions = [];
      });
    }
  }

  @override
  void dispose() {
    _debounce.cancel(); // Cancel debounce timer when widget is disposed
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

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
          _buildSearchBar(),
          _buildNavigateButton(),
          _buildOrderDetailCard(),

          // Dynamically positioned duration text overlay
          if (_routeDuration != null && _durationPosition != null)
            Positioned(
              left: _durationPosition!.x.toDouble() -
                  50, // Adjust offset as needed
              top: _durationPosition!.y.toDouble() -
                  30, // Adjust offset as needed
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _routeDuration!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          _buildDirectionsCard(),
        ],
      ),
    );
  }

// Helper function to remove HTML tags from instructions
  String _stripHtmlTags(String htmlText) {
    return RegExp(r'<[^>]*>').hasMatch(htmlText)
        ? htmlText.replaceAll(RegExp(r'<[^>]*>'), '')
        : htmlText;
  }

  // Map View with location pins and current location marker
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
        markers: _markers,
        polylines: {
          if (_routePoints.isNotEmpty)
            Polyline(
              polylineId: PolylineId("route"),
              points: _routePoints,
              color: Colors.blue,
              width: 5,
            ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onLongPress: _setPinnedLocation,
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
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Available",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          // Notification Icon with Badge
          Stack(
            children: [
              Container(
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
                child: IconButton(
                  icon: const Icon(Icons.notifications,
                      color: Colors.deepOrangeAccent, size: 20),
                  onPressed: () {},
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search Bar with Debounced Suggestions
  Widget _buildSearchBar() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                if (_debounce.isActive) {
                  _debounce.cancel(); // Cancel previous debounce timer
                }
                _debounce = Timer(const Duration(milliseconds: 800), () {
                  _searchLocation(query);
                });
              },
              decoration: InputDecoration(
                hintText: "Search Location...",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          if (_placeSuggestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Column(
                children: _placeSuggestions.map((suggestion) {
                  final placeName = suggestion['description'];
                  final placeId = suggestion['place_id'];
                  return ListTile(
                    title: Text(placeName),
                    onTap: () => _selectPlace(placeId),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionsCard() {
    // Check if there are steps to show and that the current step index is within range
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) {
      return SizedBox.shrink(); // No steps to show
    }

    // Get the current step based on _currentStepIndex
    final currentStep = _routeSteps[_currentStepIndex];

    // Convert HTML instructions to plain text
    final instruction =
        currentStep['instruction'].replaceAll(RegExp(r'<[^>]*>'), '');

    return Positioned(
      bottom: 145, // Position above the Navigate button
      left: 16,
      right: 16,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Directions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      instruction,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    currentStep['distance'],
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate Button
  Widget _buildNavigateButton() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: _calculateRoute,
        child: const Text("Navigate"),
      ),
    );
  }

  // Order Details Card
  Widget _buildOrderDetailCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: ListTile(
          title: const Text('Order ID: 12345'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Amount: 350 PHP'),
              if (_routeDuration != null) // Display duration if available
                Text('Estimated Duration: $_routeDuration'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  // Map style for the Google Map
  final String _mapStyle = '''[
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#ffffff" // White background
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "on" // Hide icons to keep it clean
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#000000" // Dark text for contrast
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#ffffff" // White text stroke
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#cfcfcf" // Light gray for administrative borders
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#c0c0c0" // Light gray for roads
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#8bc34a" // Green for highways
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#d0d0d0" // Very light gray for local roads
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#a1e8e8" // Light blue for water
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#e0f7fa" // Light teal for points of interest
        }
      ]
    }
  ]''';
}

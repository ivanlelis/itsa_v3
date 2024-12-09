import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:itsa_food_app/widgets/rider_sidebar.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // For debouncing
import 'package:geolocator/geolocator.dart' hide LocationAccuracy;
import 'package:url_launcher/url_launcher.dart';
import 'package:itsa_food_app/widgets/notification_dialog.dart';
import 'package:itsa_food_app/widgets/rider_topbar.dart';
import 'package:itsa_food_app/widgets/map_style.dart';

class RiderDashboard extends StatefulWidget {
  final String userName;
  final String email;
  final String imageUrl;
  final String branchID;

  const RiderDashboard({
    super.key,
    required this.userName,
    required this.email,
    required this.imageUrl,
    required this.branchID,
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
  late Timer _debounce; // Timer for debouncing
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<Map<String, dynamic>> _routeSteps = [];
  int _currentStepIndex = 0;
  final bool _showSearchOverlay = false;
  final List<String> _recentSearches = [];
  final Set<Polyline> _polylines = {};
  Map<String, String>? selectedOrder;

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
        // Check if rider is near the current step and move to the next step if so
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

  void _rerouteIfNeeded(LatLng currentLatLng) async {
    const double rerouteDistanceThreshold = 100.0;

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

    if (minDistance > rerouteDistanceThreshold) {
      await _calculateRoute(); // Ensure this recalculates and updates route
      setState(() {
        _currentStepIndex = 0;
      });
    }
  }

  bool _isRiderNearStep(LatLng riderPosition) {
    if (_currentStepIndex >= _routeSteps.length) return false;

    final stepLocation = _routePoints[_currentStepIndex];
    const double distanceThreshold =
        30.0; // Check if close enough to the current step
    final distance = Geolocator.distanceBetween(
      riderPosition.latitude,
      riderPosition.longitude,
      stepLocation.latitude,
      stepLocation.longitude,
    );

    return distance <= distanceThreshold;
  }

  void _initializeLocation() async {
    final permissionGranted = await _locationService.requestPermission();
    if (permissionGranted == PermissionStatus.granted) {
      _locationService.changeSettings(
        accuracy: LocationAccuracy.high, // High accuracy for better results
        interval: 1000, // Location updates every 1 second
      );

      _locationService.onLocationChanged.listen((locationData) {
        setState(() {
          _currentLocation = locationData;
          _updateCurrentLocationMarker(); // Update marker on the map
        });

        // Check if the user is within the allowed area (Dasmariñas)
        if (_currentLocation != null) {
          _checkIfInAllowedArea(_currentLocation!);
        }
      });
    }
  }

  void _checkIfInAllowedArea(LocationData location) {
    // Define the latitude and longitude boundaries of Dasmariñas
    const double dasmarinasMinLat = 14.2853;
    const double dasmarinasMaxLat = 14.3581;
    const double dasmarinasMinLng = 120.9203;
    const double dasmarinasMaxLng = 120.9917;

    // Check if the user is outside the allowed area
    if (location.latitude! < dasmarinasMinLat ||
        location.latitude! > dasmarinasMaxLat ||
        location.longitude! < dasmarinasMinLng ||
        location.longitude! > dasmarinasMaxLng) {
      _showUnavailableDialog();
    }
  }

  void _showUnavailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Service Unavailable"),
          content: Text(
              "Orders are currently unavailable in your area. Please log in again in your designated area to view orders."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacementNamed(
                    context, '/login'); // Redirect to login
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
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

      // Update polyline on map
      _updatePolyline();
    } else {
      print("Error calculating route: ${response.statusCode}");
    }
  }

  void _checkStepProgress(LatLng currentLatLng) {
    if (_currentStepIndex < _routeSteps.length) {
      // Get the current step's target location (you can use the lat/lng of the step or polyline points)
      LatLng stepLocation = _routePoints[_currentStepIndex];

      // Calculate distance between rider's current location and step location
      Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        stepLocation.latitude,
        stepLocation.longitude,
      );
    }
  }

  void _updatePolyline() {
    // Clear the existing polyline (if any)
    _polylines.clear();

    // Create a new polyline
    final polyline = Polyline(
      polylineId: PolylineId('route'),
      points: _routePoints, // List of LatLng points for the route
      color: Colors.blue, // Set the polyline color
      width: 5, // Set the polyline width
    );

    setState(() {
      _polylines.add(polyline); // Add the new polyline to the set
    });
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

  void _addToRecentSearches(String search) {
    if (!_recentSearches.contains(search)) {
      setState(() {
        _recentSearches.insert(0, search); // Add new search at the start
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast(); // Limit the list to 5 items
        }
      });
      // Save to persistent storage if needed (e.g., SharedPreferences)
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
    double navigateButtonBottom = 120;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      drawer: RiderDrawer(
        userName: widget.userName,
        email: widget.email,
        imageUrl: widget.imageUrl,
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Stack(
            children: [
              _buildMapView(),
              buildTopBar(context),

              // Ensure selectedOrder is not null and handle 'userAddress' nullability
              if (!_showSearchOverlay && selectedOrder != null)
                _buildNavigateButton(
                  navigateButtonBottom,
                  selectedOrder?['userAddress'] ??
                      'No address provided', // Use fallback if null
                ),

              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < 0) {
                      showNotificationDialog(
                        context,
                        widget.branchID,
                        setState,
                        selectedOrder,
                        (newSelectedOrder) {
                          setState(() {
                            selectedOrder =
                                newSelectedOrder; // Update the selected order immediately
                          });
                          print(
                              'Updated Order: $selectedOrder'); // Debugging log to check if it's updated
                        },
                      );
                    }
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        showNotificationDialog(
                          context,
                          widget.branchID,
                          setState,
                          selectedOrder,
                          (newSelectedOrder) {
                            setState(() {
                              selectedOrder = newSelectedOrder;
                            });
                            print(
                                'Updated Order: $selectedOrder'); // Debugging log to check if it's updated
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Check for orders",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Icon(Icons.delivery_dining, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Display selected order details in a card
              if (selectedOrder != null && selectedOrder!.isNotEmpty)
                Positioned(
                  bottom: navigateButtonBottom + 110, // Adjusted position
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivery Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("Order ID: ${selectedOrder!['orderID']}"),
                          Text(
                              "Customer: ${selectedOrder!['firstName']} ${selectedOrder!['lastName']}"),
                          Text("Address: ${selectedOrder!['userAddress']}"),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startNavigation(LatLng pinnedLocation) async {
    // Construct the navigation URL for Google Maps
    final googleMapsUrl =
        'google.navigation:q=${pinnedLocation.latitude},${pinnedLocation.longitude}&mode=d';

    // Launch Google Maps navigation using the URL
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  Future<LatLng?> _getCoordinates(String address) async {
    if (address == 'No address provided') return null;
    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Error fetching coordinates: $e');
    }
    return null;
  }

  String _stripHtmlTags(String htmlText) {
    return RegExp(r'<[^>]*>').hasMatch(htmlText)
        ? htmlText.replaceAll(RegExp(r'<[^>]*>'), '')
        : htmlText;
  }

  Widget _buildMapView() {
    return Positioned.fill(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          mapController = controller;
          mapController.setMapStyle(mapStyle);
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
        onLongPress: _setPinnedLocation,
        zoomControlsEnabled: false, // Removes the zoom buttons
        compassEnabled: false, // Removes the compass icon
      ),
    );
  }

  Widget _buildNavigateButton(double bottom, String address) {
    return Positioned(
      bottom: bottom + 15, // Adjust the position to move the button higher
      right: 16, // Position the button at the right-most side
      child: ElevatedButton(
        onPressed: () async {
          // Convert the address to latitude and longitude
          LatLng? coordinates = await _getCoordinates(address);

          if (coordinates != null) {
            // Pin the location on the map
            _setPinnedLocation(coordinates);

            // Recalculate the route to the new location
            await _calculateRoute();

            // Start the navigation to the pinned location
            _startNavigation(coordinates);
          } else {
            // Handle the case where coordinates could not be obtained
            print("Failed to get coordinates for address: $address");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          minimumSize: Size(56, 56),
          maximumSize: Size(56, 56),
          elevation: 4,
        ),
        child: Icon(
          Icons.navigation,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

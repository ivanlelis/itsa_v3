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
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Map<String, dynamic>> _routeSteps = [];
  int _currentStepIndex = 0;
  final GlobalKey _orderDetailCardKey = GlobalKey();
  bool _showSearchOverlay = false;
  final List<String> _recentSearches = [];
  final Set<Polyline> _polylines = {};

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
        accuracy: LocationAccuracy.high, // Use high accuracy
        interval: 1000, // Update location every 1 second
      );

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
          'instruction':
              step['html_instructions'] ?? 'No instruction available',
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

        // Update map with the new midpoint and adjust camera position
        mapController.animateCamera(CameraUpdate.newLatLngZoom(
            _routeMidpoint, 14)); // Adjust zoom level as needed
      }

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

  Future<void> _selectPlace(String placeId) async {
    final String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
    final response = await http.get(Uri.parse(detailsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      final placeName = data['result']['name']; // Extract place name

      final newLocation = LatLng(lat, lng);

      // Move the map to the selected location
      mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
      _setPinnedLocation(newLocation);

      // Add the place name to recent searches
      _addToRecentSearches(placeName);

      // Close the suggestions after a place is selected
      setState(() {
        _placeSuggestions = [];
      });
    } else {
      // Handle error
      print('Failed to load place details');
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderDetailHeight =
          (_orderDetailCardKey.currentContext?.findRenderObject() as RenderBox?)
                  ?.size
                  .height ??
              0;

      if (orderDetailHeight > 0) {
        if (orderDetailHeight > 80) {
          navigateButtonBottom = 130;
        } else {
          navigateButtonBottom = 98;
        }
      }

      setState(() {});
    });

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

          // Show the search overlay if activated
          if (_showSearchOverlay) _buildSearchOverlay(),

          // Only show the following widgets if the search overlay is not active
          if (!_showSearchOverlay) _buildNavigateButton(navigateButtonBottom),
          if (!_showSearchOverlay) _buildOrderDetailDraggable(),
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

          Stack(
            children: [
              Container(
                width: 40, // Reduced width
                height: 40, // Reduced height
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12), // Rounded corners
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
                  width:
                      15, // Adjust width and height to make the badge a circle
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10), // Circular badge
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // Set state to show overlay
          setState(() {
            _showSearchOverlay = true;
          });

          // Add delay to trigger fade-in animation properly
          Future.delayed(Duration(milliseconds: 100), () {
            setState(() {
              _showSearchOverlay = true;
            });
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search location...",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showSearchOverlay = false; // Close overlay with fade-out effect
          });
        },
        child: AnimatedOpacity(
          opacity:
              _showSearchOverlay ? 1.0 : 0.0, // Animate opacity between 0 and 1
          duration: Duration(milliseconds: 300), // Set the fade-in/out duration
          child: Material(
            color: Colors.grey[900]?.withOpacity(1), // Greyish overlay
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 100.0, left: 16.0, right: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[600]),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration.collapsed(
                              hintText: "Search location...",
                              hintStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            onChanged: _searchLocation,
                            style: TextStyle(
                                color:
                                    Colors.black), // Text color in search bar
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _showSearchOverlay =
                                  false; // Close overlay with fade-out effect
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_searchController.text.isEmpty &&
                    _recentSearches.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentSearches.length,
                      itemBuilder: (context, index) {
                        final recentSearch = _recentSearches[index];
                        return ListTile(
                          leading: Icon(Icons.history, color: Colors.white),
                          title: Text(
                            recentSearch,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onTap: () {
                            _searchController.text = recentSearch;
                            _searchLocation(recentSearch);
                          },
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _placeSuggestions.length,
                      itemBuilder: (context, index) {
                        var suggestion = _placeSuggestions[index];
                        return ListTile(
                          leading:
                              Icon(Icons.location_on, color: Colors.blue[300]),
                          title: Text(
                            suggestion['description'],
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onTap: () {
                            _selectPlace(suggestion['place_id']);
                            setState(() {
                              _showSearchOverlay =
                                  false; // Close overlay after selecting
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigateButton(double bottom) {
    return Positioned(
      bottom: bottom, // Use dynamic bottom position
      left: MediaQuery.of(context).size.width / 2 -
          28, // Center the button horizontally
      child: ElevatedButton(
        onPressed: () async {
          // First, calculate the route
          await _calculateRoute();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.orangeAccent, // Modern accent color for visibility
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                12), // Slightly rounded corners for modern look
          ),
          padding: EdgeInsets.all(16), // Padding for square shape
          minimumSize: Size(56, 56), // Square size
          maximumSize: Size(56, 56),
          elevation: 4, // Shadow for floating effect
        ),
        child: Icon(
          Icons.navigation, // Navigation icon
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

// New method to start the navigation after the route is calculated
  Future<void> _startNavigation() async {
    // Check if route steps exist
    if (_routeSteps.isNotEmpty) {}

    // Replace this with actual code to launch navigation in Google Maps
    final destinationLatitude = 14.6339; // Example latitude
    final destinationLongitude = 120.9772; // Example longitude

    // Construct the navigation URL for Google Maps
    final googleMapsUrl =
        'google.navigation:q=$destinationLatitude,$destinationLongitude&mode=d';

    // Launch Google Maps navigation using the URL
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  Widget _buildOrderDetailDraggable() {
    return DraggableScrollableSheet(
      initialChildSize: 0.153, // Initial height when partially visible
      minChildSize: 0.153, // Minimum height when fully collapsed
      maxChildSize: 1, // Maximum height when fully expanded
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                spreadRadius: 2,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            children: [
              // Pull-bar for aesthetics and ease of dragging
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Order Details Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () {
                      // Close or dismiss the sheet
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: 10),
              // Order Information
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: Text(
                  'Order ID: 12345',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Amount: 350 PHP',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    if (_routeDuration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Estimated Duration: $_routeDuration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orangeAccent, // Updated to backgroundColor
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    // Add your desired action here
                  },
                ),
              ),
              // Add any additional sections here
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout() {
    return Stack(
      children: [
        _buildMapView(),
        _buildTopBar(),
        _buildSearchBar(),
        _buildNavigateButton(120), // Adjust position as needed

        // Order Details Draggable Card
        _buildOrderDetailDraggable(),
      ],
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

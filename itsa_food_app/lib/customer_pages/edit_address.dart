// ignore_for_file: library_private_types_in_public_api, avoid_print, unused_element, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class EditAddress extends StatefulWidget {
  final String userName;
  final String emailAddress;
  final String email;
  final String uid;
  final String userAddress;
  final double? latitude; // Nullable
  final double? longitude; // Nullable

  const EditAddress({
    super.key,
    required this.userName,
    required this.emailAddress,
    required this.email,
    required this.uid,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  _EditAddressState createState() => _EditAddressState();
}

class _EditAddressState extends State<EditAddress> {
  late LatLng _selectedLocation;
  GoogleMapController? _controller;
  List<String> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _currentAddress = "";

  final String _mapStyle = '''[{
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

  @override
  void initState() {
    super.initState();

    // Log the initial user address for debugging
    print("User Address: ${widget.userAddress}");

    // Check if latitude and longitude are provided, otherwise use the user address to fetch coordinates
    if (widget.latitude != null && widget.longitude != null) {
      _selectedLocation = LatLng(widget.latitude!, widget.longitude!);
      _currentAddress = widget.userAddress; // Update current address
    } else if (widget.userAddress.isNotEmpty) {
      _fetchCoordinatesFromAddress(widget.userAddress);
    } else {
      // Fallback default location (San Francisco)
      _selectedLocation = LatLng(37.7749, -122.4194);
      _currentAddress = "Fetching address...";
    }
  }

  void _updateMapToUserLocation() {
    if (_controller != null) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
  }

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      // The permission is granted, you can use the location services
    } else {
      // Handle the case when permission is denied
      print("Location permission denied");
    }
  }

  Future<void> _fetchCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          _currentAddress = address; // Update current address
        });

        // Move the camera to the new location
        _updateMapToUserLocation();
        _fetchAddress(_selectedLocation); // Fetch address details
      } else {
        print("No locations found for the address.");
      }
    } catch (e) {
      print("Error fetching coordinates: $e");
      // Handle error (e.g., show a dialog or a message)
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch the address when dependencies change (i.e., when the screen is re-displayed)
    _fetchAddress(_selectedLocation);
  }

  void _initializeLocation() {
    if (widget.latitude != null && widget.longitude != null) {
      _selectedLocation = LatLng(widget.latitude!, widget.longitude!);
      _currentAddress = widget.userAddress; // Update current address
    } else if (widget.userAddress.isNotEmpty) {
      _fetchCoordinatesFromAddress(widget.userAddress);
    } else {
      // Fallback default location (San Francisco)
      _selectedLocation = LatLng(37.7749, -122.4194);
      _currentAddress = "Fetching address...";
    }

    // Move the camera to the user's location if the map controller is available
    _updateMapToUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search for an address",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black54),
          ),
          onChanged: (query) {
            _onSearchChanged(query);
          },
          onSubmitted: (value) {
            _searchAndNavigate(value);
          },
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _setMapStyle();
              _updateMapToUserLocation();
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _selectedLocation = position.target;
              });
            },
            onCameraIdle: () {
              _fetchAddress(_selectedLocation);
            },
            zoomControlsEnabled: false,
          ),
          Center(
            child: Icon(
              Icons.location_pin,
              size: screenHeight *
                  0.05, // Adjust icon size based on screen height
              color: Colors.pink,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        onTap: () {
                          _searchController.text = _suggestions[index];
                          _searchAndNavigate(_suggestions[index]);
                          _clearSuggestions();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            top: screenHeight * 0.64, // Adjust position based on screen height
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            child: Container(
              height:
                  screenHeight * 0.15, // Adjust height based on screen height
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Latitude: ${widget.latitude?.toStringAsFixed(6) ?? 'N/A'}, Longitude: ${widget.longitude?.toStringAsFixed(6) ?? 'N/A'}",
                    style: TextStyle(color: Colors.black54),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "Current selected address",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: Text(
                      _currentAddress,
                      style: TextStyle(color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight *
                0.02, // Adjust bottom position based on screen height
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            child: ElevatedButton(
              onPressed: () async {
                await _saveAddressToFirestore();
                print(
                    "New address saved: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}");
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Save this as your new address",
                style: TextStyle(
                    fontSize: screenWidth * 0.045, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddressToFirestore() async {
    try {
      // Get a reference to the Firestore instance
      final firestore = FirebaseFirestore.instance;

      // Create a reference to the user's document using the UID
      final userDocRef = firestore.collection('customer').doc(widget.uid);

      // Create the address data to save
      final addressData = {
        'userAddress': _currentAddress,
        'userCoordinates': {
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
        },
      };

      // Update the user's document with the new address and coordinates
      await userDocRef.set(addressData, SetOptions(merge: true));

      // Optionally, you can show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address saved successfully!')),
      );
    } catch (e) {
      print("Error saving address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address.')),
      );
    }
  }

  void _setMapStyle() {
    _controller?.setMapStyle(_mapStyle);
  }

  Future<void> _fetchAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentAddress =
              "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].country}"; // Update the address with more detail
        });
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  Future<void> _searchAndNavigate(String query) async {
    try {
      // Fetch locations based on the selected address from the suggestions
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        _controller?.animateCamera(CameraUpdate.newLatLng(newLocation));

        setState(() {
          _selectedLocation = newLocation;
          _currentAddress =
              query; // Set _currentAddress directly to the selected address
        });

        // Fetch and update address details if necessary
        await _fetchAddress(newLocation);
      }
    } catch (e) {
      print("Error finding address: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSuggestions(query);
    });
  }

  Future<void> _updateSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions.clear());
      return;
    }

    final apiKey =
        'AIzaSyAvT85VgPqti1JQEr_ca4cV4bZ8xuKrnXA'; // Add your API key here
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> formattedAddresses = [];

        for (var prediction in data['predictions']) {
          formattedAddresses.add(prediction['description']);
        }

        // Limit suggestions to the first 5 unique addresses
        setState(() {
          _suggestions = formattedAddresses.take(5).toList();
        });
      } else {
        print("Error fetching suggestions: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }

  void _clearSuggestions() {
    setState(() {
      _suggestions.clear();
    });
  }
}

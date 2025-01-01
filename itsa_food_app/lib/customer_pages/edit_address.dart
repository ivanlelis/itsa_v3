// ignore_for_file: library_private_types_in_public_api, avoid_print, unused_element, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng? _selectedLocation;
  GoogleMapController? _controller;
  List<String> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _currentAddress = "";
  bool _isLoading = true;
  late Set<Marker> _markers;

  final List<String> branchPlusCodes = [
    '8XQ2+94H, Dasmariñas, Cavite',
    '8X85+44, Dasmariñas, Cavite',
    '8XQ4+228, Dasmariñas, Cavite',
  ];

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
        { "color": "#A78D78" }
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
    _markers = {};
    _setBranchMarkers();

    // Log the initial user address for debugging
    print("User Address: ${widget.userAddress}");
    _getCurrentLocation();
  }

  Future<void> _setBranchMarkers() async {
    // Map branch plus codes to branch names
    final branchDetails = {
      '8XQ2+94H, Dasmariñas, Cavite': 'Sta. Lucia Branch',
      '8X85+44, Dasmariñas, Cavite': 'Sta. Cruz II Branch',
      '8XQ4+228, Dasmariñas, Cavite': 'San Dionisio Branch',
    };

    for (var branchPlusCode in branchDetails.keys) {
      final coordinates = await _getCoordinatesFromPlusCode(branchPlusCode);
      if (coordinates != null) {
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(branchPlusCode),
            position: coordinates,
            infoWindow: InfoWindow(title: branchDetails[branchPlusCode]),
          ));
        });
      }
    }
  }

  Future<LatLng?> _getCoordinatesFromPlusCode(String plusCode) async {
    final apiKey = 'AIzaSyAvT85VgPqti1JQEr_ca4cV4bZ8xuKrnXA';
    final formattedPlusCode = Uri.encodeComponent(plusCode.trim());
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$formattedPlusCode&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permissions are denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false; // Stop loading indicator once location is set
    });

    if (_controller != null) {
      _updateMapToUserLocation();
    }
  }

  void _updateMapToUserLocation() {
    if (_selectedLocation != null) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
      _fetchAddress(_selectedLocation!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading while waiting for GPS
          : Stack(
              children: [
                if (_selectedLocation != null)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) async {
                      _controller = controller;
                      _controller!.setMapStyle(_mapStyle);
                      _updateMapToUserLocation(); // Move camera to user location on map creation
                    },
                    onCameraMove: (CameraPosition position) {
                      _selectedLocation = position.target;
                    },
                    onCameraIdle: () {
                      _fetchAddress(_selectedLocation!);
                    },
                    zoomControlsEnabled: false,
                  ),
                Center(
                  child: Icon(
                    Icons.location_pin,
                    size: screenHeight * 0.05,
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
                if (_selectedLocation != null)
                  Positioned(
                    top: screenHeight * 0.62,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    child: Container(
                      height: screenHeight * 0.16,
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
                            "Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}",
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
                if (_selectedLocation != null)
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_currentAddress.contains("Dasmariñas")) {
                          // Show the dialog if the address is not in Dasmariñas
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  "Address Not Supported",
                                  style: TextStyle(fontSize: 22),
                                ),
                                content: Text(
                                  "Sorry, there are no stores available in your selected address.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text("Close"),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          // Save the address if it is in Dasmariñas
                          await _saveAddressToFirestore(); // Save the address
                          Navigator.of(context).pop(
                              _currentAddress); // Return the updated address
                          print(
                              "New address saved: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        backgroundColor: Color(
                            0xFF6E473B), // Set the background color to #6E473B
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Save this as your new address",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _saveAddressToFirestore() async {
    if (_selectedLocation != null) {
      // Check if _selectedLocation is not null
      try {
        // Get a reference to the Firestore instance
        final firestore = FirebaseFirestore.instance;

        // Create a reference to the user's document using the UID
        final userDocRef = firestore.collection('customer').doc(widget.uid);

        // Create the address data to save
        final addressData = {
          'userAddress': _currentAddress,
          'userCoordinates': {
            'latitude': _selectedLocation!.latitude, // Use ! to assert non-null
            'longitude':
                _selectedLocation!.longitude, // Use ! to assert non-null
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location is not available.')),
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
              "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}, ${placemarks[0].country}";
        });
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  Future<void> _searchAndNavigate(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        _controller?.animateCamera(CameraUpdate.newLatLng(newLocation));
        setState(() {
          _selectedLocation = newLocation;
          _currentAddress = query;
        });
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

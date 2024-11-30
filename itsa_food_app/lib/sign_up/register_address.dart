import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class RegisterAddress extends StatefulWidget {
  const RegisterAddress({Key? key}) : super(key: key);

  @override
  _RegisterAddressState createState() => _RegisterAddressState();
}

class _RegisterAddressState extends State<RegisterAddress> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  final TextEditingController _addressController = TextEditingController();
  String? _selectedAddress;
  late Set<Marker> _markers;
  List<dynamic> _suggestions = [];
  Timer? _debounceTimer;
  String _nearestBranch = '';

  // Branch Plus Codes
  final List<String> branchPlusCodes = [
    '8XQ2+94H, Dasmariñas, Cavite',
    '8X85+44, Dasmariñas, Cavite',
    '8XQ4+228, Dasmariñas, Cavite',
  ];

  @override
  void initState() {
    super.initState();
    _markers = {};
    _setBranchMarkers();
  }

  Future<void> _setBranchMarkers() async {
    for (var branchPlusCode in branchPlusCodes) {
      final coordinates = await _getCoordinatesFromPlusCode(branchPlusCode);
      if (coordinates != null) {
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(branchPlusCode),
            position: coordinates,
            infoWindow: InfoWindow(title: 'Branch Location'),
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

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    // Cancel any ongoing debounce timers
    _debounceTimer?.cancel();

    // Set up a new timer to delay the API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final String apiKey = 'AIzaSyAvT85VgPqti1JQEr_ca4cV4bZ8xuKrnXA';
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:PH';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          if (data['predictions'] != null && data['predictions'].isNotEmpty) {
            _suggestions = data['predictions'];
          } else {
            _suggestions = [];
          }
        });
      } else {
        throw Exception('Failed to load suggestions');
      }
    });
  }

  Future<void> _selectSuggestion(String placeId) async {
    final String apiKey = 'AIzaSyAvT85VgPqti1JQEr_ca4cV4bZ8xuKrnXA';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final place = data['result'];
      final location = place['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      setState(() {
        _selectedLocation = LatLng(lat, lng);
        _selectedAddress = place['formatted_address'];
        _addressController.text = _selectedAddress!;
        _suggestions = []; // Clear suggestions after selection
      });

      // Find the nearest branch
      String nearestBranch = await _findNearestBranch(LatLng(lat, lng));
      setState(() {
        _nearestBranch = nearestBranch;
      });

      _mapController.moveCamera(CameraUpdate.newLatLng(_selectedLocation!));
      _addMarker(_selectedLocation!);
    } else {
      throw Exception('Failed to load place details');
    }
  }

  Future<String> _findNearestBranch(LatLng selectedLocation) async {
    double minDistance = double.infinity;
    String nearestBranch = '';

    for (var branchPlusCode in branchPlusCodes) {
      final coordinates = await _getCoordinatesFromPlusCode(branchPlusCode);
      if (coordinates != null) {
        double distance = _getDistance(selectedLocation, coordinates);
        if (distance < minDistance) {
          minDistance = distance;
          nearestBranch =
              branchPlusCode; // You can modify this to return branch name if needed
        }
      }
    }
    return nearestBranch;
  }

  double _getDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // in kilometers

    double dLat = (end.latitude - start.latitude) * (3.141592653589793 / 180);
    double dLon = (end.longitude - start.longitude) * (3.141592653589793 / 180);

    double a = (0.5 - (1 - cos(dLat)) / 2) +
        cos(start.latitude * (3.141592653589793 / 180)) *
            cos(end.latitude * (3.141592653589793 / 180)) *
            (1 - cos(dLon)) /
            2;

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // returns the distance in kilometers
  }

  void _addMarker(LatLng location) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        infoWindow: InfoWindow(title: _selectedAddress ?? 'Selected Location'),
      ));
    });
  }

  void _saveAddress() {
    if (_selectedAddress != null) {
      // You can save the selected address here (e.g., using a method that saves to Firestore or any state management solution).
      // For now, we will pass it back to the previous screen and go back to the CustomerSignUp screen.
      Navigator.pop(context, _selectedAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Address"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  onChanged: (input) {
                    if (input.isNotEmpty) {
                      _getSuggestions(input);
                    } else {
                      setState(() {
                        _suggestions =
                            []; // Clear suggestions if input is empty
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Address',
                    hintText: 'Enter address',
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                if (_suggestions.isNotEmpty) ...[
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () =>
                              _selectSuggestion(suggestion['place_id']),
                        );
                      },
                    ),
                  ),
                ],
                if (_selectedAddress != null) ...[
                  const SizedBox(height: 10),
                  Text('Selected Address: $_selectedAddress'),
                ],
                if (_nearestBranch.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Nearest Branch: $_nearestBranch'),
                ],
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(12.8797, 121.7740), // Default to center of PH
                zoom: 6,
              ),
              markers: _markers,
              zoomControlsEnabled: false, // Disable zoom controls
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveAddress,
              child: const Text('Save This Address'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

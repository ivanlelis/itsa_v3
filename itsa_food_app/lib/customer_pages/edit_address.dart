import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class EditAddress extends StatefulWidget {
  @override
  _EditAddressState createState() => _EditAddressState();
}

class _EditAddressState extends State<EditAddress> {
  LatLng _selectedLocation =
      LatLng(37.7749, -122.4194); // Default location (San Francisco)
  GoogleMapController? _controller;
  String _address = "Address not found";
  bool _isLoadingAddress = true; // Show loading initially

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

  @override
  void initState() {
    super.initState();
    _fetchAddress(
        _selectedLocation); // Fetch the address when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Address'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    _setMapStyle();
                  },
                  onCameraMove: (CameraPosition position) {
                    setState(() {
                      _isLoadingAddress = true;
                      _selectedLocation = position.target;
                      _address = "Finding address...";
                    });
                  },
                  onCameraIdle: () {
                    _fetchAddress(_selectedLocation);
                  },
                ),
                Center(
                  child: Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _isLoadingAddress ? "Finding address..." : _address,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    print('Selected Address: $_selectedLocation');
                  },
                  child: Text('Save Address'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setMapStyle() {
    _controller?.setMapStyle(_mapStyle);
  }

  Future<void> _fetchAddress(LatLng location) async {
    try {
      // Log the coordinates being fetched
      print(
          "Fetching address for coordinates: ${location.latitude}, ${location.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        setState(() {
          _address =
              "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _address = "Address not found";
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = "Address not found";
        _isLoadingAddress = false;
      });
      print("Error fetching address: $e");
    }
  }
}

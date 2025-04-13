import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressMapPicker extends StatefulWidget {
  final LatLng initialLocation;

  const AddressMapPicker({Key? key, required this.initialLocation}) : super(key: key);

  @override
  _AddressMapPickerState createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends State<AddressMapPicker> {
  late LatLng _selectedLocation;
  String _selectedAddress = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  /// Uses OpenRouteService API to reverse geocode the selected coordinates.
  Future<void> _reverseGeocode() async {
    setState(() {
      _isLoading = true;
    });
    // Replace with your actual OpenRouteService API key.
    final String apiKey = "5b3ce3597851110001cf624864d0a9022ccf426585696672ccf66652";
    final uri = Uri.parse(
      "https://api.openrouteservice.org/geocode/reverse?api_key=$apiKey&point.lat=${_selectedLocation.latitude}&point.lon=${_selectedLocation.longitude}&size=1"
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["features"] != null && data["features"].isNotEmpty) {
          setState(() {
            _selectedAddress = data["features"][0]["properties"]["label"];
          });
        } else {
          setState(() {
            _selectedAddress = "No address found";
          });
        }
      } else {
        setState(() {
          _selectedAddress = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Error retrieving address";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Called when the user taps on the map.
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = ""; // Clear previous address on new tap.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Use 80% of the screen height.
      child: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _selectedLocation,
                zoom: 15.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 95, 0, 0),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _selectedAddress.isNotEmpty
                        ? _selectedAddress
                        : "Tap on the map to select your location",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _reverseGeocode,
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 255, 255)),
                child: const Text("Get Address"),
              ),
              ElevatedButton(
                onPressed: _selectedAddress.isNotEmpty
                    ? () {
                        Navigator.pop(context, {
                          "address": _selectedAddress,
                          "lat": _selectedLocation.latitude,
                          "lng": _selectedLocation.longitude,
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 255, 255)),
                child: const Text("Confirm Location"),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

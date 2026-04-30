import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import 'property_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> properties = [];
  List<dynamic> filteredProperties = [];
  bool isLoading = true;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final response = await ApiService.get('/properties');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            properties = json.decode(response.body);
            filteredProperties = properties;
            isLoading = false;
            
            // Auto-center on first property
            if (filteredProperties.isNotEmpty) {
              final first = filteredProperties.first;
              final lat = double.tryParse(first['lat']?.toString() ?? '0');
              final lng = double.tryParse(first['lng']?.toString() ?? '0');
              if (lat != null && lng != null && lat != 0) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _mapController.move(LatLng(lat, lng), 13.0);
                });
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterProperties(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProperties = properties;
      });
      return;
    }
    setState(() {
      filteredProperties = properties.where((p) {
        final loc = p['location']?.toString().toLowerCase() ?? '';
        final title = p['title']?.toString().toLowerCase() ?? '';
        return loc.contains(query.toLowerCase()) || title.contains(query.toLowerCase());
      }).toList();
    });
    
    if (filteredProperties.isNotEmpty) {
      final first = filteredProperties.first;
      final lat = double.tryParse(first['lat']?.toString() ?? '0');
      final lng = double.tryParse(first['lng']?.toString() ?? '0');
      if (lat != null && lng != null && lat != 0) {
        _mapController.move(LatLng(lat, lng), 13.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Map'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              if (filteredProperties.isNotEmpty) {
                final first = filteredProperties.first;
                final lat = double.tryParse(first['lat']?.toString() ?? '0');
                final lng = double.tryParse(first['lng']?.toString() ?? '0');
                if (lat != null && lng != null && lat != 0) {
                  _mapController.move(LatLng(lat, lng), 13.0);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProperties,
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.accentColor),
                  onPressed: () => _filterProperties(_searchController.text),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(18.5204, 73.8567), // Default: Pune
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nearnest.app',
                      ),
                      MarkerLayer(
                        markers: filteredProperties.where((p) => p['lat'] != null && p['lng'] != null).map((prop) {
                          final lat = double.tryParse(prop['lat'].toString()) ?? 0.0;
                          final lng = double.tryParse(prop['lng'].toString()) ?? 0.0;
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prop['title'], style: Theme.of(context).textTheme.titleLarge),
                                        const SizedBox(height: 8),
                                        Text(prop['location'] ?? '', style: TextStyle(color: Colors.grey[600])),
                                        const SizedBox(height: 12),
                                        Text('₹${prop['price']}/month', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PropertyDetailsScreen(
                                                    property: Property.fromJson(prop),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('View Details'),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: AppTheme.accentColor,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

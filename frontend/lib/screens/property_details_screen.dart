import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/image_carousel.dart';
import '../widgets/review_dialog.dart';
import '../widgets/skeleton_widgets.dart';
import 'chat_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'vendor_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> with TickerProviderStateMixin {
  late Property _property;
  bool _isBackgroundLoading = false;
  List<Property> _vendorProperties = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Map States
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isSatellite = false;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _fetchLatestProperty();
    _fetchVendorProperties();
    _fetchLocationAndRoute();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndRoute() async {
    if (_property.lat == 0.0 || _property.lng == 0.0) return;
    try {
      setState(() => _isLoadingRoute = true);
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locData = await location.getLocation();
      if (locData.latitude == null || locData.longitude == null) return;

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(locData.latitude!, locData.longitude!);
        });
      }

      // Fetch route from OSRM
      final url = 'http://router.project-osrm.org/route/v1/driving/${locData.longitude},${locData.latitude};${_property.lng},${_property.lat}?geometries=geojson';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Routing error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _fetchVendorProperties() async {
    try {
      final response = await ApiService.get('/properties?vendor=${_property.vendorId}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _vendorProperties = data
                .map((json) => Property.fromJson(json))
                .where((p) => p.id != _property.id)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching vendor properties: $e');
    }
  }

  Widget _buildMoreFromVendor() {
    if (_vendorProperties.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No other listings from this vendor.', style: TextStyle(color: AppTheme.textSecondaryColor)),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vendorProperties.length,
        itemBuilder: (context, index) {
          final p = _vendorProperties[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)));
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: p.images.isNotEmpty 
                      ? Image.network(p.images[0], height: 100, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('₹${p.price}', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchLatestProperty() async {
    try {
      setState(() => _isBackgroundLoading = true);
      await ApiService.getWithCache(
        endpoint: '/properties/${_property.id}',
        onCacheHit: (data) {
          if (mounted) {
            setState(() {
              _property = Property.fromJson(data);
            });
          }
        },
        onSourceUpdate: (data) {
          if (mounted) {
            setState(() {
              _property = Property.fromJson(data);
              _isBackgroundLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isBackgroundLoading = false);
      }
      debugPrint('Error fetching property details: $e');
    } finally {
      // Safety timeout
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isBackgroundLoading) {
          setState(() => _isBackgroundLoading = false);
        }
      });
    }
  }

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: PageView.builder(
          itemCount: images.length,
          controller: PageController(initialPage: initialIndex),
          itemBuilder: (context, index) {
            final imageStr = images[index];
            return Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: imageStr.startsWith('data:image')
                    ? Image.memory(base64Decode(imageStr.split(',').last), fit: BoxFit.contain)
                    : Image.network(imageStr, fit: BoxFit.contain),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isBackgroundLoading && _property.description.isEmpty
          ? const DetailSkeleton()
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () => _showFullScreenImage(context, _property.images, 0),
                        tooltip: 'View All Images',
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: ImageCarousel(images: _property.images, isInteractive: false),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _property.title,
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _property.propertyType,
                                style: const TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_property.offer != null && _property.offer!.discountPercentage > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_property.offer!.discountPercentage}% OFF Special Offer!',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _property.location,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondaryColor),
                            ),
                          ],
                        ),
                        if (_property.lat != 0.0 && _property.lng != 0.0) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(_property.lat, _property.lng),
                                    initialZoom: 14.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: _isSatellite 
                                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.nearnest.app',
                                    ),
                                    if (_routePoints.isNotEmpty)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: _routePoints,
                                            strokeWidth: 4.0,
                                            color: Colors.blueAccent,
                                          ),
                                        ],
                                      ),
                                    MarkerLayer(
                                      markers: [
                                        if (_currentLocation != null)
                                          Marker(
                                            point: _currentLocation!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                                          ),
                                        Marker(
                                          point: LatLng(_property.lat, _property.lng),
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_isLoadingRoute)
                                  const Center(child: CircularProgressIndicator()),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Column(
                                    children: [
                                      FloatingActionButton.small(
                                        heroTag: 'map_type',
                                        onPressed: () => setState(() => _isSatellite = !_isSatellite),
                                        backgroundColor: Colors.white,
                                        child: Icon(_isSatellite ? Icons.map : Icons.satellite, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        heroTag: 'zoom_in',
                                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                                        backgroundColor: Colors.white,
                                        child: const Icon(Icons.add, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        heroTag: 'zoom_out',
                                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                                        backgroundColor: Colors.white,
                                        child: const Icon(Icons.remove, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        heroTag: 'my_location',
                                        onPressed: () {
                                          if (_currentLocation != null) {
                                            _mapController.move(_currentLocation!, 15.0);
                                          } else {
                                            _fetchLocationAndRoute();
                                          }
                                        },
                                        backgroundColor: Colors.white,
                                        child: const Icon(Icons.my_location, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = 'https://www.google.com/maps/dir/?api=1&destination=${_property.lat},${_property.lng}';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch maps.')));
                              }
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('OPEN IN GOOGLE MAPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Vendor Section
                        Text('Owner / Vendor', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VendorProfileScreen(
                              vendorId: _property.vendorId,
                              vendorName: _property.vendorName,
                            )));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(_property.vendorProfileIcon, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_property.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const Text('Verified Vendor', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondaryColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.cardColor, thickness: 2),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rent', style: TextStyle(color: AppTheme.textSecondaryColor)),
                                Text(
                                  '₹${_property.price}/mo',
                                  style: const TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_property.propertyType == 'Restaurant' ? 'Seating' : 'Availability', style: TextStyle(color: AppTheme.textSecondaryColor)),
                                Row(
                                  children: [
                                    Icon(_property.propertyType == 'Restaurant' ? Icons.restaurant : Icons.bed_outlined, color: AppTheme.accentColor, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      _property.propertyType == 'Restaurant' ? '${_property.availableBeds} tables' : '${_property.availableBeds} beds',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.cardColor, thickness: 2),
                        const SizedBox(height: 16),
                        Text('Description', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          _property.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.cardColor, thickness: 2),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Property Gallery', style: Theme.of(context).textTheme.titleLarge),
                            Text('${_property.images.length} photos', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _property.images.length,
                            itemBuilder: (context, index) {
                              final img = _property.images[index];
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  image: DecorationImage(
                                    image: img.startsWith('data:image')
                                        ? MemoryImage(base64Decode(img.split(',').last))
                                        : NetworkImage(img) as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_property.facilities.isNotEmpty) ...[
                          Text('Facilities', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _property.facilities.map((f) => _buildFacilityBadge(f)).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Divider(color: AppTheme.cardColor, thickness: 2),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reviews (${_property.ratings.length})', style: Theme.of(context).textTheme.titleLarge),
                            TextButton(
                              onPressed: () async {
                                final result = await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (_) => ReviewDialog(propertyId: _property.id),
                                );
                                if (result == true) {
                                  _fetchLatestProperty();
                                }
                              },
                              child: const Text('Write a Review'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _property.ratings.isEmpty
                            ? const Text('No reviews yet. Be the first to review!', style: TextStyle(color: AppTheme.textSecondaryColor))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _property.ratings.length,
                                itemBuilder: (context, index) {
                                  final review = _property.ratings[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(review.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                                Text(' ${review.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(review.review, style: const TextStyle(height: 1.4)),
                                        if (review.images.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: 60,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: review.images.length,
                                              itemBuilder: (ctx, imgIndex) {
                                                final img = review.images[imgIndex];
                                                return GestureDetector(
                                                  onTap: () => _showFullScreenImage(context, review.images, imgIndex),
                                                  child: Container(
                                                    margin: const EdgeInsets.only(right: 8),
                                                    width: 60,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      image: DecorationImage(
                                                        image: img.startsWith('data:image') 
                                                          ? MemoryImage(base64Decode(img.split(',').last)) 
                                                          : NetworkImage(img) as ImageProvider,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.cardColor, thickness: 2),
                        const SizedBox(height: 16),
                        Text('More from this Vendor', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _buildMoreFromVendor(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  if (_property.vendorId.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      otherUserId: _property.vendorId,
                      otherUserName: 'Property Vendor',
                    )));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor details unavailable.')));
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: (_property.propertyType != 'Restaurant' && _property.availableBeds <= 0)
                        ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                        : const LinearGradient(
                            colors: [AppTheme.accentColor, Color(0xFF10B981)], // Emerald to Accent
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_property.propertyType != 'Restaurant' && _property.availableBeds <= 0) ? null : () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing booking...')));
                      final response = await ApiService.post('/bookings', {
                        'propertyId': _property.id,
                        'vendorId': _property.vendorId,
                        'checkInDate': DateTime.now().toIso8601String(),
                        'checkOutDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                        'totalPrice': _property.price,
                      });
                      if (response.statusCode == 201) {
                        _showPopup('Booking Successful', 'Your booking request has been sent to the vendor!');
                        _fetchLatestProperty();
                      } else {
                        _showPopup('Booking Failed', 'Error: ${response.body}');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      (_property.propertyType != 'Restaurant' && _property.availableBeds <= 0) ? 'SOLD OUT' : 'BOOK NOW',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityBadge(String facility) {
    IconData icon;
    switch (facility.toLowerCase()) {
      case 'wi-fi': icon = Icons.wifi; break;
      case 'water': icon = Icons.water_drop; break;
      case 'meals': icon = Icons.restaurant; break;
      case 'light bill incl.': icon = Icons.electrical_services; break;
      case 'ac': icon = Icons.ac_unit; break;
      case 'washroom': icon = Icons.wc; break;
      case 'washing machine': icon = Icons.local_laundry_service; break;
      case 'parking': icon = Icons.local_parking; break;
      case 'gallery': icon = Icons.balcony; break;
      default: icon = Icons.done_all;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(facility, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: title.contains('Failed') || title.contains('Error') ? Colors.red : Colors.green)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }
}

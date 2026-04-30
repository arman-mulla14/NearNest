import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';
import '../widgets/skeleton_widgets.dart';

class VendorProfileScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorProfileScreen({
    Key? key,
    required this.vendorId,
    required this.vendorName,
  }) : super(key: key);

  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVendorProperties();
  }

  Future<void> _fetchVendorProperties() async {
    try {
      final response = await ApiService.get('/properties?vendor=${widget.vendorId}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _properties = data.map((json) => Property.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching vendor properties: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Profile'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.accentColor,
                    child: Text(
                      widget.vendorName[0],
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.vendorName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verified Premium Vendor',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Properties', _properties.length.toString()),
                      _buildStatColumn('Rating', '4.8'),
                      _buildStatColumn('Experience', '2+ Years'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Text(
                'Listed Properties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              : _properties.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text('No properties listed yet.')),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PropertyCard(property: _properties[index]),
                          childCount: _properties.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }
}

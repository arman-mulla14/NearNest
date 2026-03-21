import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/image_carousel.dart';
import '../widgets/review_dialog.dart';
import 'chat_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late Property _property;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  Future<void> _fetchLatestProperty() async {
    try {
      final response = await ApiService.get('/properties/${_property.id}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _property = Property.fromJson(data);
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Carousel / App Bar
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCarousel(images: _property.images),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Type
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
                  const SizedBox(height: 8),
                  // Location
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
                  const SizedBox(height: 24),
                  // Price and Beds
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
                                      height: 150,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageCarousel(images: review.images),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
            // Chat button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.accentColor),
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
            // Book button
            Expanded(
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent successfully to the Vendor!')));
                    _fetchLatestProperty();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: ${response.body}')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_property.propertyType != 'Restaurant' && _property.availableBeds <= 0) ? Colors.grey : AppTheme.accentColor,
                ),
                child: Text((_property.propertyType != 'Restaurant' && _property.availableBeds <= 0) ? 'SOLD OUT' : 'BOOK NOW'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

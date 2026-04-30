import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../screens/property_details_screen.dart';
import 'image_carousel.dart';
import '../services/api_service.dart';

class PropertyCard extends StatefulWidget {
  final Property property;

  const PropertyCard({Key? key, required this.property}) : super(key: key);

  @override
  _PropertyCardState createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isWishlisted = false;

  void _toggleWishlist() async {
    setState(() {
      _isWishlisted = !_isWishlisted;
    });
    try {
      if (_isWishlisted) {
        await ApiService.post('/wishlist', {'propertyId': widget.property.id});
        _showWishlistPopup('Added to Wishlist', 'Property has been saved to your wishlist.');
      } else {
        await ApiService.delete('/wishlist/${widget.property.id}');
        _showWishlistPopup('Removed from Wishlist', 'Property has been removed from your wishlist.');
      }
    } catch (e) {
      // Revert if error
      setState(() {
        _isWishlisted = !_isWishlisted;
      });
      _showWishlistPopup('Error', 'Could not update wishlist: $e');
    }
  }

  void _showWishlistPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: title == 'Error' ? Colors.red : AppTheme.accentColor)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Card(
          margin: const EdgeInsets.only(bottom: 24.0),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: () {
              Future.delayed(const Duration(milliseconds: 150), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailsScreen(property: widget.property),
                  ),
                );
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 180,
                    child: ImageCarousel(images: widget.property.images, isInteractive: false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.property.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: _isWishlisted ? Colors.red : AppTheme.textSecondaryColor,
                            ),
                            onPressed: _toggleWishlist,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.property.propertyType,
                              style: const TextStyle(
                                color: Color(0xFF10B981), // Emerald Green text
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '₹${widget.property.price}/mo',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bed, size: 16, color: Colors.black87),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.property.availableBeds} beds',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


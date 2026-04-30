import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';
import '../models/property_model.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    try {
      final response = await ApiService.get('/wishlist');
      if (response.statusCode == 200) {
        setState(() {
          wishlistItems = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String propertyId) async {
    try {
      final response = await ApiService.delete('/wishlist/$propertyId');
      if (response.statusCode == 200) {
        _fetchWishlist(); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlistItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Your wishlist is empty', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = wishlistItems[index];
                    final propertyData = item['property'];
                    if (propertyData == null) return const SizedBox.shrink();
                    
                    final property = Property.fromJson(propertyData);

                    return Stack(
                      children: [
                        PropertyCard(property: property),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () => _removeFromWishlist(property.id),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

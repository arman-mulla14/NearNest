import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/property_model.dart';
import '../screens/property_details_screen.dart';
import 'image_carousel.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instagram-style swipeable carousel logic
            SizedBox(
              height: 180,
              child: ImageCarousel(images: property.images),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          property.propertyType,
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${property.price}/mo',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.bed_outlined, size: 16, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${property.availableBeds} beds available',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

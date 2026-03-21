class Property {
  final String id;
  final String vendorId;
  final String title;
  final String description;
  final String location;
  final double price;
  final String propertyType;
  final List<String> images;
  final int availableBeds;
  final List<String> facilities;
  final List<Rating> ratings;

  Property({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.propertyType,
    required this.images,
    required this.availableBeds,
    required this.facilities,
    required this.ratings,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] ?? '',
      vendorId: json['vendor'] is Map ? (json['vendor']['_id'] ?? '') : (json['vendor'] ?? ''),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      price: json['price'] != null ? json['price'].toDouble() : 0.0,
      propertyType: json['propertyType'] ?? 'PG',
      images: List<String>.from(json['images'] ?? []),
      facilities: List<String>.from(json['facilities'] ?? []),
      availableBeds: json['availableBeds'] ?? 0,
      ratings: (json['ratings'] as List<dynamic>?)?.map((x) => Rating.fromJson(x)).toList() ?? [],
    );
  }
}

class Rating {
  final String name;
  final double rating;
  final String review;
  final List<String> images;
  final String createdAt;

  Rating({
    required this.name,
    required this.rating,
    required this.review,
    required this.images,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      name: json['name'] ?? 'Guest',
      rating: json['rating']?.toDouble() ?? 5.0,
      review: json['review'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] ?? '',
    );
  }
}

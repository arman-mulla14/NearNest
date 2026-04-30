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
  final double lat;
  final double lng;

  final String vendorName;
  final String vendorProfileIcon;
  final Offer? offer;

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
    this.lat = 0.0,
    this.lng = 0.0,
    this.vendorName = 'Premium Vendor',
    this.vendorProfileIcon = '',
    this.offer,
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
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) ?? 0.0 : 0.0,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) ?? 0.0 : 0.0,
      vendorName: json['vendor'] is Map ? (json['vendor']['name'] ?? 'Premium Vendor') : 'Premium Vendor',
      vendorProfileIcon: json['vendor'] is Map ? (json['vendor']['name']?[0] ?? 'V') : 'V',
      offer: json['offer'] != null ? Offer.fromJson(json['offer']) : null,
    );
  }
}

class Offer {
  final double discountPercentage;
  final String? startDate;
  final String? endDate;

  Offer({
    required this.discountPercentage,
    this.startDate,
    this.endDate,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0.0,
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discountPercentage': discountPercentage,
      'startDate': startDate,
      'endDate': endDate,
    };
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

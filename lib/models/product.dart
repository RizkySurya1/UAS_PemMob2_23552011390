import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final String description;
  final String imageUrl;
  final int stock;
  final String? category;
  final double? rating;
  final Timestamp createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.stock,
    this.category,
    this.rating,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      stock: data['stock'] ?? 0,
      category: data['category'],
      rating: (data['rating'] ?? 5.0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'stock': stock,
      'category': category,
      'rating': rating,
      'createdAt': createdAt,
    };
  }
}

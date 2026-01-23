import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final int duration;
  final Timestamp createdAt;

  ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.duration,
    required this.createdAt,
  });

  factory ServiceItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServiceItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      description: data['description'] ?? '',
      duration: data['duration'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'duration': duration,
      'createdAt': createdAt,
    };
  }
}

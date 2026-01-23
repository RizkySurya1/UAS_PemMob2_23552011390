import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final int price;
  final String date;
  final String? timeSlot;
  final String status;
  final Timestamp createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.date,
    this.timeSlot,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      price: data['price'] ?? 0,
      date: data['date'] ?? '',
      timeSlot: data['timeSlot'],
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'date': date,
      if (timeSlot != null) 'timeSlot': timeSlot,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

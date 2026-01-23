import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createBooking({
    required String userId,
    required String serviceId,
    required String serviceName,
    required String date,
  }) async {
    await _db.collection('bookings').add({
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': 0,
      'date': date,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Booking>> userBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Booking.fromFirestore(d)).toList(),
        );
  }

  Stream<List<Booking>> allBookings() {
    return _db.collection('bookings').snapshots().map(
          (s) => s.docs.map((d) => Booking.fromFirestore(d)).toList(),
        );
  }

  Future<void> updateStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }
}

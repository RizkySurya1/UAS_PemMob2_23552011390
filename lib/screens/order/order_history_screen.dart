import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Pesanan')),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }
    
    final service = BookingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: StreamBuilder<List<Booking>>(
        stream: service.userBookings(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return const Center(child: Text('Belum ada pesanan'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(b.serviceName),
                  subtitle: Text('${b.date} - ${b.status}'),
                  leading: _getStatusIcon(b.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'pending':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }
}

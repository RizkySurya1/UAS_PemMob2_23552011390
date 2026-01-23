import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';

class ManageBookingScreen extends StatelessWidget {
  const ManageBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Booking')),
      body: StreamBuilder<List<Booking>>(
        stream: bookingService.allBookings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;

          if (bookings.isEmpty) {
            return const Center(child: Text('Belum ada booking'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  title: Text(b.serviceName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: ${b.date}'),
                      if (b.timeSlot != null) Text('Jam: ${b.timeSlot}'),
                      Text('User ID: ${b.userId}'),
                      Text('Status: ${b.status}'),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: b.status,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('Confirmed', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'diproses',
                          child: Text('Diproses', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'selesai',
                          child: Text('Selesai', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'dibatalkan',
                          child: Text('Batal', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          bookingService.updateStatus(b.id, value);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

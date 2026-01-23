import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Service'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Service'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat service',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking service Anda akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort bookings by date (newest first)
          final bookings = snapshot.data!.docs;
          bookings.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['createdAt'] as Timestamp?;
            final bTimestamp = bData['createdAt'] as Timestamp?;
            
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;
              
              return _buildBookingCard(context, booking, bookingId);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Map<String, dynamic> booking,
    String bookingId,
  ) {
    final serviceName = booking['serviceName'] ?? 'Service';
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final status = booking['status'] ?? 'pending';
    final notes = booking['notes'] ?? '';
    final createdAt = booking['createdAt'] as Timestamp?;

    // Format created date
    String formattedDate = '';
    if (createdAt != null) {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate());
    }

    // Status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'dikonfirmasi':
        statusColor = Colors.green;
        statusText = 'Dikonfirmasi';
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
      case 'selesai':
        statusColor = Colors.blue;
        statusText = 'Selesai';
        statusIcon = Icons.task_alt;
        break;
      case 'cancelled':
      case 'dibatalkan':
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Menunggu Konfirmasi';
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking, bookingId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Booking details
              _buildDetailRow(Icons.calendar_today, 'Tanggal', date),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.access_time, 'Waktu', time),
              
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.notes, 'Catatan', notes),
              ],

              if (formattedDate.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Dibuat: $formattedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(
    BuildContext context,
    Map<String, dynamic> booking,
    String bookingId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final serviceName = booking['serviceName'] ?? 'Service';
          final date = booking['date'] ?? '';
          final time = booking['time'] ?? '';
          final status = booking['status'] ?? 'pending';
          final notes = booking['notes'] ?? '';
          final userName = booking['userName'] ?? '';
          final userPhone = booking['userPhone'] ?? '';

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Detail Booking',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildDetailItem('ID Booking', bookingId),
              _buildDetailItem('Service', serviceName),
              _buildDetailItem('Tanggal', date),
              _buildDetailItem('Waktu', time),
              _buildDetailItem('Status', status.toUpperCase()),
              
              if (userName.isNotEmpty)
                _buildDetailItem('Nama', userName),
              
              if (userPhone.isNotEmpty)
                _buildDetailItem('No. Telepon', userPhone),
              
              if (notes.isNotEmpty)
                _buildDetailItem('Catatan', notes),

              const SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

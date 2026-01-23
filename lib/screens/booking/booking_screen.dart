import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final int price;

  const BookingScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.price,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool loading = false;
  
  // Jam kerja: 08:00 - 17:00, setiap 1 jam
  final List<String> timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.serviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pilih Tanggal
            const Text(
              'Pilih Tanggal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(
                selectedDate == null
                    ? 'Pilih Tanggal'
                    : selectedDate!.toLocal().toString().split(' ')[0],
              ),
            ),

            const SizedBox(height: 24),

            // Pilih Jam
            if (selectedDate != null) ...[
              const Text(
                'Pilih Jam Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                key: ValueKey(selectedDate.toString()),
                future: _getAvailableTimeSlots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final availableSlots = snapshot.data!;

                  if (availableSlots.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Text(
                        'Semua slot sudah penuh untuk tanggal ini. Silakan pilih tanggal lain.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeSlots.map((time) {
                      final isAvailable = availableSlots.contains(time);
                      final isSelected = selectedTimeSlot == time;

                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: isAvailable
                            ? (selected) {
                                setState(() {
                                  selectedTimeSlot = selected ? time : null;
                                });
                              }
                            : null,
                        backgroundColor: isAvailable ? null : Colors.grey.shade300,
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? Colors.black
                                  : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        disabledColor: Colors.grey.shade300,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '* Slot abu-abu sudah dibooking',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Konfirmasi Booking', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time slot saat ganti tanggal
      });
    }
  }

  Future<List<String>> _getAvailableTimeSlots() async {
    if (selectedDate == null) return [];

    try {
      final dateStr = selectedDate!.toIso8601String().split('T')[0];

      // Get all bookings for selected date
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isEqualTo: dateStr)
          .get();

      // Get booked time slots (hanya yang confirmed atau pending)
      final bookedSlots = bookings.docs
          .where((doc) {
            final status = doc.data()['status'] as String?;
            return status == 'pending' || status == 'confirmed';
          })
          .map((doc) => doc.data()['timeSlot'] as String?)
          .where((slot) => slot != null)
          .cast<String>()
          .toSet();

      // Return available slots
      return timeSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      // Return all slots jika error
      return timeSlots;
    }
  }

  Future<void> _submit() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dulu')),
      );
      return;
    }

    if (selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam booking dulu')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final auth = context.read<AuthService>();
      final dateStr = selectedDate!.toIso8601String().split('T')[0];

      // Double check slot masih available
      final existingBooking = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isEqualTo: dateStr)
          .where('timeSlot', isEqualTo: selectedTimeSlot)
          .get();

      // Cek apakah ada booking yang masih aktif
      final hasActiveBooking = existingBooking.docs.any((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'pending' || status == 'confirmed';
      });

      if (hasActiveBooking) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jam ini sudah dibooking orang lain')),
        );
        setState(() {
          loading = false;
          selectedTimeSlot = null;
        });
        return;
      }

      // Create booking with time slot
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': auth.user!.uid,
        'serviceId': widget.serviceId,
        'serviceName': widget.serviceName,
        'price': widget.price,
        'date': dateStr,
        'timeSlot': selectedTimeSlot,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking berhasil untuk $dateStr jam $selectedTimeSlot')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal booking: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

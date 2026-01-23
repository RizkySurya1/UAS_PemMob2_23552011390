import 'package:flutter/material.dart';
import '../../services/catalog_service.dart';
import '../../models/service_item.dart';
import '../booking/booking_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogService = CatalogService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Service'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jam Operasional: 08.00 - 17.00 WIB',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceItem>>(
              stream: catalogService.servicesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data!;

                if (services.isEmpty) {
                  return const Center(
                    child: Text('Belum ada layanan tersedia'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          _showBookingDialog(context, service);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.build,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 16,
                                            color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${service.duration} menit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Rp ${service.price}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, ServiceItem service) {
    final now = TimeOfDay.now();
    final currentHour = now.hour;

    // Cek jam operasional (10.00 - 17.00)
    if (currentHour < 10 || currentHour >= 17) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diluar Jam Operasional'),
          content: const Text(
            'Maaf, booking hanya dapat dilakukan pada jam operasional bengkel:\n\n10.00 - 17.00 WIB\n\nSilakan coba lagi saat jam operasional.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          serviceId: service.id,
          serviceName: service.name,
          price: service.price,
        ),
      ),
    );
  }
}

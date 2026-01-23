import 'package:flutter/material.dart';
import '../../services/catalog_service.dart';
import '../../models/service_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ManageServicesScreen extends StatelessWidget {
  const ManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogService();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jasa Service')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ServiceItem>>(
        stream: catalog.servicesStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada jasa'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (c, i) {
              final s = data[i];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  'Rp ${s.price}\n${s.description}\nDurasi: ${s.duration} menit',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => catalog.deleteService(s.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _form(BuildContext context) {
    final name = TextEditingController();
    final price = TextEditingController();
    final desc = TextEditingController();
    final duration = TextEditingController();

    final catalog = CatalogService();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Jasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Durasi (menit)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await catalog.addService(
                ServiceItem(
                  id: '',
                  name: name.text.trim(),
                  price: int.tryParse(price.text) ?? 0,
                  description: desc.text.trim(),
                  duration: int.tryParse(duration.text) ?? 0,
                  createdAt: Timestamp.now(),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }
}

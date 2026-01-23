import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/add_address_screen.dart';

class AddressListScreen extends StatelessWidget {
  final bool isSelectMode;

  const AddressListScreen({super.key, this.isSelectMode = false});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alamat Saya')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectMode ? 'Pilih Alamat' : 'Alamat Saya'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('addresses')
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
                  Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada alamat tersimpan',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan alamat untuk pengiriman',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Alamat'),
                  ),
                ],
              ),
            );
          }

          final addresses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index].data() as Map<String, dynamic>;
              final addressId = addresses[index].id;
              final isDefault = address['isDefault'] ?? false;

              return _buildAddressCard(
                context,
                address,
                addressId,
                isDefault,
                userId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAddressScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    Map<String, dynamic> address,
    String addressId,
    bool isDefault,
    String userId,
  ) {
    final name = address['name'] ?? '';
    final phone = address['phone'] ?? '';
    final fullAddress = address['fullAddress'] ?? '';
    final label = address['label'] ?? 'Rumah';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isSelectMode
            ? () => Navigator.pop(context, {
                  'id': addressId,
                  'name': name,
                  'phone': phone,
                  'fullAddress': fullAddress,
                })
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Utama',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!isSelectMode)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (!isDefault)
                          const PopupMenuItem(
                            value: 'setDefault',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Text('Jadikan Utama'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAddressScreen(
                                addressId: addressId,
                                existingAddress: address,
                              ),
                            ),
                          );
                        } else if (value == 'setDefault') {
                          _setDefaultAddress(context, userId, addressId);
                        } else if (value == 'delete') {
                          _deleteAddress(context, addressId);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fullAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setDefaultAddress(BuildContext context, String userId, String addressId) async {
    try {
      // Remove default from all addresses
      final addresses = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in addresses.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set new default
      batch.update(
        FirebaseFirestore.instance.collection('addresses').doc(addressId),
        {'isDefault': true},
      );

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat utama berhasil diubah')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah alamat utama: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(BuildContext context, String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(addressId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil dihapus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus alamat: $e')),
        );
      }
    }
  }
}

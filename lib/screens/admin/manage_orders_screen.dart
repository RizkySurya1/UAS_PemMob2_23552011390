import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;
          
          // Sort by createdAt descending
          orders.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (orders.isEmpty) {
            return const Center(
              child: Text('Belum ada pesanan'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final items = order['items'] as List<dynamic>? ?? [];
              final total = order['total'] ?? 0;
              final status = order['status'] ?? 'pending';
              final userId = order['userId'] ?? '';
              final address = order['address'] ?? '';
              final trackingNumber = order['trackingNumber'] ?? '';
              final createdAt = order['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: _getStatusIcon(status),
                  title: Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Total: Rp $total'),
                      Text('User: ${userId.substring(0, 8)}'),
                      if (createdAt != null)
                        Text(
                          'Tanggal: ${_formatDate(createdAt.toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: status,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'diproses',
                        child: Text('Diproses'),
                      ),
                      DropdownMenuItem(
                        value: 'dikirim',
                        child: Text('Dikirim'),
                      ),
                      DropdownMenuItem(
                        value: 'selesai',
                        child: Text('Selesai'),
                      ),
                      DropdownMenuItem(
                        value: 'dibatalkan',
                        child: Text('Dibatalkan'),
                      ),
                    ],
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .update({'status': newStatus});
                        
                        // Send notification to user
                        await NotificationService.sendOrderStatusNotification(
                          userId: userId,
                          orderId: orderId,
                          status: newStatus,
                        );
                      }
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Pesanan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final itemData = item as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${itemData['productName']} x${itemData['quantity']}',
                                    ),
                                  ),
                                  Text(
                                    'Rp ${itemData['price'] * itemData['quantity']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 24),
                          const Text(
                            'Alamat Pengiriman:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(address),
                          if (order['notes'] != null &&
                              order['notes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Catatan:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(order['notes']),
                          ],
                          
                          // Payment confirmation for transfer orders
                          if (order['paymentMethod'] == 'transfer') ...[
                            const Divider(height: 24),
                            const Text(
                              'Metode Pembayaran:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Transfer Bank'),
                            const SizedBox(height: 12),
                            const Text(
                              'Status Pembayaran:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPaymentStatusLabel(order['paymentStatus'] ?? 'pending'),
                              style: TextStyle(
                                color: _getPaymentStatusColor(order['paymentStatus'] ?? 'pending'),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (order['paymentProofUrl'] != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Bukti Transfer:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _showPaymentProof(context, order['paymentProofUrl']),
                                child: Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      order['paymentProofUrl'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                              if (order['paymentStatus'] == 'waiting_confirmation') ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _rejectPayment(orderId, userId),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text(
                                          'Tolak',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _approvePayment(orderId, userId),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Terima'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                          
                          // Tracking Number Input
                          if (status == 'dikirim' || trackingNumber.isNotEmpty) ...[
                            const Divider(height: 24),
                            const Text(
                              'Nomor Resi:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(text: trackingNumber),
                                    decoration: const InputDecoration(
                                      hintText: 'Masukkan nomor resi',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onSubmitted: (value) async {
                                      if (value.trim().isNotEmpty) {
                                        await FirebaseFirestore.instance
                                            .collection('orders')
                                            .doc(orderId)
                                            .update({'trackingNumber': value.trim()});
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () async {
                                    final controller = TextEditingController(text: trackingNumber);
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Input Nomor Resi'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: 'Nomor resi pengiriman',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, controller.text),
                                            child: const Text('Simpan'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (result != null && result.trim().isNotEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orderId)
                                          .update({'trackingNumber': result.trim()});
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total: Rp $total',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
      case 'pending':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'diproses':
        return const Icon(Icons.inventory, color: Colors.blue);
      case 'dikirim':
        return const Icon(Icons.local_shipping, color: Colors.purple);
      case 'selesai':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'dibatalkan':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'waiting_confirmation':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'waiting_confirmation':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentProof(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Transfer'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePayment(String orderId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'paymentStatus': 'confirmed'});

      await NotificationService.sendOrderStatusNotification(
        userId: userId,
        orderId: orderId,
        status: 'payment_confirmed',
      );
    } catch (e) {
      debugPrint('Error approving payment: $e');
    }
  }

  Future<void> _rejectPayment(String orderId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': 'rejected',
        'status': 'dibatalkan',
      });

      // Return stock when payment rejected
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final items = orderDoc.data()?['items'] as List<dynamic>? ?? [];
        final batch = FirebaseFirestore.instance.batch();

        for (var item in items) {
          final itemData = item as Map<String, dynamic>;
          final productId = itemData['productId'];
          final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;

          final productRef = FirebaseFirestore.instance
              .collection('products')
              .doc(productId);

          batch.update(productRef, {
            'stock': FieldValue.increment(quantity),
          });
        }
        await batch.commit();
      }

      await NotificationService.sendOrderStatusNotification(
        userId: userId,
        orderId: orderId,
        status: 'payment_rejected',
      );
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
    }
  }
}

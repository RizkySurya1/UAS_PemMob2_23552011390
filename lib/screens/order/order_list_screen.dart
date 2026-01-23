import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product/add_review_screen.dart';
import '../../services/notification_service.dart';

class OrderListScreen extends StatefulWidget {
  final String? initialStatus;

  const OrderListScreen({super.key, this.initialStatus});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Semua', 'status': null},
    {'label': 'Dikemas', 'status': 'diproses'},
    {'label': 'Dikirim', 'status': 'dikirim'},
    {'label': 'Selesai', 'status': 'selesai'},
    {'label': 'Dibatalkan', 'status': 'dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialStatus != null
        ? _tabs.indexWhere((tab) => tab['status'] == widget.initialStatus)
        : 0;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab['label'] as String)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return _buildOrderList(tab['status'] as String?);
        }).toList(),
      ),
    );
  }

  Widget _buildOrderList(String? status) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Silakan login terlebih dahulu'));
    }

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
        
        // Sort manually in Dart instead of Firestore
        orders.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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
            final orderStatus = order['status'] ?? 'pending';
            final createdAt = order['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showOrderDetail(context, order, orderId),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Order #${orderId.substring(0, 8)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(orderStatus),
                        ],
                      ),
                      const Divider(height: 16),
                      ...items.take(2).map((item) {
                        final itemData = item as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${itemData['productName']} x${itemData['quantity']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (items.length > 2)
                        Text(
                          '+${items.length - 2} produk lainnya',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt.toDate()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Text(
                            'Rp $total',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'diproses':
        color = Colors.blue;
        label = 'Dikemas';
        break;
      case 'dikirim':
        color = Colors.purple;
        label = 'Dikirim';
        break;
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        break;
      case 'dibatalkan':
        color = Colors.red;
        label = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showOrderDetail(
      BuildContext context, Map<String, dynamic> order, String orderId) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = order['total'] ?? 0;
    final status = order['status'] ?? 'pending';
    final address = order['address'] ?? '';
    final notes = order['notes'] ?? '';
    final trackingNumber = order['trackingNumber'] ?? '';
    final createdAt = order['createdAt'] as Timestamp?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${orderId.substring(0, 8)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Divider(height: 24),
              const Text(
                'Produk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                final itemData = item as Map<String, dynamic>;
                final price = (itemData['price'] as num?)?.toInt() ?? 0;
                final qty = (itemData['quantity'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemData['productName'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Rp $price x $qty',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${price * qty}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp $total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(address),
              
              // Order Timeline
              const SizedBox(height: 24),
              const Text(
                'Status Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildOrderTimeline(status, trackingNumber, createdAt),
              
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Catatan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(notes),
              ],
              
              // Cancel order button for pending/diproses status
              if (status == 'pending' || status == 'diproses') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelConfirmation(context, orderId, items),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text(
                      'Batalkan Pesanan',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
              
              // Add review button if order is completed and not reviewed yet
              if (status == 'selesai') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('orderId', isEqualTo: orderId)
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .limit(1)
                      .get(),
                  builder: (context, reviewSnapshot) {
                    final hasReview = reviewSnapshot.hasData && 
                        reviewSnapshot.data!.docs.isNotEmpty;
                    
                    if (hasReview) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Terima kasih sudah memberikan review!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Beri Penilaian',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddReviewScreen(
                                    orderId: orderId,
                                  ),
                                ),
                              );
                              
                              if (result == true && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Terima kasih atas review Anda!'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Tulis Review Pesanan'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildOrderTimeline(String status, String trackingNumber, Timestamp? createdAt) {
    final steps = [
      {'status': 'pending', 'label': 'Pesanan Dibuat', 'icon': Icons.receipt},
      {'status': 'diproses', 'label': 'Sedang Dikemas', 'icon': Icons.inventory},
      {'status': 'dikirim', 'label': 'Dalam Pengiriman', 'icon': Icons.local_shipping},
      {'status': 'selesai', 'label': 'Pesanan Selesai', 'icon': Icons.check_circle},
    ];

    final statusOrder = ['pending', 'diproses', 'dikirim', 'selesai'];
    final currentStatusIndex = statusOrder.indexOf(status);

    if (status == 'dibatalkan') {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Dibatalkan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final stepStatus = step['status'] as String;
          final isCompleted = currentStatusIndex >= index;
          final isCurrent = currentStatusIndex == index;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: isCompleted ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          color: isCompleted ? Colors.black : Colors.grey,
                        ),
                      ),
                      if (stepStatus == 'dikirim' && trackingNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Resi: $trackingNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showCancelConfirmation(BuildContext context, String orderId, List<dynamic> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Stok produk akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _cancelOrder(context, orderId, items);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, String orderId, List<dynamic> items) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'dibatalkan'});

      // Return stock for each item
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

      // Send notification
      await NotificationService.sendOrderStatusNotification(
        userId: userId,
        orderId: orderId,
        status: 'dibatalkan',
      );

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan pesanan: $e')),
        );
      }
    }
  }
}

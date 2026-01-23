import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'order/order_list_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifikasi')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(context, userId),
            tooltip: 'Tandai semua sudah dibaca',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
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
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort by date (newest first)
          final notifications = snapshot.data!.docs;
          notifications.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['createdAt'] as Timestamp?;
            final bTimestamp = bData['createdAt'] as Timestamp?;
            
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              
              return _buildNotificationCard(
                context,
                notification,
                notificationId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final title = notification['title'] ?? 'Notifikasi';
    final body = notification['body'] ?? '';
    final read = notification['read'] ?? false;
    final createdAt = notification['createdAt'] as Timestamp?;
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    String formattedDate = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        formattedDate = DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        formattedDate = 'Kemarin';
      } else {
        formattedDate = DateFormat('dd MMM').format(date);
      }
    }

    IconData icon = Icons.notifications;
    Color iconColor = Colors.blue;

    if (data['type'] == 'order_status') {
      icon = Icons.shopping_bag;
      iconColor = Colors.orange;
    }

    return Card(
      color: read ? Colors.white : Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          _markAsRead(notificationId);
          if (data['type'] == 'order_status') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderListScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(BuildContext context, String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }
}

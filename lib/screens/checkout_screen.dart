import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final int total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.cartItems.map((item) {
              final data = item.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['productName']),
                  subtitle: Text('${data['quantity']} x Rp ${data['price']}'),
                  trailing: Text(
                    'Rp ${data['quantity'] * data['price']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Alamat Pengiriman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${widget.total}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Konfirmasi Pesanan',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final orderItems = widget.cartItems.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'productId': data['productId'],
        'productName': data['productName'],
        'price': data['price'],
        'quantity': data['quantity'],
      };
    }).toList();

    final orderRef = await FirebaseFirestore.instance.collection('orders').add({
      'userId': user?.uid,
      'items': orderItems,
      'total': widget.total,
      'address': _addressController.text,
      'notes': _notesController.text,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    for (var item in widget.cartItems) {
      await item.reference.delete();
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(
          orderId: orderRef.id,
          total: widget.total,
          items: orderItems,
          address: _addressController.text,
        ),
      ),
      (route) => route.isFirst,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan berhasil dibuat!')),
    );
  }
}
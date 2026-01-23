import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReviewScreen extends StatefulWidget {
  final String orderId;

  const AddReviewScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User tidak ditemukan');

      // Check if order already reviewed
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('orderId', isEqualTo: widget.orderId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah memberikan review untuk pesanan ini'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, false);
        }
        return;
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'User';

      // Get order data to get product IDs
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      
      final orderData = orderDoc.data();
      final items = orderData?['items'] as List<dynamic>? ?? [];
      final productIds = items
          .map((item) => (item as Map<String, dynamic>)['productId'] as String?)
          .where((id) => id != null)
          .toList();

      // Add review for the order
      await FirebaseFirestore.instance
          .collection('reviews')
          .add({
        'orderId': widget.orderId,
        'userId': user.uid,
        'userName': userName,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'productIds': productIds, // Store all product IDs from order
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Try to mark order as reviewed (optional, ignore if fails)
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'reviewed': true,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Ignore error, review already saved successfully
        debugPrint('Note: Could not mark order as reviewed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tulis Review'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Pesanan',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${widget.orderId.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(
              'Rating',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Review text
            Text(
              'Review',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reviewController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalaman Anda dengan pesanan ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Review tidak boleh kosong';
                }
                if (value.trim().length < 10) {
                  return 'Review minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kirim Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return 'Sangat Puas';
    if (rating >= 4.0) return 'Puas';
    if (rating >= 3.0) return 'Cukup';
    if (rating >= 2.0) return 'Kurang';
    return 'Sangat Kurang';
  }
}

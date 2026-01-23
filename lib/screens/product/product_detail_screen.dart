import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isCheckingFavorite = false);
      return;
    }

    try {
      final favoriteQuery = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: widget.productId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = favoriteQuery.docs.isNotEmpty;
          _isCheckingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingFavorite = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      if (_isFavorite) {
        // Remove from favorites
        final favoriteQuery = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: userId)
            .where('productId', isEqualTo: widget.productId)
            .limit(1)
            .get();

        if (favoriteQuery.docs.isNotEmpty) {
          await favoriteQuery.docs.first.reference.delete();
        }

        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dihapus dari wishlist')),
          );
        }
      } else {
        // Add to favorites
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': userId,
          'productId': widget.productId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke wishlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          if (!_isCheckingFavorite)
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade200,
              child: widget.product['imageUrl'] != null
                  ? Image.network(widget.product['imageUrl'], fit: BoxFit.cover)
                  : Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'] ?? 'Produk',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('productIds', arrayContains: widget.productId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '5.0',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(0 review)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      }

                      final reviews = snapshot.data!.docs;
                      final reviewCount = reviews.length;
                      
                      double totalRating = 0;
                      if (reviewCount > 0) {
                        for (var doc in reviews) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalRating += (data['rating'] as num?)?.toDouble() ?? 0;
                        }
                      }
                      
                      final averageRating = reviewCount > 0 ? totalRating / reviewCount : 5.0;

                      return InkWell(
                        onTap: reviewCount > 0
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductReviewsScreen(
                                      productId: widget.productId,
                                      productName: widget.product['name'] ?? 'Produk',
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($reviewCount review)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (reviewCount > 0) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rp ${widget.product['price'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stok: ${widget.product['stock'] ?? 0}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_quantity < (widget.product['stock'] ?? 0)) {
                            setState(() => _quantity++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'] ??
                        'Tidak ada deskripsi tersedia.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Spesifikasi Produk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.product['specifications'] != null)
                    ...(widget.product['specifications'] as Map<String, dynamic>)
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(entry.key,
                                      style:
                                          const TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 16),
                                  Text(': ${entry.value}'),
                                ],
                              ),
                            ))
                        ,
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Tambah ke Keranjang',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    // Normalisasi harga & stok agar pasti numerik
    final price = (widget.product['price'] as num?)?.toInt() ?? 0;
    final stock = (widget.product['stock'] as num?)?.toInt() ?? 0;

    if (stock > 0 && _quantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok tersisa $stock')), // beri tahu stok tersisa
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('carts').add({
        'userId': user.uid,
        'productId': widget.productId,
        'productName': widget.product['name'] ?? 'Produk',
        'price': price,
        'quantity': _quantity,
        'imageUrl': widget.product['imageUrl'],
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk ditambahkan ke keranjang'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString()}')),
      );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product/product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist Saya'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data!.docs;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada produk favorit',
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
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index].data() as Map<String, dynamic>;
              final productId = favorite['productId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder: (context, productSnap) {
                  if (!productSnap.hasData || !productSnap.data!.exists) {
                    return const SizedBox();
                  }

                  final product = productSnap.data!.data() as Map<String, dynamic>;
                  final price = (product['price'] as num?)?.toInt() ?? 0;
                  final stock = (product['stock'] as num?)?.toInt() ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: productId,
                              product: {
                                'id': productId,
                                ...product,
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product['imageUrl'] != null
                                  ? Image.network(
                                      product['imageUrl'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp $price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stok: $stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: stock > 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Remove button
                            IconButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('favorites')
                                    .doc(favorites[index].id)
                                    .delete();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dihapus dari wishlist'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
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
        },
      ),
    );
  }
}

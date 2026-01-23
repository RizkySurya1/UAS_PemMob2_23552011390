import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order/new_checkout_screen.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          final cartItems = snapshot.data!.docs;

          if (cartItems.isEmpty) {
            return _buildEmptyState();
          }

          int total = 0;
          for (var item in cartItems) {
            final data = item.data() as Map<String, dynamic>;
            final price = (data['price'] as num?)?.toInt() ?? 0;
            final qty = (data['quantity'] as num?)?.toInt() ?? 0;
            total += price * qty;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index].data() as Map<String, dynamic>;
                    final price = (item['price'] as num?)?.toInt() ?? 0;
                    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
                      elevation: AppTheme.elevationS,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                child: item['imageUrl'] != null
                                    ? Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image, color: Colors.grey, size: 32);
                                        },
                                      )
                                    : const Icon(Icons.image, color: Colors.grey, size: 32),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceM),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productName'] ?? 'Produk',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppTheme.spaceXS),
                                  Text(
                                    'Rp ${_formatPrice(price)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceXS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spaceS,
                                      vertical: AppTheme.spaceXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                    ),
                                    child: Text(
                                      'Qty: $quantity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete Button
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppTheme.errorColor,
                                  onPressed: () {
                                    _showDeleteConfirmation(context, cartItems[index]);
                                  },
                                ),
                                const SizedBox(height: AppTheme.spaceS),
                                Text(
                                  'Rp ${_formatPrice(price * quantity)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Item count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cartItems.length} item',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice(total)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppTheme.spaceL),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice(total)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewCheckoutScreen(
                                  cartItems: cartItems,
                                  total: total,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: AppTheme.elevationS,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined),
                              SizedBox(width: AppTheme.spaceS),
                              Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to format price
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        title: const Text('Hapus Item'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              item.reference.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item dihapus dari keranjang')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Loading skeleton
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'Keranjang Kosong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Belum ada produk di keranjang Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
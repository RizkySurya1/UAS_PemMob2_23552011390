import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import 'product/product_detail_screen.dart';
import 'cart_screen.dart';
import 'booking/booking_list_screen.dart';
import 'profile/profile_screen.dart';
import 'product/products_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(context),
          const ProductsScreen(),
          const CartScreen(),
          const BookingListScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.motorcycle, color: Colors.white, size: 28),
                            SizedBox(width: AppTheme.spaceM),
                            Text(
                              'BENGKEL PAKISTUNES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari produk bengkel...',
                              hintStyle: TextStyle(color: AppTheme.textSecondary),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceL,
                                vertical: AppTheme.spaceM,
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductsScreen(
                                      searchQuery: value.trim(),
                                    ),
                                  ),
                                );
                              }
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildServiceMenu(context),
                _buildPromoSection(),
                _buildProductSection(context),
                const SizedBox(height: AppTheme.spaceXL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMenu(BuildContext context) {
    final services = [
      {
        'icon': Icons.build,
        'label': 'Peralatan\nService',
        'category': 'Peralatan Service',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Icons.local_drink,
        'label': 'Oli &\nPelumas',
        'category': 'Oli & Pelumas',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Icons.settings,
        'label': 'Suku\nCadang',
        'category': 'Suku Cadang',
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': Icons.sports_motorsports,
        'label': 'Sparepart\nRacing',
        'category': 'Sparepart Racing',
        'color': const Color(0xFFE91E63),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: services.map((service) {
          final color = service['color'] as Color;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductsScreen(
                          selectedCategory: service['category'] as String,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceM),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Icon(
                            service['icon'] as IconData,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          service['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Image.asset(
          'assets/images/banner_promo.png',
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildProductSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceL,
            vertical: AppTheme.spaceM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produk Populer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to products screen
                  setState(() {
                    _currentIndex = 1; // Switch to Products tab
                  });
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .limit(6)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildProductSkeleton();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final products = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppTheme.spaceM,
                mainAxisSpacing: AppTheme.spaceM,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index].data() as Map<String, dynamic>;
                final productId = products[index].id;
                final price = (product['price'] as num?)?.toInt() ?? 0;
                final stock = (product['stock'] as num?)?.toInt() ?? 0;

                return _buildProductCard(
                  context,
                  productId,
                  product,
                  price,
                  stock,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
    int price,
    int stock,
  ) {
    return Card(
      elevation: AppTheme.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: productId,
                product: {'id': productId, ...product},
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusM),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusM),
                    ),
                    child: product['imageUrl'] != null
                        ? Image.network(
                            product['imageUrl'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                  ),
                ),
                // Stock Badge
                if (stock <= 5)
                  Positioned(
                    top: AppTheme.spaceS,
                    right: AppTheme.spaceS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceS,
                        vertical: AppTheme.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: stock == 0 ? AppTheme.error : AppTheme.warning,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        stock == 0 ? 'Habis' : 'Stok: $stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Produk',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${_formatPrice(price)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.spaceM,
        mainAxisSpacing: AppTheme.spaceM,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                color: Colors.grey.shade200,
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXXL),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'Belum ada produk',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

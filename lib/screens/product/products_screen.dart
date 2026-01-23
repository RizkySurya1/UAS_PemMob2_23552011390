import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../product/product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? searchQuery;

  const ProductsScreen({super.key, this.selectedCategory, this.searchQuery});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late String _selectedCategory;
  String? _searchQuery;

  final List<String> categories = [
    'Semua',
    'Peralatan Service',
    'Oli & Pelumas',
    'Suku Cadang',
    'Sparepart Racing',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? 'Semua';
    _searchQuery = widget.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceS),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppTheme.backgroundColor,
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    elevation: isSelected ? AppTheme.elevationS : 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceL,
                      vertical: AppTheme.spaceS,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Products List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'Semua'
                  ? FirebaseFirestore.instance
                      .collection('products')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('products')
                      .where('category', isEqualTo: _selectedCategory)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var products = snapshot.data!.docs;

                // Filter by search query if provided
                if (_searchQuery != null && _searchQuery!.isNotEmpty) {
                  final query = _searchQuery!.toLowerCase();
                  products = products.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final description = (data['description'] ?? '').toString().toLowerCase();
                    return name.contains(query) || description.contains(query);
                  }).toList();
                }

                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.spaceM,
                    mainAxisSpacing: AppTheme.spaceM,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product =
                        products[index].data() as Map<String, dynamic>;
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
          ),
        ],
      ),
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
      margin: EdgeInsets.zero,
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

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.spaceM,
        mainAxisSpacing: AppTheme.spaceM,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.zero,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text(
              _searchQuery != null && _searchQuery!.isNotEmpty
                  ? 'Produk tidak ditemukan'
                  : 'Belum ada produk',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery != null && _searchQuery!.isNotEmpty) ...{
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Coba kata kunci lain',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            },
          ],
        ),
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

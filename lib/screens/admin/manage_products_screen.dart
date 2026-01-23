import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/catalog_service.dart';
import '../../models/product.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogService = CatalogService();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Produk')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Product>>(
        stream: catalogService.productsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('Belum ada produk'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: p.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image),
                        ),
                  title: Text(p.name),
                  subtitle: Text('Rp ${_formatPrice(p.price)} • Stok: ${p.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(context, product: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, catalogService, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _confirmDelete(BuildContext context, CatalogService service, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              service.deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ProductFormScreen(product: product),
      ),
    );
  }
}

class _ProductFormScreen extends StatefulWidget {
  final Product? product;

  const _ProductFormScreen({this.product});

  @override
  State<_ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<_ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  String _selectedCategory = 'Peralatan Service';

  final List<String> _categories = [
    'Peralatan Service',
    'Oli & Pelumas',
    'Suku Cadang',
    'Sparepart Racing',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _priceCtrl.text = widget.product!.price.toString();
      _descCtrl.text = widget.product!.description;
      _imageUrlCtrl.text = widget.product!.imageUrl;
      _stockCtrl.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category ?? 'Peralatan Service';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String finalImageUrl = _imageUrlCtrl.text.trim();

      final catalogService = CatalogService();
      final productData = Product(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        price: int.tryParse(_priceCtrl.text) ?? 0,
        description: _descCtrl.text.trim(),
        imageUrl: finalImageUrl,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        category: _selectedCategory,
        rating: widget.product?.rating ?? 5.0,
        createdAt: widget.product?.createdAt ?? Timestamp.now(),
      );

      if (widget.product == null) {
        await catalogService.addProduct(productData);
      } else {
        await catalogService.updateProduct(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Produk berhasil ditambahkan'
                : 'Produk berhasil diupdate'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan produk: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Section
              const Text(
                'Gambar Produk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageUrlCtrl.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrlCtrl.text,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('URL gambar tidak valid', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Preview gambar', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upload gambar ke ImgBB.com atau Imgur.com, lalu paste URL-nya di sini',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL Gambar *',
                  hintText: 'https://i.ibb.co/xxx/image.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.link),
                  helperText: 'Gunakan ImgBB atau Imgur untuk upload gambar gratis',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URL gambar harus diisi';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return 'URL harus dimulai dengan http:// atau https://';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Product Info
              const Text(
                'Informasi Produk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Produk *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga (Rp) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stok *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Deskripsi detail produk...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(
                    widget.product == null ? 'Tambah Produk' : 'Update Produk',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

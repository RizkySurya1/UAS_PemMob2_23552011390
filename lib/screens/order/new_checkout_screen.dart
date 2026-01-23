import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'order_success_screen.dart';
import '../profile/address_list_screen.dart';

class NewCheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final int total;

  const NewCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<NewCheckoutScreen> createState() => _NewCheckoutScreenState();
}

class _NewCheckoutScreenState extends State<NewCheckoutScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isInitializing = true;
  String _paymentMethod = 'cod';
  Map<String, dynamic>? _selectedAddress;
  File? _paymentProofImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final defaultAddress = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (defaultAddress.docs.isNotEmpty && mounted) {
        final doc = defaultAddress.docs.first;
        setState(() {
          _selectedAddress = {
            'id': doc.id,
            ...doc.data(),
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading default address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressListScreen(isSelectMode: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  Future<void> _pickPaymentProof() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _paymentProofImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<String?> _uploadPaymentProof() async {
    if (_paymentProofImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final fileName = 'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('payment_proofs')
          .child(userId!)
          .child(fileName);

      await ref.putFile(_paymentProofImage!);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload bukti: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _processOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih alamat pengiriman terlebih dahulu')),
      );
      return;
    }

    if (_paymentMethod == 'transfer' && _paymentProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload bukti transfer terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User tidak ditemukan');

      // Upload payment proof if transfer
      String? paymentProofUrl;
      if (_paymentMethod == 'transfer') {
        paymentProofUrl = await _uploadPaymentProof();
        if (paymentProofUrl == null) {
          throw Exception('Gagal upload bukti transfer');
        }
      }

      // Create order items
      final items = widget.cartItems.map((item) {
        final data = item.data() as Map<String, dynamic>;
        return {
          'productId': data['productId'],
          'productName': data['productName'],
          'price': (data['price'] as num?)?.toInt() ?? 0,
          'quantity': (data['quantity'] as num?)?.toInt() ?? 0,
          'imageUrl': data['imageUrl'],
        };
      }).toList();

      // Check stock availability and decrease stock
      final stockBatch = FirebaseFirestore.instance.batch();
      for (var item in widget.cartItems) {
        final data = item.data() as Map<String, dynamic>;
        final productId = data['productId'];
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;

        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (!productDoc.exists) {
          throw Exception('Produk ${data['productName']} tidak ditemukan');
        }

        final currentStock = (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
        if (currentStock < quantity) {
          throw Exception('Stok ${data['productName']} tidak mencukupi');
        }

        // Decrease stock
        stockBatch.update(productDoc.reference, {
          'stock': FieldValue.increment(-quantity),
        });
      }
      await stockBatch.commit();

      // Create order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': items,
        'total': widget.total,
        'addressId': _selectedAddress!['id'],
        'address': _selectedAddress!['fullAddress'],
        'receiverName': _selectedAddress!['name'],
        'receiverPhone': _selectedAddress!['phone'],
        'notes': _notesController.text.trim(),
        'paymentMethod': _paymentMethod,
        'paymentProofUrl': paymentProofUrl,
        'paymentStatus': _paymentMethod == 'cod' ? 'pending' : 'waiting_confirmation',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete cart items
      final batch = FirebaseFirestore.instance.batch();
      for (var item in widget.cartItems) {
        batch.delete(item.reference);
      }
      await batch.commit();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: orderRef.id,
              total: widget.total,
              items: items,
              address: _selectedAddress!['fullAddress'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pesanan: $e')),
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
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Validate cart items
    if (widget.cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Checkout'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Keranjang kosong',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.cartItems.map((item) {
              try {
                final data = item.data() as Map<String, dynamic>;
                final price = (data['price'] as num?)?.toInt() ?? 0;
                final qty = (data['quantity'] as num?)?.toInt() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: data['imageUrl'] != null
                        ? Image.network(
                            data['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image),
                          ),
                    title: Text(data['productName'] ?? 'Produk'),
                    subtitle: Text('$qty x Rp ${_formatPrice(price)}'),
                    trailing: Text(
                      'Rp ${_formatPrice(qty * price)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              } catch (e) {
                debugPrint('Error rendering cart item: $e');
                return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: 24),

            // Shipping Address
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: _selectedAddress == null
                  ? ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Pilih Alamat'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectAddress,
                    )
                  : ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(_selectedAddress!['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedAddress!['phone'] ?? ''),
                          const SizedBox(height: 4),
                          Text(_selectedAddress!['fullAddress'] ?? ''),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: _selectAddress,
                        child: const Text('Ubah'),
                      ),
                      isThreeLine: true,
                    ),
            ),
            const SizedBox(height: 24),

            // Payment Method
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'cod',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                        _paymentProofImage = null;
                      });
                    },
                    title: const Text('COD (Cash on Delivery)'),
                    subtitle: const Text('Bayar saat barang diterima'),
                    secondary: const Icon(Icons.money),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'transfer',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    title: const Text('Transfer Bank'),
                    subtitle: const Text('BCA / Mandiri / BNI'),
                    secondary: const Icon(Icons.account_balance),
                  ),
                ],
              ),
            ),

            // Transfer Instructions
            if (_paymentMethod == 'transfer') ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Transfer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBankInfo('BCA', '1234567890', 'Bengkel Pakistunes'),
                      const Divider(),
                      _buildBankInfo('Mandiri', '0987654321', 'Bengkel Pakistunes'),
                      const SizedBox(height: 12),
                      Text(
                        'Total: Rp ${_formatPrice(widget.total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Upload Payment Proof
              const Text(
                'Upload Bukti Transfer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: _pickPaymentProof,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _paymentProofImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _paymentProofImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk upload bukti transfer',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Contoh: Kirim sore hari',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${_formatPrice(widget.total)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _isUploadingImage) ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading || _isUploadingImage
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Buat Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
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

  Widget _buildBankInfo(String bankName, String accountNumber, String accountName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bankName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('No. Rek: $accountNumber'),
        Text('a.n. $accountName'),
      ],
    );
  }
}

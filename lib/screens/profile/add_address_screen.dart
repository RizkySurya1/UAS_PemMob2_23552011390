import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressScreen extends StatefulWidget {
  final String? addressId;
  final Map<String, dynamic>? existingAddress;

  const AddAddressScreen({
    super.key,
    this.addressId,
    this.existingAddress,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedLabel = 'Rumah';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _labels = ['Rumah', 'Kantor', 'Apartemen', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _nameController.text = widget.existingAddress!['name'] ?? '';
      _phoneController.text = widget.existingAddress!['phone'] ?? '';
      _addressController.text = widget.existingAddress!['fullAddress'] ?? '';
      _selectedLabel = widget.existingAddress!['label'] ?? 'Rumah';
      _isDefault = widget.existingAddress!['isDefault'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User tidak ditemukan');

      final addressData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'fullAddress': _addressController.text.trim(),
        'label': _selectedLabel,
        'isDefault': _isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.addressId != null) {
        // Update existing address
        await FirebaseFirestore.instance
            .collection('addresses')
            .doc(widget.addressId)
            .update(addressData);
      } else {
        // Create new address
        addressData['createdAt'] = FieldValue.serverTimestamp();
        
        // If this is the first address, make it default
        final existingAddresses = await FirebaseFirestore.instance
            .collection('addresses')
            .where('userId', isEqualTo: userId)
            .get();
        
        if (existingAddresses.docs.isEmpty) {
          addressData['isDefault'] = true;
        }

        await FirebaseFirestore.instance
            .collection('addresses')
            .add(addressData);
      }

      // If set as default, remove default from others
      if (_isDefault) {
        final addresses = await FirebaseFirestore.instance
            .collection('addresses')
            .where('userId', isEqualTo: userId)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in addresses.docs) {
          if (doc.id != widget.addressId) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.addressId != null
                ? 'Alamat berhasil diperbarui'
                : 'Alamat berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan alamat: $e'),
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
    final isEdit = widget.addressId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Alamat' : 'Tambah Alamat'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Penerima',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama penerima tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: '08123456789',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                  return 'Format nomor telepon tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Alamat Lengkap',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'Jalan, RT/RW, Kelurahan, Kecamatan, Kota, Provinsi, Kode Pos',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat lengkap tidak boleh kosong';
                }
                if (value.trim().length < 20) {
                  return 'Alamat minimal 20 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Label
            const Text(
              'Label Alamat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _labels.map((label) {
                final isSelected = _selectedLabel == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLabel = label;
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Set as default
            CheckboxListTile(
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
              title: const Text('Jadikan alamat utama'),
              subtitle: const Text('Alamat ini akan digunakan sebagai alamat default'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
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
                  : Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Alamat',
                      style: const TextStyle(
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
}

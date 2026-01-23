import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        _nameController.text = data?['name'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _addressController.text = data?['address'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User tidak ditemukan');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
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
        title: const Text('Edit Profil'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field (Read-only)
            TextFormField(
              initialValue: FirebaseAuth.instance.currentUser?.email ?? '',
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Phone Field
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
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                    return 'Format nomor telepon tidak valid';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Field
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alamat',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'Masukkan alamat lengkap',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
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
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

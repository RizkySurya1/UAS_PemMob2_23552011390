import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../order/order_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../booking/booking_history_screen.dart';
import '../profile/address_list_screen.dart';
import '../notification_screen.dart';
import '../product/wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ⛔ USER NULL → KEMBALI KE LOGIN
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR / DATA TIDAK ADA
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Data profil tidak ditemukan'),
            );
          }

          final userData =
              snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              // Profile Header with Gradient
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceL,
                        AppTheme.spaceL,
                        AppTheme.spaceL,
                        AppTheme.spaceXXL,
                      ),
                      child: Column(
                        children: [
                          // Avatar with border
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Text(
                                (userData['name'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceM),
                          // Name
                          Text(
                            userData['name'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          // Email
                          Text(
                            userData['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          if (userData['phone'] != null) ...{
                            const SizedBox(height: AppTheme.spaceXS),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: AppTheme.spaceXS),
                                Text(
                                  userData['phone'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          },
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderStatusSection(context, user.uid),
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Account Section
                      _buildSectionTitle('Akun'),
                      _buildMenuCard(
                        icon: Icons.notifications_outlined,
                        iconColor: AppTheme.accentColor,
                        title: 'Notifikasi',
                        subtitle: 'Lihat notifikasi pesanan',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        icon: Icons.person_outline,
                        iconColor: AppTheme.primaryColor,
                        title: 'Edit Profil',
                        subtitle: 'Ubah informasi profil Anda',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true && context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.location_on_outlined,
                        iconColor: AppTheme.errorColor,
                        title: 'Alamat Saya',
                        subtitle: 'Kelola alamat pengiriman',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressListScreen(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Orders Section
                      _buildSectionTitle('Pesanan & Service'),
                      _buildMenuCard(
                        icon: Icons.receipt_long_outlined,
                        iconColor: Colors.purple,
                        title: 'Riwayat Pesanan',
                        subtitle: 'Lihat semua pesanan Anda',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderListScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        icon: Icons.build_outlined,
                        iconColor: Colors.green,
                        title: 'Riwayat Service',
                        subtitle: 'Lihat riwayat booking service',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookingHistoryScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        icon: Icons.favorite_outline,
                        iconColor: Colors.red,
                        title: 'Wishlist',
                        subtitle: 'Produk favorit saya',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WishlistScreen(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Support Section
                      _buildSectionTitle('Bantuan & Informasi'),
                      _buildMenuCard(
                        icon: Icons.help_outline,
                        iconColor: Colors.teal,
                        title: 'Bantuan',
                        subtitle: 'FAQ dan dukungan pelanggan',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              title: const Text('Pusat Bantuan'),
                              content: const Text(
                                'Butuh bantuan? Kami siap membantu Anda!\n\n'
                                '📱 WhatsApp: 0812-3456-7890\n'
                                '📧 Email: support@bengkelpakistunes.com\n\n'
                                '⏰ Jam Layanan:\n'
                                'Senin - Sabtu: 08.00 - 17.00 WIB\n'
                                'Minggu: Libur\n\n'
                                'Tim customer service kami siap melayani pertanyaan, keluhan, atau bantuan teknis terkait aplikasi dan layanan bengkel.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        icon: Icons.info_outline,
                        iconColor: Colors.blueGrey,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Versi 1.0.0',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              title: const Text('Tentang Aplikasi'),
                              content: const Text(
                                '🔧 Bengkel Pakistunes\n'
                                'Versi 1.0.0\n\n'
                                'Aplikasi mobile bengkel motor terpercaya untuk semua kebutuhan perawatan dan perbaikan motor Anda. '
                                'Kami menyediakan layanan booking servis, pembelian produk sparepart, dan tracking order dengan mudah.\n\n'
                                '📍 Alamat:\n'
                                'Jl. Pakis Raya No. 123\n'
                                'Bandung, Jawa Barat\n\n'
                                '⏰ Jam Operasional:\n'
                                'Senin - Sabtu: 08.00 - 17.00 WIB\n'
                                'Minggu: Libur\n\n'
                                '© 2026 Bengkel Pakistunes. All rights reserved.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Logout Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await context.read<AuthService>().logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spaceL,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: AppTheme.spaceS),
                                  Text(
                                    'Keluar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spaceXXL),
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

  Widget _buildOrderStatusSection(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final orders = snapshot.data?.docs ?? [];
        
        final dikemas = orders.where((o) => (o.data() as Map)['status'] == 'diproses').length;
        final dikirim = orders.where((o) => (o.data() as Map)['status'] == 'dikirim').length;
        final selesai = orders.where((o) => (o.data() as Map)['status'] == 'selesai').length;
        final dibatalkan = orders.where((o) => (o.data() as Map)['status'] == 'dibatalkan').length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pesanan Saya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderListScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOrderStatusItem(
                      context,
                      icon: Icons.inventory,
                      label: 'Dikemas',
                      count: dikemas,
                      status: 'diproses',
                    ),
                    _buildOrderStatusItem(
                      context,
                      icon: Icons.local_shipping,
                      label: 'Dikirim',
                      count: dikirim,
                      status: 'dikirim',
                    ),
                    _buildOrderStatusItem(
                      context,
                      icon: Icons.check_circle,
                      label: 'Selesai',
                      count: selesai,
                      status: 'selesai',
                    ),
                    _buildOrderStatusItem(
                      context,
                      icon: Icons.cancel,
                      label: 'Dibatalkan',
                      count: dibatalkan,
                      status: 'dibatalkan',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Section title widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spaceXS,
        bottom: AppTheme.spaceM,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Menu card widget
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildOrderStatusItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required String status,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderListScreen(initialStatus: status),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              if (count > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

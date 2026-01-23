import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'home_content_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _routeByRole();
  }

  Future<void> _routeByRole() async {
    final auth = context.read<AuthService>();
    final role = await auth.getUserRole();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeContentScreen();
  }
}

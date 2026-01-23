import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
            ),
          ),
          
          // Back Button
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Title
                    const Text(
                      'Daftar Akun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              hintText: 'Masukkan nama lengkap',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceL),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@')) {
                                return 'Email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceL),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'No. Telepon',
                              hintText: '08xxxxxxxxxx',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'No. telepon tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceL),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Minimal 6 karakter',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceXL),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();

    try {
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi gagal: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}

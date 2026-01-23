import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/register_screen.dart';
import 'auth/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background Header
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
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
                    
                    // Logo and Title
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.motorcycle,
                              size: 60,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceL),
                          const Text(
                            'BENGKEL',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const Text(
                            'PAKIS TUNES',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Login Form Card
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
                          const Text(
                            'Masuk',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXL),

                          // EMAIL
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
                                  color: AppTheme.primaryColor,
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

                          // PASSWORD
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Masukkan password',
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
                                  color: AppTheme.primaryColor,
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

                          // LOGIN BUTTON
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
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
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceL),

                          // REGISTER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();

    try {
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      /// ⬇️ BIARKAN SPLASH YANG CEK ROLE
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal. Periksa email dan password.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

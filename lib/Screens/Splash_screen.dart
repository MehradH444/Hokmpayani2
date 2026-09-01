import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  /// بررسی توکن و وضعیت ورود کاربر
  Future<void> _checkAuthentication() async {
    // ایجاد وقفه کوتاه ۲ ثانیه‌ای برای نمایش انیمیشن و لوگوی بازی
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (isAuthenticated) {
      // اگر توکن معتبر است، انتقال به صفحه لابی اصلی
      Navigator.of(context).pushReplacementNamed('/lobby');
    } else {
      // در غیر این صورت، انتقال به صفحه ورود / ثبت‌نام
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // لوگو / آیکون پاسور بازی
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.shade700.withOpacity(0.15),
                border: Border.all(color: Colors.amber.shade600, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade600.withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(
                Icons.style,
                size: 80,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),

            // عنوان بازی
            const Text(
              'حکــم مستــر',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional Online Hokm Engine',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 50),

            // لودینگ بارگذاری
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'در حال اتصال به سرور...',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

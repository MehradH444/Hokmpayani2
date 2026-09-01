import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // فیلدهای ورود
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // فیلدهای ثبت‌نام
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('لطفاً تمامی فیلدها را پر کنید');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(username, password);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/lobby');
    } else {
      _showError(auth.errorMessage ?? 'ورود ناموفق بود');
    }
  }

  Future<void> _handleRegister() async {
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('لطفاً نام کاربری و رمز عبور را وارد کنید');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(username, password);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/lobby');
    } else {
      _showError(auth.errorMessage ?? 'ثبت‌نام انجام نشد');
    }
  }

  Future<void> _handleGuestLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginAsGuest();

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/lobby');
    } else {
      _showError(auth.errorMessage ?? 'ورود مهمان با خطا مواجه شد');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون بالای کادر ورود
                  const Icon(Icons.style, size: 50, color: Colors.amber),
                  const SizedBox(height: 8),
                  const Text(
                    'ورود به حساب کاربری',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),

                  // تب‌های ورود و ثبت‌نام
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(text: 'ورود'),
                      Tab(text: 'ثبت‌نام'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 160,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // فرم ورود
                        Column(
                          children: [
                            TextField(
                              controller: _loginUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'نام کاربری',
                                prefixIcon: Icon(Icons.person, color: Colors.amber),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _loginPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'رمز عبور',
                                prefixIcon: Icon(Icons.lock, color: Colors.amber),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        // فرم ثبت‌نام
                        Column(
                          children: [
                            TextField(
                              controller: _regUsernameController,
                              decoration: const InputDecoration(
                                labelText: 'نام کاربری جدید',
                                prefixIcon: Icon(Icons.person_add, color: Colors.amber),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _regPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'رمز عبور جدید',
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.amber),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // دکمه اصلی (ورود / ثبت‌نام)
                  if (auth.isLoading)
                    const CircularProgressIndicator(color: Colors.amber)
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _handleLogin();
                        } else {
                          _handleRegister();
                        }
                      },
                      child: Text(
                        _tabController.index == 0 ? 'ورود به بازی' : 'ایجاد حساب جدید',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // دکمه ورود مهمان
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: auth.isLoading ? null : _handleGuestLogin,
                    child: const Text('ورود سریع به عنوان مهمان', style: TextStyle(color: Colors.amber)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

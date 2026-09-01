import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    // فعال‌سازی شنونده‌های وب‌سوکت برای کاربر جاری
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<GameProvider>(context, listen: false)
            .listenToSocketEvents(auth.user!['_id']);
      }
    });
  }

  /// پیوستن به میز بازی بر اساس شناسه اتاق
  void _joinRoom(String roomId) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.resetGame();
    Navigator.of(context).pushNamed('/game', arguments: roomId);
  }

  /// دریافت پاداش روزانه
  Future<void> _claimDailyReward() async {
    final response = await ApiService.claimDailyReward();
    if (!mounted) return;

    if (response['success'] == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.updateWallet(response['wallet']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تبریک! ${response['reward']['amount']} ${response['reward']['type'] == 'coins' ? 'سکه' : 'الماس'} دریافت کردید.',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'پاداش امروز را قبلاً دریافت کرده‌اید', textAlign: TextAlign.center),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // هدر بالای صفحه: اطلاعات کاربر، سکه و الماس
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF020617).withOpacity(0.6),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Text(
                        user != null && user['username'] != null
                            ? user['username'][0].toUpperCase()
                            : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['username'] ?? 'بازیکن',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'سطح: ${user?['level'] ?? 1}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // سکه
                    _buildCurrencyChip(
                      Icons.monetization_on,
                      Colors.amber,
                      '${user?['wallet']?['coins'] ?? 0}',
                    ),
                    const SizedBox(width: 8),

                    // الماس
                    _buildCurrencyChip(
                      Icons.diamond,
                      Colors.cyanAccent,
                      '${user?['wallet']?['gems'] ?? 0}',
                    ),
                    const SizedBox(width: 12),

                    // دکمه خروج
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: () async {
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // بخش انتخاب کارت‌های ورود به میز بازی
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // کادر بازی آنلاین سریع
                      Expanded(
                        child: _buildLobbyCard(
                          title: 'شروع سریع',
                          subtitle: 'ورود به میز ۴ نفره معمولی',
                          icon: Icons.flash_on,
                          color: Colors.amber.shade700,
                          onTap: () => _joinRoom('room_standard_1'),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // کادر میز حرفه‌ای
                      Expanded(
                        child: _buildLobbyCard(
                          title: 'میز حرفه‌ای‌ها',
                          subtitle: 'ورودی ۵,۰۰۰ سکه',
                          icon: Icons.star,
                          color: Colors.purpleAccent,
                          onTap: () => _joinRoom('room_pro_1'),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // تورنمنت
                      Expanded(
                        child: _buildLobbyCard(
                          title: 'تورنمنت حکم',
                          subtitle: 'رقابت و جام قهرمانی',
                          icon: Icons.emoji_events,
                          color: Colors.redAccent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تورنمنت بعدی به زودی شروع می‌شود!')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // منوی پایین صفحه (فروشگاه، گردونه شانس، کلن)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                color: const Color(0xFF020617).withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavBtn(
                      icon: Icons.shopping_cart,
                      label: 'فروشگاه',
                      color: Colors.amber,
                      onTap: () => Navigator.of(context).pushNamed('/shop'),
                    ),
                    _buildBottomNavBtn(
                      icon: Icons.card_giftcard,
                      label: 'پاداش روزانه',
                      color: Colors.greenAccent,
                      onTap: _claimDailyReward,
                    ),
                    _buildBottomNavBtn(
                      icon: Icons.shield,
                      label: 'کلن‌ها',
                      color: Colors.cyanAccent,
                      onTap: () => Navigator.of(context).pushNamed('/clan'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLobbyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

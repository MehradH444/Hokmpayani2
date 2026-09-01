import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ارائه دهندگان مدیریت وضعیت (Providers)
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';

// صفحات اپلیکیشن (Screens)
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_table_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/clan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // قفل کردن حالت صفحه به صورت افقی (Landscape) برای تجربه بازی حکم آنلاین
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // مخفی کردن نوار وضعیت گوشی جهت نمایش تمام صفحه
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const HokmMasterApp());
}

class HokmMasterApp extends StatelessWidget {
  const HokmMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'حکم مستر (Hokm Master)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // پس زمینه تاریک کازینویی
          fontFamily: 'Vazirmatn', // فونت استاندارد
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/lobby': (context) => const LobbyScreen(),
          '/game': (context) => const GameTableScreen(),
          '/shop': (context) => const ShopScreen(),
          '/clan': (context) => const ClanScreen(),
        },
      ),
    );
  }
}

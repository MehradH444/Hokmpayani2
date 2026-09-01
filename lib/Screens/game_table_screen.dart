import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class GameTableScreen extends StatefulWidget {
  const GameTableScreen({super.key});

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  String? _roomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomId == null) {
      _roomId = ModalRoute.of(context)?.settings.arguments as String? ?? 'room_standard_1';
      final game = Provider.of<GameProvider>(context, listen: false);
      // ورود به اتاق سوکت
      game.resetGame();
    }
  }

  // تبدیل نام انگلیسی خال به آیکون و رنگ
  Widget _getSuitIcon(String suit, {double size = 20}) {
    switch (suit) {
      case 'hearts':
        return Icon(Icons.favorite, color: Colors.red, size: size);
      case 'diamonds':
        return Icon(Icons.style, color: Colors.redAccent, size: size);
      case 'clubs':
        return Icon(Icons.filter_vintage, color: Colors.white, size: size);
      case 'spades':
      default:
        return Icon(Icons.park, color: Colors.lightBlueAccent, size: size);
    }
  }

  // دیالوگ انتخاب حکم برای حاکم
  void _showHokmSelectionDialog(GameProvider game) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('شما حاکم هستید! خال حکم را انتخاب کنید:',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 16)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _hokmOptionBtn(game, 'spades', Icons.park, Colors.lightBlueAccent),
            _hokmOptionBtn(game, 'hearts', Icons.favorite, Colors.red),
            _hokmOptionBtn(game, 'diamonds', Icons.style, Colors.redAccent),
            _hokmOptionBtn(game, 'clubs', Icons.filter_vintage, Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _hokmOptionBtn(GameProvider game, String suit, IconData icon, Color color) {
    return IconButton(
      iconSize: 40,
      icon: Icon(icon, color: color),
      onPressed: () {
        game.selectHokm(suit);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final game = Provider.of<GameProvider>(context);

    // اگر کاربر حاکم باشد و هنوز حکم انتخاب نشده باشد، دیالوگ را باز کن
    if (game.amIHakem && game.hokmSuit == null && game.myCards.length == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHokmSelectionDialog(game);
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          radialGradient: RadialGradient(
            colors: [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF0F172A)],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // نوار بالای میز (امتیازات و حکم)
              Positioned(
                top: 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // امتیازات
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Text(
                        'تیم ما: ${game.teamScore['team1'] ?? 0}  |  تیم حریف: ${game.teamScore['team2'] ?? 0}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // خروج از بازی
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // خال حکم
                    if (game.hokmSuit != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            const Text('حکم: ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            _getSuitIcon(game.hokmSuit!),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // مرکز میز (کارت‌های انداخته‌شده)
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.2), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: game.currentTrick.map((played) {
                      final card = played['card'];
                      return Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black45),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${card['value']}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            _getSuitIcon(card['suit'], size: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // کارت‌های دست بازیکن (پایین صفحه)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: game.myCards.length,
                      itemBuilder: (context, index) {
                        final card = game.myCards[index];
                        return GestureDetector(
                          onTap: () {
                            if (game.isMyTurn) {
                              game.playCard(card['id']);
                            }
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: game.isMyTurn ? Colors.amber : Colors.grey,
                                width: game.isMyTurn ? 2 : 1,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${card['value']}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _getSuitIcon(card['suit']),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

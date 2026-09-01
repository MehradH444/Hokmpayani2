import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  /// دریافت لیست آیتم‌های فروشگاه از سرور
  Future<void> _loadShopItems() async {
    try {
      final response = await ApiService.getShopItems();
      if (response['success'] == true) {
        setState(() {
          _items = response['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// خرید آیتم و به‌روزرسانی کیف پول
  Future<void> _buyItem(String itemId) async {
    final response = await ApiService.buyShopItem(itemId);
    if (!mounted) return;

    if (response['success'] == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.updateWallet(response['wallet']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خرید با موفقیت انجام شد!', textAlign: TextAlign.center),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'موجودی کافی نیست', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه حکم مستر', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF020617),
        iconTheme: const IconThemeData(color: Colors.amber),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${user?['wallet']?['coins'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 4),
                Text('${user?['wallet']?['gems'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          item['type'] == 'coins'
                              ? Icons.monetization_on
                              : item['type'] == 'gems'
                                  ? Icons.diamond
                                  : Icons.style,
                          size: 40,
                          color: Colors.amber,
                        ),
                        Text(
                          item['name'] ?? 'آیتم ویژه',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'قیمت: ${item['price']} ${item['currency'] == 'gems' ? 'الماس' : 'تومان'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            minimumSize: const Size(double.infinity, 30),
                          ),
                          onPressed: () => _buyItem(item['_id']),
                          child: const Text('خرید', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

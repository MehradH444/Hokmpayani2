import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ClanScreen extends StatefulWidget {
  const ClanScreen({super.key});

  @override
  State<ClanScreen> createState() => _ClanScreenState();
}

class _ClanScreenState extends State<ClanScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// ایجاد کلن جدید
  Future<void> _createClan() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً نام و توضیحات کلن را وارد کنید', textAlign: TextAlign.center),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.createClan(name, description, 'shield_gold');
      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کلن با موفقیت ساخته شد!', textAlign: TextAlign.center),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'خطا در ساخت کلن', textAlign: TextAlign.center),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در ارتباط با سرور', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// دیالوگ ساخت کلن
  void _showCreateClanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ایجاد کلن جدید', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام کلن',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات کلن',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: _isLoading ? null : _createClan,
            child: const Text('ساخت کلن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final hasClan = user != null && user['clan'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتحادها (کلن‌ها)', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF020617),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // وضعیت عضویت در کلن
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF020617).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.cyanAccent, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasClan ? 'کلن شما: ${user['clan']['name'] ?? ''}' : 'شما در هیچ کلنی عضو نیستید',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasClan ? 'نقش: ${user['clanRole'] ?? 'عضو'}' : 'برای دریافت پاداش تیمی به یک کلن بپیوندید',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!hasClan)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                      onPressed: _showCreateClanDialog,
                      child: const Text('ایجاد کلن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // عنوان لیست کلن‌ها
            const Alignment(
              alignment: Alignment.centerRight,
              child: Text(
                'برترین کلن‌های این هفته',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 10),

            // لیست نمونه کلن‌های برتر
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                        child: Text('#${index + 1}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      ),
                      title: Text('کلن قهرمانان ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('تعداد اعضا: ${(index + 1) * 7}/50  |  امتیاز کل: ${(5 - index) * 1200}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                        onPressed: hasClan
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('درخواست عضویت ارسال شد')),
                                );
                              },
                        child: const Text('عضویت', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

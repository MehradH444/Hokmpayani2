import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  /// بررسی ورود قبلی کاربر هنگام اجرای اپلیکیشن (Splash Screen)
  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _setLoading(false);
        return false;
      }

      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        _user = response['user'];
        await SocketService.connect(); // برقراری اتصال سوکت پس از تایید هویت
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        await ApiService.removeToken();
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  /// ثبت‌نام کاربر جدید
  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.register(username, password);
      if (response['success'] == true) {
        await ApiService.saveToken(response['token']);
        _user = response['user'];
        await SocketService.connect();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'خطا در ثبت‌نام';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'ارتباط با سرور برقرار نشد';
      _setLoading(false);
      return false;
    }
  }

  /// ورود کاربر با نام کاربری و کلمه عبور
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.login(username, password);
      if (response['success'] == true) {
        await ApiService.saveToken(response['token']);
        _user = response['user'];
        await SocketService.connect();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'اطلاعات ورود نادرست است';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'ارتباط با سرور برقرار نشد';
      _setLoading(false);
      return false;
    }
  }

  /// ورود سریع به عنوان مهمان (Guest Login)
  Future<bool> loginAsGuest() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await ApiService.loginAsGuest();
      if (response['success'] == true) {
        await ApiService.saveToken(response['token']);
        _user = response['user'];
        await SocketService.connect();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'خطا در ورود مهمان';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'ارتباط با سرور برقرار نشد';
      _setLoading(false);
      return false;
    }
  }

  /// به‌روزرسانی کیف پول کاربر در حافظه فرانت‌اند پس از خرید یا دریافت پاداش
  void updateWallet(Map<String, dynamic> newWallet) {
    if (_user != null) {
      _user!['wallet'] = newWallet;
      notifyListeners();
    }
  }

  /// خروج از حساب کاربری (Logout)
  Future<void> logout() async {
    await ApiService.removeToken();
    SocketService.disconnect();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

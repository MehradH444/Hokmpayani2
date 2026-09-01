import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class GameProvider with ChangeNotifier {
  Map<String, dynamic>? _roomData;
  List<dynamic> _myCards = [];
  List<dynamic> _currentTrick = [];
  String? _hokmSuit;
  int _hakemIndex = 0;
  int _currentTurnIndex = 0;
  int _mySeatIndex = -1;
  Map<String, dynamic> _teamScore = {'team1': 0, 'team2': 0};
  Map<String, dynamic> _matchScore = {'team1': 0, 'team2': 0};
  List<Map<String, dynamic>> _tableMessages = [];

  // Getters
  Map<String, dynamic>? get roomData => _roomData;
  List<dynamic> get myCards => _myCards;
  List<dynamic> get currentTrick => _currentTrick;
  String? get hokmSuit => _hokmSuit;
  int get hakemIndex => _hakemIndex;
  int get currentTurnIndex => _currentTurnIndex;
  int get mySeatIndex => _mySeatIndex;
  bool get isMyTurn => _currentTurnIndex == _mySeatIndex;
  bool get amIHakem => _hakemIndex == _mySeatIndex;
  Map<String, dynamic> get teamScore => _teamScore;
  Map<String, dynamic> get matchScore => _matchScore;
  List<Map<String, dynamic>> get tableMessages => _tableMessages;

  /// مقداردهی شنونده‌های سوکت (Socket Listeners) برای به‌روزرسانی زنده وضعیت میز
  void listenToSocketEvents(String userId) {
    // بروزرسانی وضعیت کلی اتاق
    SocketService.onRoomUpdated((data) {
      _roomData = data['room'];
      if (_roomData != null && _roomData!['players'] != null) {
        final players = _roomData!['players'] as List;
        _mySeatIndex = players.indexWhere((p) => p != null && p['id'] == userId);
      }
      notifyListeners();
    });

    // شروع دست جدید
    SocketService.onGameStarted((data) {
      _hakemIndex = data['hakemIndex'] ?? 0;
      _currentTrick.clear();
      _hokmSuit = null;
      notifyListeners();
    });

    // دریافت کارت‌های دست بازیکن
    SocketService.onReceiveCards((data) {
      _myCards = List.from(data['cards'] ?? []);
      notifyListeners();
    });

    // تعیین خال حکم
    SocketService.onHokmSelected((data) {
      _hokmSuit = data['hokmSuit'];
      _currentTurnIndex = data['currentTurnIndex'] ?? _hakemIndex;
      notifyListeners();
    });

    // انداخته شدن کارت روی میز توسط یکی از بازیکنان
    SocketService.onCardPlayed((data) {
      final seatIndex = data['seatIndex'];
      final card = data['card'];
      _currentTurnIndex = data['nextTurnIndex'];

      // اگر کارت خودم بوده، آن را از لیست دست من حذف کن
      if (seatIndex == _mySeatIndex) {
        _myCards.removeWhere((c) => c['id'] == card['id']);
      }

      _currentTrick.add({'seatIndex': seatIndex, 'card': card});
      notifyListeners();
    });

    // تعیین برنده دست ۴تایی
    SocketService.onTrickResolved((data) {
      _teamScore = Map<String, dynamic>.from(data['teamScore']);
      _matchScore = Map<String, dynamic>.from(data['matchScore']);
      _currentTurnIndex = data['nextTurnIndex'];
      _currentTrick.clear();
      notifyListeners();
    });

    // پایان راند (رسیدن به ۷ دست)
    SocketService.onHandEnded((data) {
      _matchScore = Map<String, dynamic>.from(data['matchScore']);
      _currentTrick.clear();
      notifyListeners();
    });

    // دریافت چت یا استیکر جدید
    SocketService.onNewTableChat((data) {
      _tableMessages.add(Map<String, dynamic>.from(data));
      notifyListeners();
    });
  }

  /// ارسال درخواست بازی کردن کارت به سرور
  void playCard(String cardId) {
    SocketService.playCard(cardId);
  }

  /// ارسال درخواست انتخاب حکم به سرور
  void selectHokm(String suit) {
    SocketService.selectHokm(suit);
  }

  /// ارسال چت متنی یا استیکر
  void sendChat(String messageType, String content, {String? stickerId}) {
    SocketService.sendTableChat(messageType, content, stickerId: stickerId);
  }

  /// پاکسازی استیت در زمان خروج از میز
  void resetGame() {
    _roomData = null;
    _myCards.clear();
    _currentTrick.clear();
    _hokmSuit = null;
    _tableMessages.clear();
  }
}

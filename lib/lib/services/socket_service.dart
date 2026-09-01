import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;

  // اتصال به سرور سوکت با استفاده از توکن امنیتی JWT
  static Future<void> connect() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    // آدرس سرور سوکت (در صورت استفاده از موبایل واقعی IP سیستم خود را بزنید)
    _socket = IO.io(
      'http://10.0.2.2:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[Socket] Connected successfully');
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected');
    });

    _socket!.onError((data) {
      print('[Socket Error] $data');
    });
  }

  // پیوستن به میز بازی
  static void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  // تعیین خال حکم توسط حاکم
  static void selectHokm(String hokmSuit) {
    _socket?.emit('select_hokm', {'hokmSuit': hokmSuit});
  }

  // انداختن کارت روی میز
  static void playCard(String cardId) {
    _socket?.emit('play_card', {'cardId': cardId});
  }

  // ارسال پیام یا استیکر روی میز
  static void sendTableChat(String messageType, String content, {String? stickerId}) {
    _socket?.emit('send_table_chat', {
      'messageType': messageType,
      'content': content,
      'stickerId': stickerId,
    });
  }

  // شنیدن رویداد به‌روزرسانی اطلاعات میز
  static void onRoomUpdated(Function(dynamic) callback) {
    _socket?.on('room_updated', callback);
  }

  // شنیدن رویداد شروع بازی و پخش کارت‌ها
  static void onGameStarted(Function(dynamic) callback) {
    _socket?.on('game_started', callback);
  }

  // شنیدن دریافت کارت‌های دست بازیکن
  static void onReceiveCards(Function(dynamic) callback) {
    _socket?.on('receive_cards', callback);
  }

  // شنیدن انتخاب حکم
  static void onHokmSelected(Function(dynamic) callback) {
    _socket?.on('hokm_selected', callback);
  }

  // شنیدن بازی شدن کارت توسط سایر بازیکنان
  static void onCardPlayed(Function(dynamic) callback) {
    _socket?.on('card_played', callback);
  }

  // شنیدن نتیجه برنده هر دست ۴ تایی
  static void onTrickResolved(Function(dynamic) callback) {
    _socket?.on('trick_resolved', callback);
  }

  // شنیدن نتیجه پایان راند (رسیدن به ۷ دست)
  static void onHandEnded(Function(dynamic) callback) {
    _socket?.on('hand_ended', callback);
  }

  // شنیدن چت یا استیکر جدید
  static void onNewTableChat(Function(dynamic) callback) {
    _socket?.on('new_table_chat', callback);
  }

  // قطع اتصال از سوکت
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

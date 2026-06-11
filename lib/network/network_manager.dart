import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'message.dart';

const int kGamePort = 45678;

class NetworkManager extends ChangeNotifier {
  ServerSocket? _server;
  Socket? _hostSocket;
  final Map<String, Socket> _clientSockets = {};
  final StreamController<GameMessage> _messageController =
      StreamController.broadcast();

  bool _isHost = false;
  bool _isConnected = false;
  String? _localPlayerId;

  bool get isHost => _isHost;
  bool get isConnected => _isConnected;
  String? get localPlayerId => _localPlayerId;
  Stream<GameMessage> get messageStream => _messageController.stream;

  Future<String?> startHost(String playerId) async {
    _isHost = true;
    _localPlayerId = playerId;
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, kGamePort);
      _server!.listen(_handleNewClient);
      final ip = await _getLocalIp();
      _isConnected = true;
      notifyListeners();
      return ip;
    } catch (e) {
      debugPrint('خطا در راه‌اندازی سرور: $e');
      return null;
    }
  }

  void _handleNewClient(Socket socket) {
    final clientId = '${socket.remoteAddress.address}:${socket.remotePort}';
    _clientSockets[clientId] = socket;
    socket.transform(utf8.decoder).listen(
      (data) => _handleRawData(data),
      onDone: () {
        _clientSockets.remove(clientId);
        notifyListeners();
      },
      onError: (e) => debugPrint('خطای کلاینت: $e'),
    );
  }

  Future<bool> connectToHost(String hostIp, String playerId) async {
    _isHost = false;
    _localPlayerId = playerId;
    try {
      _hostSocket = await Socket.connect(hostIp, kGamePort,
          timeout: const Duration(seconds: 10));
      _hostSocket!.transform(utf8.decoder).listen(
        (data) => _handleRawData(data),
        onDone: _onDisconnected,
        onError: (e) => debugPrint('خطای اتصال: $e'),
      );
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('خطا در اتصال: $e');
      return false;
    }
  }

  void sendMessage(GameMessage message) {
    final data = message.toJsonString() + '\n';
    final bytes = utf8.encode(data);
    if (_isHost) {
      for (final socket in _clientSockets.values) {
        try { socket.add(bytes); } catch (e) { debugPrint('خطا در ارسال: $e'); }
      }
    } else {
      try { _hostSocket?.add(bytes); } catch (e) { debugPrint('خطا در ارسال: $e'); }
    }
  }

  String _buffer = '';
  void _handleRawData(String data) {
    _buffer += data;
    final lines = _buffer.split('\n');
    _buffer = lines.last;
    for (final line in lines.sublist(0, lines.length - 1)) {
      if (line.trim().isEmpty) continue;
      try {
        final message = GameMessage.fromJsonString(line.trim());
        _messageController.add(message);
      } catch (e) {
        debugPrint('خطا در پارس پیام: $e');
      }
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    notifyListeners();
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<String> getLocalIp() => _getLocalIp();
  int get connectedClientsCount => _clientSockets.length;

  Future<void> disconnect() async {
    await _server?.close();
    await _hostSocket?.close();
    for (final s in _clientSockets.values) { await s.close(); }
    _clientSockets.clear();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}

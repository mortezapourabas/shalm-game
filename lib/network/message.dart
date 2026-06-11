import 'dart:convert';
import '../models/card.dart';
import '../models/game_state.dart';

enum MessageType {
  playerJoined,
  playerLeft,
  startGame,
  placeBid,
  declareShalm,
  playCard,
  gameStateSync,
  chatMessage,
  ping,
  pong,
}

class GameMessage {
  final MessageType type;
  final String senderId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  GameMessage({
    required this.type,
    required this.senderId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GameMessage.playerJoined(String playerId, String name) =>
      GameMessage(type: MessageType.playerJoined, senderId: playerId, data: {'name': name});

  factory GameMessage.startGame(String hostId) =>
      GameMessage(type: MessageType.startGame, senderId: hostId, data: {});

  factory GameMessage.placeBid(String playerId, int bid) =>
      GameMessage(type: MessageType.placeBid, senderId: playerId, data: {'bid': bid});

  factory GameMessage.declareShalm(String playerId) =>
      GameMessage(type: MessageType.declareShalm, senderId: playerId, data: {});

  factory GameMessage.playCard(String playerId, PlayingCard card) =>
      GameMessage(type: MessageType.playCard, senderId: playerId, data: {'card': card.toJson()});

  factory GameMessage.syncState(String senderId, GameState state) =>
      GameMessage(type: MessageType.gameStateSync, senderId: senderId, data: {'state': state.toJson()});

  factory GameMessage.chat(String playerId, String text) =>
      GameMessage(type: MessageType.chatMessage, senderId: playerId, data: {'text': text});

  factory GameMessage.ping(String senderId) =>
      GameMessage(type: MessageType.ping, senderId: senderId, data: {});

  factory GameMessage.pong(String senderId) =>
      GameMessage(type: MessageType.pong, senderId: senderId, data: {});

  String toJsonString() => jsonEncode({
    'type': type.index,
    'senderId': senderId,
    'data': data,
    'timestamp': timestamp.millisecondsSinceEpoch,
  });

  factory GameMessage.fromJsonString(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return GameMessage(
      type: MessageType.values[json['type']],
      senderId: json['senderId'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

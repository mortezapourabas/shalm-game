import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import '../game_logic/shalm_logic.dart';
import '../network/network_manager.dart';
import '../network/message.dart';

class GameController extends ChangeNotifier {
  final NetworkManager network;
  GameState _state = GameState();
  String? _myPlayerId;
  StreamSubscription? _messageSub;
  String? _lastError;

  GameController({required this.network}) {
    _messageSub = network.messageStream.listen(_handleMessage);
  }

  GameState get state => _state;
  String? get myPlayerId => _myPlayerId;
  String? get lastError => _lastError;

  Player? get myPlayer =>
      _myPlayerId == null ? null :
      _state.players.firstWhere((p) => p.id == _myPlayerId,
          orElse: () => Player(id: '', name: ''));

  bool get isMyTurn =>
      _state.currentPlayer?.id == _myPlayerId &&
      _state.phase == GamePhase.playing;

  Future<String?> hostGame(String playerName) async {
    _myPlayerId = 'player_host';
    final ip = await network.startHost(_myPlayerId!);
    if (ip == null) return null;
    final me = Player(id: _myPlayerId!, name: playerName, isHost: true);
    _state.players.add(me);
    notifyListeners();
    return ip;
  }

  Future<bool> joinGame(String hostIp, String playerName) async {
    _myPlayerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    final ok = await network.connectToHost(hostIp, _myPlayerId!);
    if (!ok) return false;
    network.sendMessage(GameMessage.playerJoined(_myPlayerId!, playerName));
    return true;
  }

  void startGame() {
    if (!network.isHost) return;
    if (_state.players.length != 4) {
      _lastError = 'برای شروع بازی ۴ نفر لازم است';
      notifyListeners();
      return;
    }
    ShalmGameLogic.shuffleAndDeal(_state);
    _state.phase = GamePhase.bidding;
    _state.currentPlayerIndex = (_state.dealerIndex + 1) % 4;
    for (final p in _state.players) { p.status = PlayerStatus.bidding; }
    network.sendMessage(GameMessage.syncState(_myPlayerId!, _state));
    notifyListeners();
  }

  void placeBid(int bid) {
    if (_state.phase != GamePhase.bidding) return;
    if (_state.currentPlayer?.id != _myPlayerId) return;
    final existingBids = _state.players
        .where((p) => p.bid > 0 || p.status == PlayerStatus.playing)
        .map((p) => p.bid)
        .toList();
    if (!ShalmGameLogic.isValidBid(bid, existingBids)) {
      _lastError = 'این شیر معتبر نیست';
      notifyListeners();
      return;
    }
    network.sendMessage(GameMessage.placeBid(_myPlayerId!, bid));
    _applyBid(_myPlayerId!, bid);
  }

  void declareShalm() {
    if (_state.phase != GamePhase.bidding) return;
    if (_state.currentPlayer?.id != _myPlayerId) return;
    network.sendMessage(GameMessage.declareShalm(_myPlayerId!));
    _applyDeclareShalm(_myPlayerId!);
  }

  void playCard(PlayingCard card) {
    if (!isMyTurn) return;
    final error = ShalmGameLogic.playCard(_state, _myPlayerId!, card);
    if (error != null) {
      _lastError = error;
      notifyListeners();
      return;
    }
    network.sendMessage(GameMessage.playCard(_myPlayerId!, card));
    if (network.isHost) {
      network.sendMessage(GameMessage.syncState(_myPlayerId!, _state));
    }
    notifyListeners();
  }

  void startNewRound() {
    if (!network.isHost) return;
    ShalmGameLogic.startNewRound(_state);
    network.sendMessage(GameMessage.syncState(_myPlayerId!, _state));
    notifyListeners();
  }

  void _handleMessage(GameMessage msg) {
    switch (msg.type) {
      case MessageType.playerJoined:
        _handlePlayerJoined(msg);
        break;
      case MessageType.placeBid:
        _applyBid(msg.senderId, msg.data['bid']);
        break;
      case MessageType.declareShalm:
        _applyDeclareShalm(msg.senderId);
        break;
      case MessageType.playCard:
        if (!network.isHost) break;
        final card = PlayingCard.fromJson(msg.data['card']);
        ShalmGameLogic.playCard(_state, msg.senderId, card);
        network.sendMessage(GameMessage.syncState(_myPlayerId!, _state));
        notifyListeners();
        break;
      case MessageType.gameStateSync:
        _state = GameState.fromJson(msg.data['state']);
        notifyListeners();
        break;
      default:
        break;
    }
  }

  void _handlePlayerJoined(GameMessage msg) {
    if (!network.isHost) return;
    if (_state.players.length >= 4) return;
    final newPlayer = Player(id: msg.senderId, name: msg.data['name']);
    _state.players.add(newPlayer);
    network.sendMessage(GameMessage.syncState(_myPlayerId!, _state));
    notifyListeners();
  }

  void _applyBid(String playerId, int bid) {
    final player = _state.players.firstWhere((p) => p.id == playerId,
        orElse: () => Player(id: '', name: ''));
    if (player.id.isEmpty) return;
    player.bid = bid;
    player.status = PlayerStatus.playing;
    _advanceBiddingTurn();
    notifyListeners();
  }

  void _applyDeclareShalm(String playerId) {
    _state.hasShalm = true;
    _state.shalm = playerId;
    _state.phase = GamePhase.playing;
    _state.currentPlayerIndex = _state.players.indexWhere((p) => p.id == playerId);
    notifyListeners();
  }

  void _advanceBiddingTurn() {
    final allBid = _state.players.every((p) => p.status == PlayerStatus.playing);
    if (allBid) {
      _state.phase = GamePhase.playing;
      _state.currentPlayerIndex = (_state.dealerIndex + 1) % 4;
    } else {
      _state.currentPlayerIndex = (_state.currentPlayerIndex + 1) % 4;
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }
}

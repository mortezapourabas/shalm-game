import 'card.dart';
import 'player.dart';

enum GamePhase { lobby, bidding, playing, roundEnd, gameEnd }
enum TrumpSuit { spade, heart, diamond, club, noTrump }

class Trick {
  final List<MapEntry<String, PlayingCard>> plays;
  String? winnerId;

  Trick() : plays = [];

  void addPlay(String playerId, PlayingCard card) {
    plays.add(MapEntry(playerId, card));
  }

  PlayingCard? get leadCard => plays.isEmpty ? null : plays.first.value;
  Suit? get leadSuit => leadCard?.suit;
  bool get isComplete => plays.length == 4;

  Map<String, dynamic> toJson() => {
    'plays': plays.map((e) => {'pid': e.key, 'card': e.value.toJson()}).toList(),
    'winnerId': winnerId,
  };

  factory Trick.fromJson(Map<String, dynamic> json) {
    final t = Trick();
    for (var p in (json['plays'] as List)) {
      t.plays.add(MapEntry(p['pid'], PlayingCard.fromJson(p['card'])));
    }
    t.winnerId = json['winnerId'];
    return t;
  }
}

class GameState {
  List<Player> players;
  GamePhase phase;
  TrumpSuit trumpSuit;
  int currentPlayerIndex;
  int dealerIndex;
  List<Trick> tricks;
  Trick? currentTrick;
  int roundNumber;
  String? shalm;
  bool hasShalm;

  GameState({
    this.players = const [],
    this.phase = GamePhase.lobby,
    this.trumpSuit = TrumpSuit.noTrump,
    this.currentPlayerIndex = 0,
    this.dealerIndex = 0,
    this.tricks = const [],
    this.currentTrick,
    this.roundNumber = 1,
    this.shalm,
    this.hasShalm = false,
  }) {
    players = [];
    tricks = [];
  }

  Player? get currentPlayer =>
      players.isEmpty ? null : players[currentPlayerIndex % players.length];

  Player? get dealer =>
      players.isEmpty ? null : players[dealerIndex % players.length];

  int get totalTricksPlayed => tricks.length;
  int get tricksPerRound => 13;
  bool get isRoundComplete => totalTricksPlayed >= tricksPerRound;

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'phase': phase.index,
    'trumpSuit': trumpSuit.index,
    'currentPlayerIndex': currentPlayerIndex,
    'dealerIndex': dealerIndex,
    'tricks': tricks.map((t) => t.toJson()).toList(),
    'currentTrick': currentTrick?.toJson(),
    'roundNumber': roundNumber,
    'shalm': shalm,
    'hasShalm': hasShalm,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final gs = GameState(
      phase: GamePhase.values[json['phase'] ?? 0],
      trumpSuit: TrumpSuit.values[json['trumpSuit'] ?? 4],
      currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
      dealerIndex: json['dealerIndex'] ?? 0,
      roundNumber: json['roundNumber'] ?? 1,
      shalm: json['shalm'],
      hasShalm: json['hasShalm'] ?? false,
    );
    gs.players = (json['players'] as List).map((p) => Player.fromJson(p)).toList();
    gs.tricks = (json['tricks'] as List).map((t) => Trick.fromJson(t)).toList();
    if (json['currentTrick'] != null) {
      gs.currentTrick = Trick.fromJson(json['currentTrick']);
    }
    return gs;
  }
}

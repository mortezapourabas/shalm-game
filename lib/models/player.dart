import 'card.dart';

enum PlayerStatus { waiting, bidding, playing, done }

class Player {
  final String id;
  String name;
  List<PlayingCard> hand;
  List<PlayingCard> wonCards;
  int bid;
  int tricksWon;
  int totalScore;
  bool isHost;
  PlayerStatus status;

  Player({
    required this.id,
    required this.name,
    this.hand = const [],
    this.wonCards = const [],
    this.bid = 0,
    this.tricksWon = 0,
    this.totalScore = 0,
    this.isHost = false,
    this.status = PlayerStatus.waiting,
  }) {
    hand = [];
    wonCards = [];
  }

  int get wonPoints => wonCards.fold(0, (sum, c) => sum + c.point);

  bool get madeBid => tricksWon >= bid;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bid': bid,
    'tricksWon': tricksWon,
    'totalScore': totalScore,
    'isHost': isHost,
    'status': status.index,
    'hand': hand.map((c) => c.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    final p = Player(
      id: json['id'],
      name: json['name'],
      bid: json['bid'] ?? 0,
      tricksWon: json['tricksWon'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
      isHost: json['isHost'] ?? false,
      status: PlayerStatus.values[json['status'] ?? 0],
    );
    if (json['hand'] != null) {
      p.hand = (json['hand'] as List).map((c) => PlayingCard.fromJson(c)).toList();
    }
    return p;
  }
}

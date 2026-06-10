enum Suit { spade, heart, diamond, club }
enum Rank {
  two, three, four, five, six, seven, eight, nine, ten,
  jack, queen, king, ace
}

class PlayingCard {
  final Suit suit;
  final Rank rank;
  bool isSelected;

  PlayingCard({required this.suit, required this.rank, this.isSelected = false});

  int get point {
    switch (rank) {
      case Rank.ace:   return 11;
      case Rank.ten:   return 10;
      case Rank.king:  return 4;
      case Rank.queen: return 3;
      case Rank.jack:  return 2;
      default:         return 0;
    }
  }

  bool get isAceOfSpades => suit == Suit.spade && rank == Rank.ace;

  String get suitSymbol {
    switch (suit) {
      case Suit.spade:   return '♠';
      case Suit.heart:   return '♥';
      case Suit.diamond: return '♦';
      case Suit.club:    return '♣';
    }
  }

  String get rankLabel {
    switch (rank) {
      case Rank.ace:   return 'A';
      case Rank.king:  return 'K';
      case Rank.queen: return 'Q';
      case Rank.jack:  return 'J';
      case Rank.ten:   return '10';
      case Rank.nine:  return '9';
      case Rank.eight: return '8';
      case Rank.seven: return '7';
      case Rank.six:   return '6';
      case Rank.five:  return '5';
      case Rank.four:  return '4';
      case Rank.three: return '3';
      case Rank.two:   return '2';
    }
  }

  String get id => '${suit.name}_${rank.name}';

  Map<String, dynamic> toJson() => {'suit': suit.index, 'rank': rank.index};

  factory PlayingCard.fromJson(Map<String, dynamic> json) =>
      PlayingCard(suit: Suit.values[json['suit']], rank: Rank.values[json['rank']]);

  @override
  String toString() => '$rankLabel$suitSymbol';
}

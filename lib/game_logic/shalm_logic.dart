import 'dart:math';
import '../models/card.dart';
import '../models/player.dart';
import '../models/game_state.dart';

class ShalmGameLogic {
  static List<PlayingCard> createDeck() {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        deck.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }

  static void shuffleAndDeal(GameState state) {
    final deck = createDeck();
    deck.shuffle(Random());
    for (int i = 0; i < state.players.length; i++) {
      state.players[i].hand = deck.sublist(i * 13, (i + 1) * 13);
      state.players[i].hand.sort(_compareCards);
    }
  }

  static bool isValidBid(int bid, List<int> existingBids) {
    if (bid < 0 || bid > 13) return false;
    if (existingBids.length == 3) {
      final total = existingBids.fold(0, (a, b) => a + b) + bid;
      return total != 13;
    }
    return true;
  }

  static bool canDeclareShalm(Player player) {
    return player.hand.length == 13;
  }

  static List<PlayingCard> getPlayableCards(
    Player player,
    Trick? currentTrick,
    TrumpSuit trumpSuit,
  ) {
    if (currentTrick == null || currentTrick.plays.isEmpty) {
      return List.from(player.hand);
    }
    final leadSuit = currentTrick.leadSuit;
    final sameSuit = player.hand.where((c) => c.suit == leadSuit).toList();
    if (sameSuit.isNotEmpty) return sameSuit;
    return List.from(player.hand);
  }

  static String determineTrickWinner(Trick trick, TrumpSuit trumpSuit) {
    final leadSuit = trick.leadSuit!;
    String winnerId = trick.plays.first.key;
    PlayingCard winningCard = trick.plays.first.value;
    for (final play in trick.plays.skip(1)) {
      if (_beats(play.value, winningCard, leadSuit, trumpSuit)) {
        winningCard = play.value;
        winnerId = play.key;
      }
    }
    return winnerId;
  }

  static bool _beats(
    PlayingCard challenger,
    PlayingCard current,
    Suit leadSuit,
    TrumpSuit trumpSuit,
  ) {
    final trumpSuitEnum = _toSuit(trumpSuit);
    final challengerIsTrump = trumpSuitEnum != null && challenger.suit == trumpSuitEnum;
    final currentIsTrump = trumpSuitEnum != null && current.suit == trumpSuitEnum;
    if (challengerIsTrump && !currentIsTrump) return true;
    if (!challengerIsTrump && currentIsTrump) return false;
    if (challenger.suit == current.suit) {
      return challenger.rank.index > current.rank.index;
    }
    if (challenger.suit != leadSuit) return false;
    return challenger.rank.index > current.rank.index;
  }

  static Suit? _toSuit(TrumpSuit ts) {
    switch (ts) {
      case TrumpSuit.spade:   return Suit.spade;
      case TrumpSuit.heart:   return Suit.heart;
      case TrumpSuit.diamond: return Suit.diamond;
      case TrumpSuit.club:    return Suit.club;
      case TrumpSuit.noTrump: return null;
    }
  }

  static Map<String, int> calculateRoundScore(
    List<Player> players,
    bool hasShalm,
    String? shalmPlayerId,
  ) {
    final scores = <String, int>{};
    for (final player in players) {
      if (hasShalm && player.id == shalmPlayerId) {
        scores[player.id] = player.tricksWon == 13 ? 100 : -100;
      } else {
        if (player.madeBid) {
          final bonus = (player.tricksWon - player.bid);
          scores[player.id] = (player.bid * 10) + bonus;
        } else {
          final diff = player.bid - player.tricksWon;
          scores[player.id] = -(diff * 10);
        }
      }
    }
    return scores;
  }

  static int _compareCards(PlayingCard a, PlayingCard b) {
    if (a.suit.index != b.suit.index) return a.suit.index - b.suit.index;
    return a.rank.index - b.rank.index;
  }

  static String? playCard(
    GameState state,
    String playerId,
    PlayingCard card,
  ) {
    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return 'بازیکن پیدا نشد';
    if (playerIndex != state.currentPlayerIndex) return 'نوبت شما نیست';
    final player = state.players[playerIndex];
    final playable = getPlayableCards(player, state.currentTrick, state.trumpSuit);
    if (!playable.any((c) => c.id == card.id)) return 'این کارت قابل بازی نیست';
    player.hand.removeWhere((c) => c.id == card.id);
    state.currentTrick ??= Trick();
    state.currentTrick!.addPlay(playerId, card);
    if (state.currentTrick!.isComplete) {
      final winnerId = determineTrickWinner(state.currentTrick!, state.trumpSuit);
      state.currentTrick!.winnerId = winnerId;
      state.tricks.add(state.currentTrick!);
      final winner = state.players.firstWhere((p) => p.id == winnerId);
      winner.tricksWon++;
      winner.wonCards.addAll(state.currentTrick!.plays.map((e) => e.value));
      state.currentTrick = null;
      state.currentPlayerIndex = state.players.indexWhere((p) => p.id == winnerId);
      if (state.isRoundComplete) {
        state.phase = GamePhase.roundEnd;
        _applyScores(state);
      }
    } else {
      state.currentPlayerIndex = (state.currentPlayerIndex + 1) % 4;
    }
    return null;
  }

  static void _applyScores(GameState state) {
    final roundScores = calculateRoundScore(
      state.players,
      state.hasShalm,
      state.shalm,
    );
    for (final player in state.players) {
      player.totalScore += roundScores[player.id] ?? 0;
    }
  }

  static void startNewRound(GameState state) {
    state.dealerIndex = (state.dealerIndex + 1) % 4;
    state.currentPlayerIndex = (state.dealerIndex + 1) % 4;
    state.tricks.clear();
    state.currentTrick = null;
    state.hasShalm = false;
    state.shalm = null;
    state.roundNumber++;
    for (final player in state.players) {
      player.hand.clear();
      player.wonCards.clear();
      player.bid = 0;
      player.tricksWon = 0;
      player.status = PlayerStatus.bidding;
    }
    shuffleAndDeal(state);
    state.phase = GamePhase.bidding;
  }

  static Player? checkGameEnd(GameState state) {
    for (final player in state.players) {
      if (player.totalScore >= 1000) return player;
    }
    return null;
  }
}

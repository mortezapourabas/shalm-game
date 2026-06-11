import 'package:flutter/material.dart';
import '../game_logic/game_controller.dart';
import '../models/game_state.dart';
import 'card_widget.dart';

class TrickArea extends StatelessWidget {
  final GameController controller;

  const TrickArea({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final trick = state.currentTrick;
    final lastTrick = state.tricks.isNotEmpty ? state.tricks.last : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTrumpInfo(state),
          const SizedBox(height: 8),
          if (trick != null && trick.plays.isNotEmpty)
            _buildCurrentTrick(trick, state)
          else if (lastTrick != null)
            _buildLastTrick(lastTrick, state)
          else
            const Text(
              'بازی شروع نشده',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          const SizedBox(height: 8),
          Text(
            'دست ${state.totalTricksPlayed + 1} از ${state.tricksPerRound}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTrumpInfo(GameState state) {
    final trumpNames = {
      TrumpSuit.spade: '♠ پیک',
      TrumpSuit.heart: '♥ دل',
      TrumpSuit.diamond: '♦ خشت',
      TrumpSuit.club: '♣ گشنیز',
      TrumpSuit.noTrump: 'بی‌حکم',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'حکم: ${trumpNames[state.trumpSuit]}',
        style: const TextStyle(color: Colors.amber, fontSize: 14),
      ),
    );
  }

  Widget _buildCurrentTrick(Trick trick, GameState state) {
    return Column(
      children: [
        const Text('دست جاری',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: trick.plays.map((play) {
            final player = state.players.firstWhere(
                (p) => p.id == play.key);
            return Column(
              children: [
                CardWidget(card: play.value, width: 55, height: 80),
                const SizedBox(height: 4),
                Text(player.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLastTrick(Trick trick, GameState state) {
    if (trick.winnerId == null) return const SizedBox.shrink();
    final winner = state.players.firstWhere((p) => p.id == trick.winnerId);
    return Text(
      '${winner.name} دست آخر را برد',
      style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
    );
  }
}

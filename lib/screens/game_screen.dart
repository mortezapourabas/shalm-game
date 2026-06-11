import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_logic/game_controller.dart';
import '../game_logic/shalm_logic.dart';
import '../models/game_state.dart';
import '../widgets/card_widget.dart';
import '../widgets/trick_area.dart';
import '../widgets/bidding_dialog.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B5E20),
        body: Consumer<GameController>(
          builder: (context, controller, _) {
            final state = controller.state;
            if (state.phase == GamePhase.bidding &&
                state.currentPlayer?.id == controller.myPlayerId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showBiddingDialog(context, controller);
              });
            }
            if (state.phase == GamePhase.roundEnd) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showRoundEndDialog(context, controller);
              });
            }
            return SafeArea(
              child: Column(
                children: [
                  _buildTopBar(controller),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildOpponentHands(controller),
                        const SizedBox(height: 8),
                        Expanded(child: TrickArea(controller: controller)),
                        const SizedBox(height: 8),
                        _buildMyHand(controller),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(GameController controller) {
    final state = controller.state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('دور ${state.roundNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            state.currentPlayer != null ? 'نوبت: ${state.currentPlayer!.name}' : '',
            style: const TextStyle(color: Colors.amber, fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.leaderboard, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildOpponentHands(GameController controller) {
    final state = controller.state;
    final opponents = state.players.where((p) => p.id != controller.myPlayerId).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((player) {
          final isCurrentTurn = state.currentPlayer?.id == player.id;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentTurn ? Colors.amber : Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${player.name} (${player.hand.length}🃏)',
                  style: TextStyle(
                    color: isCurrentTurn ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('شیر: ${player.bid} | برده: ${player.tricksWon}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyHand(GameController controller) {
    final myPlayer = controller.myPlayer;
    if (myPlayer == null) return const SizedBox.shrink();
    Set<String> playableIds = {};
    if (controller.isMyTurn && controller.state.phase == GamePhase.playing) {
      playableIds = ShalmGameLogic.getPlayableCards(
        myPlayer,
        controller.state.currentTrick,
        controller.state.trumpSuit,
      ).map((c) => c.id).toSet();
    }
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(myPlayer.name, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                'شیر: ${myPlayer.bid} | برده: ${myPlayer.tricksWon} | امتیاز: ${myPlayer.totalScore}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: myPlayer.hand.length,
              itemBuilder: (context, index) {
                final card = myPlayer.hand[index];
                final canPlay = playableIds.contains(card.id);
                return CardWidget(
                  card: card,
                  isPlayable: canPlay,
                  onTap: canPlay ? () => controller.playCard(card) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBiddingDialog(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BiddingDialog(controller: controller),
    );
  }

  void _showRoundEndDialog(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('پایان دور', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: controller.state.players.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.name),
                  Text('${p.totalScore} امتیاز',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
          ),
          actions: [
            if (controller.network.isHost)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.startNewRound();
                },
                child: const Text('دور بعد ▶'),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('منتظر هاست...', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}

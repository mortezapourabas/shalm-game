import 'package:flutter/material.dart';
import '../models/player.dart';

class ScoreBoard extends StatelessWidget {
  final List<Player> players;
  const ScoreBoard({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('جدول امتیازات', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...sorted.asMap().entries.map((e) {
              final rank = e.key + 1;
              final player = e.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: rank == 1 ? Colors.amber[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rank == 1 ? Colors.amber : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$rank. ${player.name}'),
                    Text(
                      '${player.totalScore} امتیاز',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}

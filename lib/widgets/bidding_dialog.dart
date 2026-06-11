import 'package:flutter/material.dart';
import '../game_logic/game_controller.dart';

class BiddingDialog extends StatefulWidget {
  final GameController controller;
  const BiddingDialog({super.key, required this.controller});

  @override
  State<BiddingDialog> createState() => _BiddingDialogState();
}

class _BiddingDialogState extends State<BiddingDialog> {
  int _selectedBid = 0;

  @override
  Widget build(BuildContext context) {
    final myPlayer = widget.controller.myPlayer;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(
          'اعلام شیر - ${myPlayer?.name ?? ""}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'چند دست می‌برید؟',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(14, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedBid = i),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedBid == i ? Colors.amber : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: _selectedBid == i ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.controller.declareShalm();
              },
              icon: const Text('🃏'),
              label: const Text('اعلام شلم! (برد همه ۱۳ دست)',
                  style: TextStyle(color: Colors.amber)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.controller.placeBid(_selectedBid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: Text('تأیید: $_selectedBid شیر',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

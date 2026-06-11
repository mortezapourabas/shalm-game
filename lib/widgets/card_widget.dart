import 'package:flutter/material.dart';
import '../models/card.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isPlayable;
  final bool faceDown;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.isPlayable = false,
    this.faceDown = false,
    this.onTap,
    this.width = 60,
    this.height = 90,
  });

  Color get _suitColor {
    switch (card.suit) {
      case Suit.heart:
      case Suit.diamond:
        return Colors.red[700]!;
      case Suit.spade:
      case Suit.club:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        transform: isPlayable
            ? (Matrix4.identity()..translate(0.0, -8.0))
            : Matrix4.identity(),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: faceDown ? Colors.blue[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPlayable ? Colors.amber : Colors.grey[300]!,
              width: isPlayable ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isPlayable ? 0.4 : 0.2),
                blurRadius: isPlayable ? 8 : 4,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: faceDown ? _buildCardBack() : _buildCardFront(),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              children: [
                Text(card.rankLabel,
                    style: TextStyle(color: _suitColor, fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text(card.suitSymbol,
                    style: TextStyle(color: _suitColor, fontSize: 12)),
              ],
            ),
          ),
          Text(card.suitSymbol,
              style: TextStyle(color: _suitColor, fontSize: 22)),
          Align(
            alignment: Alignment.bottomRight,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                children: [
                  Text(card.rankLabel,
                      style: TextStyle(color: _suitColor, fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(card.suitSymbol,
                      style: TextStyle(color: _suitColor, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Center(
      child: Icon(Icons.style, color: Colors.blue[200], size: 32),
    );
  }
}

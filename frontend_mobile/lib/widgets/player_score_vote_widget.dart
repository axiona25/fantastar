import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colore primario per voto normale.
const Color _kPrimaryVote = Color(0xFF0D47A1);
/// Grigio per 6 politico (partita rinviata).
const Color _kPostponedVote = Color(0xFF5C6B7A);

/// Mostra il voto/punteggio di un giocatore. Se [isPostponed] è true mostra
/// "6" in grigio con icona orologio e tooltip "Partita rinviata — 6 politico".
class PlayerScoreVoteWidget extends StatelessWidget {
  const PlayerScoreVoteWidget({
    super.key,
    required this.score,
    this.isPostponed = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
  });

  final double score;
  final bool isPostponed;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final displayScore = isPostponed ? 6.0 : score;
    final color = isPostponed ? _kPostponedVote : _kPrimaryVote;
    final text = displayScore == displayScore.truncateToDouble()
        ? displayScore.toInt().toString()
        : displayScore.toStringAsFixed(1);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        if (isPostponed) ...[
          const SizedBox(width: 4),
          Icon(Icons.schedule, size: fontSize * 0.875, color: _kPostponedVote),
        ],
      ],
    );

    if (isPostponed) {
      content = Tooltip(
        message: 'Partita rinviata — 6 politico',
        child: content,
      );
    }

    return content;
  }
}

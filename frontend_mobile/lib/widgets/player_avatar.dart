import 'package:flutter/material.dart';

import '../app/constants.dart';

/// Colori primari squadre Serie A (per sfondo avatar quando usato con teamColor).
const Map<String, Color> teamColors = {
  'Atalanta': Color(0xFF1E71B8),
  'Bologna': Color(0xFF1A2F48),
  'Cagliari': Color(0xFF6D2C35),
  'Como': Color(0xFF003DA5),
  'Empoli': Color(0xFF005BA1),
  'Fiorentina': Color(0xFF5B2D8E),
  'Genoa': Color(0xFF9E1B2F),
  'Inter': Color(0xFF0068A8),
  'Juventus': Color(0xFF000000),
  'Lazio': Color(0xFF87D8F7),
  'Lecce': Color(0xFFF5E130),
  'Milan': Color(0xFFE30613),
  'Monza': Color(0xFFCE2B37),
  'Napoli': Color(0xFF004A8F),
  'Parma': Color(0xFFFEE439),
  'Roma': Color(0xFF8E1F2F),
  'Torino': Color(0xFF7B1C2A),
  'Udinese': Color(0xFF000000),
  'Venezia': Color(0xFF004D28),
  'Verona': Color(0xFF1A3A6E),
  'Hellas Verona': Color(0xFF1A3A6E),
  'Frosinone': Color(0xFFF5A623),
  'Salernitana': Color(0xFF682B47),
};

Color getTeamColor(String? teamName) {
  if (teamName == null || teamName.isEmpty) return Colors.grey;
  final name = teamName.trim();
  if (teamColors.containsKey(name)) return teamColors[name]!;
  for (final e in teamColors.entries) {
    if (name.toLowerCase().contains(e.key.toLowerCase())) return e.value;
  }
  return Colors.grey;
}

/// Colore badge ruolo: P arancione, D verde, C blu, A rosso.
Color getRoleBadgeColor(String role) {
  switch (role.toUpperCase()) {
    case 'P':
    case 'POR':
      return const Color(0xFFFF8F00);
    case 'D':
    case 'DIF':
      return const Color(0xFF2E7D32);
    case 'C':
    case 'CEN':
      return const Color(0xFF1565C0);
    case 'A':
    case 'ATT':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF5C6B7A);
  }
}

/// Lettera ruolo per badge: POR->P, DIF->D, CEN->C, ATT->A.
String getRoleLetter(String role) {
  switch (role.toUpperCase()) {
    case 'POR':
      return 'P';
    case 'DIF':
      return 'D';
    case 'CEN':
      return 'C';
    case 'ATT':
      return 'A';
    default:
      return role.isNotEmpty ? role[0].toUpperCase() : '?';
  }
}

/// Avatar 3D Disney giocatore. URL sempre: kBackendOrigin/static/media/avatars/{playerId}.png
/// Usare ovunque nell'app si mostri un giocatore (listone, asta, rosa, dettaglio, etc.).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.playerId,
    required this.role,
    this.size = 52,
    this.showRoleBadge = true,
    this.playerName,
    this.teamColor,
  });

  final int playerId;
  final String role;
  final double size;
  final bool showRoleBadge;
  /// Nome per fallback iniziali se immagine non disponibile (opzionale).
  final String? playerName;
  /// Colore sfondo/gradiente (opzionale, altrimenti usa sfondo neutro).
  final Color? teamColor;

  @override
  Widget build(BuildContext context) {
    final badgeColor = getRoleBadgeColor(role);
    final letter = getRoleLetter(role);
    final bgColor = teamColor ?? const Color(0xFFE0E8F2);

    return SizedBox(
      width: size + (showRoleBadge ? 4 : 0),
      height: size + (showRoleBadge ? 4 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(
                color: badgeColor.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: playerId > 0
                  ? Image.network(
                      getPlayerAvatarUrl(playerId),
                      fit: BoxFit.cover,
                      cacheWidth: (size * 2).toInt(),
                      cacheHeight: (size * 2).toInt(),
                      errorBuilder: (_, __, ___) => _fallbackContent(badgeColor),
                    )
                  : _fallbackContent(badgeColor),
            ),
          ),
          if (showRoleBadge)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallbackContent(Color roleColor) {
    if (playerName != null && playerName!.trim().isNotEmpty) {
      final parts = playerName!.trim().split(RegExp(r'\s+'));
      final initial = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : playerName!.trim()[0].toUpperCase();
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            color: roleColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Icon(Icons.person, size: size * 0.5, color: roleColor);
  }
}

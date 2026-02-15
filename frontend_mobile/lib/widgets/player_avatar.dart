import 'package:flutter/material.dart';

import '../app/constants.dart';

/// Colori primari squadre Serie A (per sfondo avatar).
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

/// Restituisce il colore squadra per nome (case-insensitive match parziale).
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
Color _roleBadgeColor(String role) {
  switch (role.toUpperCase()) {
    case 'P':
    case 'POR':
      return Colors.orange;
    case 'D':
    case 'DIF':
      return Colors.green;
    case 'C':
    case 'CEN':
      return Colors.blue;
    case 'A':
    case 'ATT':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Lettera ruolo per badge: POR->P, DIF->D, CEN->C, ATT->A.
String _roleLetter(String role) {
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

/// Avatar giocatore in stile Fantacalcio: cerchio sfumato squadra + cutout/foto + badge ruolo.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    this.cutoutUrl,
    this.photoUrl,
    required this.playerName,
    required this.role,
    required this.teamColor,
    this.size = 56,
  });

  final String? cutoutUrl;
  final String? photoUrl;
  final String playerName;
  final String role;
  final Color teamColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolvePlayerPhotoUrl(cutoutUrl ?? photoUrl);
    final badgeColor = _roleBadgeColor(role);
    final letter = _roleLetter(role);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Cerchio sfondo con gradiente squadra
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  teamColor.withOpacity(0.3),
                  teamColor.withOpacity(0.7),
                ],
              ),
              border: Border.all(color: teamColor.withOpacity(0.5), width: 1.5),
            ),
          ),
          // 2. Foto cutout/photo sovrapposta (testa leggermente più grande del cerchio)
          Positioned(
            left: size * 0.05,
            right: size * 0.05,
            bottom: 0,
            child: SizedBox(
              width: size * 0.9,
              height: size * 0.95,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) => _initialsAvatar(context),
                    )
                  : _initialsAvatar(context),
            ),
          ),
          // 3. Badge ruolo in basso a sinistra
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(BuildContext context) {
    final initial = playerName.trim().isNotEmpty
        ? (playerName.trim().split(RegExp(r'\s+')).length >= 2
            ? '${playerName.trim().split(RegExp(r'\s+')).first[0]}${playerName.trim().split(RegExp(r'\s+')).last[0]}'.toUpperCase()
            : playerName.trim()[0].toUpperCase())
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

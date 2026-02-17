import 'package:flutter/material.dart';

import '../app/constants.dart';

/// Mappa loghi predefiniti per le leghe (icone Material).
const Map<String, IconData> leagueLogos = {
  'trophy': Icons.emoji_events,
  'star': Icons.star,
  'shield': Icons.shield,
  'football': Icons.sports_soccer,
  'crown': Icons.workspace_premium,
  'fire': Icons.local_fire_department,
  'bolt': Icons.bolt,
  'diamond': Icons.diamond,
};

/// Colore associato a ogni logo.
const Map<String, Color> leagueLogoColors = {
  'trophy': Colors.amber,
  'star': Colors.orange,
  'shield': Colors.blue,
  'football': Colors.green,
  'crown': Colors.purple,
  'fire': Colors.red,
  'bolt': Colors.yellow,
  'diamond': Colors.cyan,
};

/// Chiavi ordinate per la griglia di selezione (stesso ordine delle mappe).
const List<String> leagueLogoKeys = [
  'trophy', 'star', 'shield', 'football', 'crown', 'fire', 'bolt', 'diamond',
];

/// Widget riutilizzabile: cerchio con icona colorata per il logo della lega.
/// Usare ovunque si mostri il nome della lega (lista, dettaglio, header, classifica).
class LeagueLogo extends StatelessWidget {
  const LeagueLogo({
    super.key,
    required this.logoKey,
    this.size = 40,
  });

  final String logoKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Stemma da backend: path tipo /static/media/league_badges/3d/xxx.png oppure legacy badge_01
    final bool isNetworkBadge = logoKey.contains('league_badges') ||
        logoKey.startsWith('/static/') ||
        RegExp(r'^badge_\d{2}$').hasMatch(logoKey);
    if (isNetworkBadge) {
      String path = logoKey;
      if (logoKey.startsWith('http')) {
        path = logoKey;
      } else if (logoKey.startsWith('/static/') || logoKey.contains('league_badges')) {
        path = '$kBackendOrigin${logoKey.startsWith('/') ? logoKey : '/$logoKey'}';
      } else {
        path = '$kBackendOrigin/static/media/league_badges/3d/$logoKey.png';
      }
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon('trophy', size),
        ),
      );
    }

    final key = leagueLogos.containsKey(logoKey) ? logoKey : 'trophy';
    final iconData = leagueLogos[key]!;
    final color = leagueLogoColors[key] ?? Colors.amber;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(iconData, color: color, size: size * 0.6),
      ),
    );
  }

  Widget _buildFallbackIcon(String key, double size) {
    final iconData = leagueLogos[key] ?? Icons.emoji_events;
    final color = leagueLogoColors[key] ?? Colors.amber;
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Icon(iconData, color: color, size: size * 0.6),
      ),
    );
  }
}

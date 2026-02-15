import 'package:flutter/material.dart';

import '../models/player_list_item.dart';
import 'player_avatar.dart';

/// Riga listone: [Avatar 40x40] [Nome + Ruolo · Squadra · Prezzo] [trailing].
const double kPlayerListTilePhotoSize = 40.0;

class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    super.key,
    required this.player,
    this.trailing,
    this.onTap,
  });

  final PlayerListItemModel player;
  final Widget? trailing;
  final VoidCallback? onTap;

  Widget _buildLeading(BuildContext context) {
    return PlayerAvatar(
      cutoutUrl: player.cutoutUrl,
      photoUrl: player.photoUrl,
      playerName: player.name,
      role: player.position,
      teamColor: getTeamColor(player.realTeamName),
      size: kPlayerListTilePhotoSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(context),
      title: Text(
        player.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${player.position} · ${player.realTeamName} · ${player.initialPrice.toStringAsFixed(0)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}


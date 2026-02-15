import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/player_detail.dart';
import '../../services/player_service.dart';

/// Colore badge per ruolo: POR giallo, DIF verde, CEN blu, ATT rosso.
Color _positionBadgeColor(String position) {
  switch (position.toUpperCase()) {
    case 'POR':
      return Colors.amber.shade700;
    case 'DIF':
      return Colors.green.shade700;
    case 'CEN':
      return Colors.blue.shade700;
    case 'ATT':
      return Colors.red.shade700;
    default:
      return Colors.grey.shade700;
  }
}

String _resolveUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '$kBackendOrigin$url';
}

/// Scheda giocatore completa: header, info, squadra, quotazione, statistiche, biografia.
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerDetailModel?>(
      future: context.read<PlayerService>().getPlayerDetail(playerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton(), title: const Text('Giocatore')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton(), title: const Text('Giocatore')),
            body: const Center(child: Text('Giocatore non trovato.')),
          );
        }
        return Scaffold(
          appBar: AppBar(leading: const BackButton(), title: const Text('Scheda giocatore')),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderSection(player: p),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoCard(player: p),
                      const SizedBox(height: 12),
                      _SquadraCard(player: p),
                      const SizedBox(height: 12),
                      _QuotazioneCard(player: p),
                      const SizedBox(height: 12),
                      _StatisticheCard(stats: p.seasonStats),
                      const SizedBox(height: 12),
                      _BiografiaCard(description: p.description),
                      const SizedBox(height: 16),
                      if (p.fantasyScores.isNotEmpty) ...[
                        Text('Punteggi fantasy', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...p.fantasyScores.take(10).map(
                              (s) => ListTile(
                                dense: true,
                                title: Text('Giornata ${s.matchday}: ${s.score.toStringAsFixed(1)}'),
                                subtitle: s.events.isNotEmpty ? Text(s.events.join(', ')) : null,
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _positionBadgeColor(player.position);
    final cutout = _resolveUrl(player.cutoutUrl);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [badgeColor.withOpacity(0.85), badgeColor.withOpacity(0.5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        children: [
          if (cutout.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cutout,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => SizedBox(width: 150, height: 150, child: Icon(Icons.person, size: 80, color: Colors.white.withOpacity(0.9))),
              ),
            )
          else
            SizedBox(
              width: 150,
              height: 150,
              child: Icon(Icons.person, size: 80, color: Colors.white.withOpacity(0.9)),
            ),
          const SizedBox(height: 12),
          Text(
            player.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (player.shirtNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text('#${player.shirtNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              if (player.shirtNumber != null && player.position.isNotEmpty) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  player.positionDetail ?? player.position,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _InfoColumn(label: 'Età', value: player.age?.toString() ?? '—')),
            Expanded(child: _InfoColumn(label: 'Altezza', value: player.height ?? '—')),
            Expanded(child: _InfoColumn(label: 'Peso', value: player.weight ?? '—')),
            Expanded(child: _InfoColumn(label: 'Nazionalità', value: _nationalityDisplay(player.nationality))),
          ],
        ),
      ),
    );
  }

  String _nationalityDisplay(String? nat) {
    if (nat == null || nat.isEmpty) return '—';
    return nat;
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _SquadraCard extends StatelessWidget {
  const _SquadraCard({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    final badge = _resolveUrl(player.realTeamBadge);
    final name = player.realTeamName ?? '—';
    final num = player.shirtNumber;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (badge.isNotEmpty)
              Image.network(badge, width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40, child: Icon(Icons.shield_outlined))),
            if (badge.isNotEmpty) const SizedBox(width: 12),
            Expanded(child: Text(name, style: Theme.of(context).textTheme.titleSmall)),
            if (num != null) Text('· #$num', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _QuotazioneCard extends StatelessWidget {
  const _QuotazioneCard({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    final initial = player.initialPrice ?? 0.0;
    final current = player.currentValue ?? initial;
    final maxVal = (initial > current ? initial : current).clamp(1.0, double.infinity);
    final progress = maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quotazione iniziale: ${initial.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Valore attuale: ${current.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(current >= initial ? Colors.green : Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticheCard extends StatelessWidget {
  const _StatisticheCard({this.stats});

  final PlayerSeasonStatsModel? stats;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Statistiche stagione', style: Theme.of(context).textTheme.titleSmall),),);
    }
    final s = stats!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiche stagione', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCell(label: 'Presenze', value: '${s.appearances}')),
                Expanded(child: _StatCell(label: 'Gol', value: '${s.goals}')),
                Expanded(child: _StatCell(label: 'Assist', value: '${s.assists}')),
                Expanded(child: _StatCell(label: 'Media voto', value: s.avgRating?.toStringAsFixed(1) ?? '—')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCell(label: 'Minuti', value: '${s.minutesPlayed}')),
                Expanded(child: _StatCell(label: 'Ammonizioni', value: '${s.yellowCards}')),
                Expanded(child: _StatCell(label: 'Espulsioni', value: '${s.redCards}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BiografiaCard extends StatefulWidget {
  const _BiografiaCard({this.description});

  final String? description;

  @override
  State<_BiografiaCard> createState() => _BiografiaCardState();
}

class _BiografiaCardState extends State<_BiografiaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final desc = widget.description?.trim();
    if (desc == null || desc.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Biografia', style: Theme.of(context).textTheme.titleSmall),
        ),
      );
    }
    final showExpand = desc.length > 120;
    final text = _expanded || !showExpand ? desc : '${desc.substring(0, 120)}...';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: showExpand ? () => setState(() => _expanded = !_expanded) : null,
              child: Row(
                children: [
                  Text('Biografia', style: Theme.of(context).textTheme.titleMedium),
                  if (showExpand) Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

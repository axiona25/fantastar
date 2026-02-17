import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/player_detail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/player_avatar.dart';
import '../../services/player_service.dart';

String _resolveUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '$kBackendOrigin$url';
}

/// Scheda giocatore: design Fantastar, palette progetto, layout moderno.
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
            backgroundColor: AppColors.background1,
            appBar: AppBar(
              leading: const BackButton(),
              title: Text('Scheda giocatore', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            backgroundColor: AppColors.background1,
            appBar: AppBar(
              leading: const BackButton(),
              title: Text('Scheda giocatore', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
            body: Center(
              child: Text(
                'Giocatore non trovato.',
                style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
              ),
            ),
          );
        }
        return _PlayerDetailContent(player: p);
      },
    );
  }
}

class _PlayerDetailContent extends StatelessWidget {
  const _PlayerDetailContent({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    final roleColor = getRoleBadgeColor(player.position);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FantastarBackground(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header con back e titolo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 24),
                          onPressed: () => context.pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        const Spacer(),
                        Text(
                          'Scheda giocatore',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                // Hero card: avatar + nome + ruolo/number
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            roleColor,
                            roleColor.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          PlayerAvatar(
                            playerId: player.id,
                            role: player.position,
                            playerName: player.name,
                            size: 110,
                            showRoleBadge: true,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            player.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (player.shirtNumber != null)
                                _Chip(
                                  text: '#${player.shirtNumber}',
                                  bg: Colors.white.withOpacity(0.25),
                                ),
                              _Chip(
                                text: player.positionDetail ?? player.position,
                                bg: Colors.white.withOpacity(0.25),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
                // Blocco contenuti: card bianche
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _InfoCard(player: player),
                      const SizedBox(height: 14),
                      _SquadraCard(player: player),
                      const SizedBox(height: 14),
                      _QuotazioneCard(player: player),
                      const SizedBox(height: 14),
                      _StatisticheCard(stats: player.seasonStats),
                      const SizedBox(height: 14),
                      _BiografiaCard(description: player.description),
                      if (player.fantasyScores.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _FantasyScoresSection(scores: player.fantasyScores),
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg});

  final String text;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

Widget _sectionCard({
  required String title,
  required Widget child,
  IconData? icon,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.player});

  final PlayerDetailModel player;

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      title: 'Dati anagrafici',
      icon: Icons.person_outline,
      child: Row(
        children: [
          Expanded(child: _InfoCell(label: 'Età', value: player.age?.toString() ?? '—')),
          Expanded(child: _InfoCell(label: 'Altezza', value: player.height ?? '—')),
          Expanded(child: _InfoCell(label: 'Peso', value: player.weight ?? '—')),
          Expanded(child: _InfoCell(label: 'Nazionalità', value: player.nationality ?? '—')),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
    return _sectionCard(
      title: 'Squadra',
      icon: Icons.shield_outlined,
      child: Row(
        children: [
          if (badge.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                badge,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: AppColors.background3,
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
          if (player.shirtNumber != null)
            Text(
              '#${player.shirtNumber}',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
            ),
        ],
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
    final isUp = current >= initial;
    return _sectionCard(
      title: 'Quotazione',
      icon: Icons.trending_up,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Iniziale: ${initial.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
              ),
              Text(
                'Attuale: ${current.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.background3,
              valueColor: AlwaysStoppedAnimation<Color>(isUp ? AppColors.success : const Color(0xFFFF8F00)),
            ),
          ),
        ],
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
      return _sectionCard(
        title: 'Statistiche stagione',
        icon: Icons.bar_chart,
        child: Text(
          'Nessun dato disponibile',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
        ),
      );
    }
    final s = stats!;
    return _sectionCard(
      title: 'Statistiche stagione',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatCell(label: 'Presenze', value: '${s.appearances}')),
              Expanded(child: _StatCell(label: 'Gol', value: '${s.goals}')),
              Expanded(child: _StatCell(label: 'Assist', value: '${s.assists}')),
              Expanded(child: _StatCell(label: 'Media', value: s.avgRating?.toStringAsFixed(1) ?? '—')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatCell(label: 'Minuti', value: '${s.minutesPlayed}')),
              Expanded(child: _StatCell(label: 'Ammonizioni', value: '${s.yellowCards}')),
              Expanded(child: _StatCell(label: 'Espulsioni', value: '${s.redCards}')),
            ],
          ),
        ],
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
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
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
      return _sectionCard(
        title: 'Biografia',
        icon: Icons.article_outlined,
        child: Text(
          'Nessuna biografia disponibile.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
        ),
      );
    }
    final showExpand = desc.length > 140;
    final text = _expanded || !showExpand ? desc : '${desc.substring(0, 140)}...';
    return _sectionCard(
      title: 'Biografia',
      icon: Icons.article_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.45, color: AppColors.textDark),
          ),
          if (showExpand)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _expanded ? 'Mostra meno' : 'Mostra di più',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FantasyScoresSection extends StatelessWidget {
  const _FantasyScoresSection({required this.scores});

  final List<PlayerFantasyScoreModel> scores;

  @override
  Widget build(BuildContext context) {
    final list = scores.take(10).toList();
    return _sectionCard(
      title: 'Punteggi fantasy',
      icon: Icons.sports_esports,
      child: Column(
        children: [
          ...list.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s.matchday}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.events.isNotEmpty ? s.events.join(', ') : '—',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    s.score.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

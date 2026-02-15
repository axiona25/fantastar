import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../services/match_service.dart';
import '../../utils/error_utils.dart';

/// Live Overview: partite della giornata selezionata (matchday passato dal parent).
/// Ordine: 1) IN CORSO (IN_PLAY/PAUSED), 2) TERMINATE (FINISHED), 3) DA GIOCARE (SCHEDULED/TIMED).
/// Giornate passate: risultati (TERMINATA + score). Corrente: LIVE e TERMINATE. Future: PROGRAMMATA con data/ora.
/// Refresh ogni 30s.
class LiveOverviewScreen extends StatefulWidget {
  const LiveOverviewScreen({
    super.key,
    required this.matchday,
    required this.todayMatchday,
  });

  final int matchday;
  final int todayMatchday;

  @override
  State<LiveOverviewScreen> createState() => _LiveOverviewScreenState();
}

class _LiveOverviewScreenState extends State<LiveOverviewScreen> {
  List<MatchModel> _matches = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;

  Future<void> _load() async {
    final isFirstLoad = _matches.isEmpty && !_loading;
    setState(() {
      if (isFirstLoad) _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<MatchService>().getMatchesByMatchday(widget.matchday);
      if (mounted) {
        setState(() {
          _matches = _orderByStatus(list);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  /// Ordine: IN_PLAY/PAUSED first, poi FINISHED, poi SCHEDULED/TIMED.
  static List<MatchModel> _orderByStatus(List<MatchModel> list) {
    final inCorso = list.where((m) => m.status == 'IN_PLAY' || m.status == 'PAUSED').toList();
    final finished = list.where((m) => m.status == 'FINISHED').toList();
    final scheduled = list.where((m) => m.status == 'SCHEDULED' || m.status == 'TIMED').toList();
    return [...inCorso, ...finished, ...scheduled];
  }

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(LiveOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchday != widget.matchday) _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  static bool _isLive(String? s) => s == 'IN_PLAY' || s == 'PAUSED';
  static bool _isFinished(String? s) => s == 'FINISHED';
  static bool _isScheduled(String? s) => s == 'SCHEDULED' || s == 'TIMED';

  @override
  Widget build(BuildContext context) {
    final inCorso = _matches.where((m) => _isLive(m.status)).toList();
    final terminate = _matches.where((m) => _isFinished(m.status)).toList();
    final daGiocare = _matches.where((m) => _isScheduled(m.status)).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading && _matches.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _matches.isEmpty
              ? Center(child: Text(_error!))
                  : _matches.isEmpty
                  ? const Center(child: Text('Nessuna partita per questa giornata'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (inCorso.isNotEmpty) ...[
                          _SectionHeader(title: 'IN CORSO', color: Colors.red),
                          ...inCorso.map((m) => _MatchCard(match: m, badge: _MatchBadge.live)),
                        ],
                        if (terminate.isNotEmpty) ...[
                          _SectionHeader(title: 'TERMINATE', color: Colors.grey),
                          ...terminate.map((m) => _MatchCard(match: m, badge: _MatchBadge.terminata)),
                        ],
                        if (daGiocare.isNotEmpty) ...[
                          _SectionHeader(title: 'PROGRAMMATA', color: Colors.blue),
                          ...daGiocare.map((m) => _MatchCard(match: m, badge: _MatchBadge.programmata)),
                        ],
                      ],
                    ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }
}

enum _MatchBadge { live, terminata, programmata }

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.badge});

  final MatchModel match;
  final _MatchBadge badge;

  @override
  Widget build(BuildContext context) {
    final isLive = badge == _MatchBadge.live;
    final isFinished = badge == _MatchBadge.terminata;
    final isScheduled = badge == _MatchBadge.programmata;

    final scoreText = isScheduled
        ? '-'
        : '${match.homeScore ?? 0} - ${match.awayScore ?? 0}';
    final subtitle = isLive && match.minute != null
        ? "${match.minute}'"
        : isScheduled && match.kickOff != null
            ? _formatKickOff(match.kickOff!)
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/live/match/${match.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Crest(url: match.homeCrest),
                        const SizedBox(width: 6),
                        Text(
                          match.homeSigla,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        scoreText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          match.awaySigla,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 6),
                        _Crest(url: match.awayCrest),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BadgeWidget(badge: badge),
            ],
          ),
        ),
      ),
    );
  }

  String _formatKickOff(DateTime d) {
    return DateFormat('EEE d MMM, HH:mm', 'it').format(d);
  }
}

class _Crest extends StatelessWidget {
  const _Crest({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    if (url == null || url!.isEmpty) {
      return const SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.sports_soccer, size: 22),
      );
    }
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 22),
    );
  }
}

class _BadgeWidget extends StatelessWidget {
  const _BadgeWidget({required this.badge});

  final _MatchBadge badge;

  @override
  Widget build(BuildContext context) {
    switch (badge) {
      case _MatchBadge.live:
        return const _LiveBadge();
      case _MatchBadge.terminata:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'TERMINATA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      case _MatchBadge.programmata:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'PROGRAMMATA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
    }
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.6 + 0.4 * _controller.value),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}

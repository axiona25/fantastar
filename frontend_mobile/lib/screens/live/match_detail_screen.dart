import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';

import '../../app/constants.dart';
import '../../models/match.dart';
import '../../widgets/player_avatar.dart';
import '../../models/standing_row.dart';
import '../../services/match_service.dart';
import '../../services/stats_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/error_utils.dart';

/// Dettaglio partita: risultato, cronaca, statistiche, formazioni, cronaca testuale (ESPN). Auto-refresh 30s se LIVE.
class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final int matchId;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  MatchDetailFullModel? _match;
  List<MatchHighlightModel> _highlights = [];
  List<StandingRow> _standings = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;
  final WebSocketService _ws = WebSocketService();
  final ScrollController _scrollController = ScrollController();
  Set<int> _highlightEventIndices = {};
  Set<int> _highlightCommentaryIndices = {};
  bool _showGoalOverlay = false;
  bool _matchFinishedBanner = false;
  late TabController _tabController;

  static bool _isLiveStatus(String? s) =>
      s == 'IN_PLAY' || s == 'PAUSED' || s == 'HALFTIME';

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final m = await context.read<MatchService>().getMatchDetailFull(widget.matchId);
      if (mounted) {
        setState(() {
          _match = m;
          _loading = false;
          _error = null;
        });
        _startPollingIfLive();
        _loadHighlights();
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

  void _startPollingIfLive() {
    _refreshTimer?.cancel();
    if (_match != null &&
        _isLiveStatus(_match!.status)) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshDetail(),
      );
    }
  }

  Future<void> _refreshDetail() async {
    if (!mounted || _match == null) return;
    try {
      final m = await context.read<MatchService>().getMatchDetailFull(widget.matchId);
      if (!mounted) return;
      final wasLive = _isLiveStatus(_match!.status);
      final nowFinished = m.status == 'FINISHED';

      if (nowFinished && wasLive) {
        _refreshTimer?.cancel();
        setState(() {
          _match = m;
          _matchFinishedBanner = true;
        });
        return;
      }

      final oldEventCount = _match!.events.length;
      final newEventCount = m.events.length;
      final oldCommCount = _match!.commentary.length;
      final newCommCount = m.commentary.length;

      Set<int> newEventIndices = {};
      if (newEventCount > oldEventCount) {
        for (var i = oldEventCount; i < newEventCount; i++) {
          newEventIndices.add(i);
        }
      }
      // Commentary is ordered newest first; new entries are at indices 0 .. (newCount - oldCount - 1)
      Set<int> newCommIndices = {};
      if (newCommCount > oldCommCount) {
        final added = newCommCount - oldCommCount;
        for (var i = 0; i < added; i++) {
          newCommIndices.add(i);
        }
      }

      bool hasNewGoal = false;
      if (newEventIndices.isNotEmpty) {
        final goalTypes = {'Goal', 'Own Goal', 'Gol'};
        for (final i in newEventIndices) {
          if (i < m.events.length && goalTypes.contains(m.events[i].type)) {
            hasNewGoal = true;
            break;
          }
        }
      }

      setState(() {
        _match = m;
        _highlightEventIndices = newEventIndices;
        _highlightCommentaryIndices = newCommIndices;
        if (hasNewGoal) _showGoalOverlay = true;
      });

      if (_scrollController.hasClients && _scrollController.offset < 50) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightEventIndices = {};
            _highlightCommentaryIndices = {};
          });
        }
      });
      if (hasNewGoal) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showGoalOverlay = false);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHighlights() async {
    try {
      final list = await context.read<MatchService>().getMatchHighlights(widget.matchId);
      if (mounted) setState(() => _highlights = list);
    } catch (_) {
      if (mounted) setState(() => _highlights = []);
    }
  }

  void _connectWs() {
    final url = context.read<MatchService>().matchWsUrl(widget.matchId);
    _ws.connect(url, onMessage: (data) {
      if (data is! Map) return;
      if (!mounted || _match == null) return;
      final type = data['type'] as String?;
      if (type == 'match_update') {
        setState(() {
          _match = MatchDetailFullModel(
            id: _match!.id,
            matchday: _match!.matchday,
            status: data['status'] as String? ?? _match!.status,
            minute: data['minute'] as int?,
            kickOff: _match!.kickOff,
            homeTeam: _match!.homeTeam,
            awayTeam: _match!.awayTeam,
            homeScore: data['home_score'] as int? ?? _match!.homeScore,
            awayScore: data['away_score'] as int? ?? _match!.awayScore,
            referee: _match!.referee,
            venue: _match!.venue,
            events: _match!.events,
            lineups: _match!.lineups,
            statistics: _match!.statistics,
            commentary: _match!.commentary,
            translated: _match!.translated,
          );
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWs());
  }

  Future<void> _loadStandings() async {
    try {
      final list = await context.read<StatsService>().getStandings();
      if (mounted) setState(() => _standings = list);
    } catch (_) {
      if (mounted) setState(() => _standings = []);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _ws.disconnect();
    super.dispose();
  }

  @override
  void didUpdateWidget(MatchDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _match == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Partita')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _match == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Partita')),
        body: Center(child: Text(_error!)),
      );
    }
    final m = _match!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text('Giornata ${m.matchday}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.star_outline),
                tooltip: 'Pagelle',
                onPressed: () => context.push('/match/${widget.matchId}/pagelle'),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MatchDetailHeader(
                match: m,
                highlightEventIndices: _highlightEventIndices,
                matchFinishedBanner: _matchFinishedBanner,
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'CRONACA'),
                  Tab(text: 'VOTI'),
                  Tab(text: 'FORMAZIONI'),
                  Tab(text: 'STATISTICHE'),
                  Tab(text: 'CLASSIFICA'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CronacaTab(
                      match: m,
                      highlights: _highlights,
                      highlightEventIndices: _highlightEventIndices,
                      highlightCommentaryIndices: _highlightCommentaryIndices,
                      scrollController: _scrollController,
                      translated: m.translated,
                    ),
                    _VotiTab(
                      matchId: widget.matchId,
                      status: m.status,
                      homeTeamName: m.homeTeam.name,
                      awayTeamName: m.awayTeam.name,
                    ),
                    _FormazioniTab(lineups: m.lineups),
                    _StatisticheTab(statistics: m.statistics),
                    _ClassificaTab(
                      standings: _standings,
                      homeTeamName: m.homeTeam.name,
                      awayTeamName: m.awayTeam.name,
                      homeShort: m.homeTeam.short,
                      awayShort: m.awayTeam.short,
                      onLoad: _loadStandings,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showGoalOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Text(
                      '⚽ GOOOL!',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ),
                  onEnd: () {},
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Header fisso (stile ScoreBat): stemmi, nomi squadre, risultato, badge, data/ora.
class _MatchDetailHeader extends StatelessWidget {
  const _MatchDetailHeader({
    required this.match,
    this.highlightEventIndices = const {},
    this.matchFinishedBanner = false,
  });

  final MatchDetailFullModel match;
  final Set<int> highlightEventIndices;
  final bool matchFinishedBanner;

  @override
  Widget build(BuildContext context) {
    final homeCrest = match.homeTeam.crest;
    final awayCrest = match.awayTeam.crest;
    final homeName = match.homeTeam.name.toUpperCase();
    final awayName = match.awayTeam.name.toUpperCase();
    String dateTimeStr = '—';
    if (match.kickOff != null) {
      dateTimeStr = '${DateFormat('HH:mm').format(match.kickOff!)}, ${DateFormat('EEEE d MMMM', 'it').format(match.kickOff!)}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: Column(
        children: [
          if (matchFinishedBanner)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(8)),
                child: Text('Partita terminata', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (homeCrest != null && homeCrest.isNotEmpty)
                      Image.network(
                        homeCrest.startsWith('http') ? homeCrest : '$kBackendOrigin$homeCrest',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 44),
                      )
                    else
                      const Icon(Icons.shield_outlined, size: 44),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homeName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${match.homeScore ?? "-"} - ${match.awayScore ?? "-"}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        awayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (awayCrest != null && awayCrest.isNotEmpty)
                      Image.network(
                        awayCrest.startsWith('http') ? awayCrest : '$kBackendOrigin$awayCrest',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 44),
                      )
                    else
                      const Icon(Icons.shield_outlined, size: 44),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatusBadge(status: match.status, minute: match.minute, kickOff: match.kickOff),
          const SizedBox(height: 6),
          Text(
            dateTimeStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatefulWidget {
  const _StatusBadge({required this.status, this.minute, this.kickOff});

  final String status;
  final int? minute;
  final DateTime? kickOff;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> {
  Timer? _blinkTimer;
  bool _blinkOn = true;

  @override
  void initState() {
    super.initState();
    if (widget.status == 'IN_PLAY' || widget.status == 'PAUSED' || widget.status == 'HALFTIME') {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _blinkOn = !_blinkOn);
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    bool isLive = widget.status == 'IN_PLAY' || widget.status == 'PAUSED' || widget.status == 'HALFTIME';
    if (widget.status == 'FINISHED') {
      label = 'TERMINATA';
      color = Colors.grey;
    } else if (isLive) {
      label = 'LIVE ${widget.minute ?? 0}\'';
      color = Colors.red;
    } else {
      final time = widget.kickOff != null ? 'ore ${widget.kickOff!.hour.toString().padLeft(2, '0')}:${widget.kickOff!.minute.toString().padLeft(2, '0')}' : 'orario TBD';
      label = 'DA GIOCARE $time';
      color = Colors.orange;
    }
    final opacity = isLive && !_blinkOn ? 0.5 : 1.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: isLive ? opacity : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

/// Tab Cronaca: eventi (gol sx/dx, minuto al centro), cronaca testuale, highlights.
class _CronacaTab extends StatelessWidget {
  const _CronacaTab({
    required this.match,
    required this.highlights,
    this.highlightEventIndices = const {},
    this.highlightCommentaryIndices = const {},
    required this.scrollController,
    this.translated = true,
  });

  final MatchDetailFullModel match;
  final List<MatchHighlightModel> highlights;
  final Set<int> highlightEventIndices;
  final Set<int> highlightCommentaryIndices;
  final ScrollController scrollController;
  final bool translated;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (match.events.isNotEmpty) ...[
          _CronacaEventsScoreBatStyle(
            events: match.events,
            highlightEventIndices: highlightEventIndices,
          ),
          const SizedBox(height: 20),
        ],
        if (match.commentary.isNotEmpty) ...[
          _CronacaTestualeSection(
            commentary: match.commentary,
            highlightIndices: highlightCommentaryIndices,
          ),
          const SizedBox(height: 20),
        ],
        if (highlights.isNotEmpty) ...[
          _HighlightsSection(highlights: highlights),
          const SizedBox(height: 16),
        ],
        if (!translated && (match.events.isNotEmpty || match.commentary.isNotEmpty))
          Center(
            child: Chip(
              label: Text('🔄 Traduzione in corso...', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }
}

/// Tab Voti: voti live per casa/trasferta (solo rating, ruolo, icone eventi).
class _VotiTab extends StatefulWidget {
  const _VotiTab({
    required this.matchId,
    required this.status,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final int matchId;
  final String status;
  final String homeTeamName;
  final String awayTeamName;

  @override
  State<_VotiTab> createState() => _VotiTabState();
}

class _VotiTabState extends State<_VotiTab> {
  MatchRatingsResponseModel? _ratings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<MatchService>().getMatchRatings(widget.matchId);
      if (mounted) setState(() {
        _ratings = r;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Impossibile caricare i voti';
      });
    }
  }

  static bool _isLive(String? s) =>
      s == 'IN_PLAY' || s == 'PAUSED' || s == 'HALFTIME';

  static Color _ratingColor(double? v) {
    if (v == null) return Colors.grey;
    if (v >= 7.0) return Colors.green;
    if (v >= 6.0) return Colors.black87;
    if (v >= 5.5) return Colors.orange;
    return Colors.red;
  }

  static int _roleOrder(String role) {
    switch (role.toUpperCase()) {
      case 'POR': return 0;
      case 'DIF': return 1;
      case 'CEN': return 2;
      case 'ATT': return 3;
      default: return 2;
    }
  }

  static String _roleLetter(String role) {
    switch (role.toUpperCase()) {
      case 'POR': return 'P';
      case 'DIF': return 'D';
      case 'CEN': return 'C';
      case 'ATT': return 'A';
      default: return 'C';
    }
  }

  static List<MatchRatingPlayerModel> _sortByRole(List<MatchRatingPlayerModel> list) {
    final copy = List<MatchRatingPlayerModel>.from(list);
    copy.sort((a, b) {
      final o = _roleOrder(a.role).compareTo(_roleOrder(b.role));
      if (o != 0) return o;
      final na = a.number ?? '';
      final nb = b.number ?? '';
      if (na.toString().isNotEmpty && nb.toString().isNotEmpty) return na.toString().compareTo(nb.toString());
      return a.name.compareTo(b.name);
    });
    return copy;
  }

  /// Icone eventi: gol/autogol da eventList (pallone normale vs rosso), il resto da events.
  static List<Widget> _eventIcons(MatchRatingPlayerEventsModel e, List<MatchRatingPlayerEventItemModel> eventList) {
    final icons = <Widget>[];
    for (final ev in eventList) {
      if (ev.type == 'goal') {
        icons.add(Text('⚽', style: TextStyle(fontSize: 12)));
      } else if (ev.type == 'own_goal') {
        icons.add(Icon(Icons.sports_soccer, color: Colors.red, size: 16));
      }
    }
    if (e.yellowCards > 0) icons.add(Text('🟨', style: TextStyle(fontSize: 12)));
    if (e.redCards > 0) icons.add(Text('🟥', style: TextStyle(fontSize: 12)));
    if (e.assists > 0) icons.add(Text('🔄', style: TextStyle(fontSize: 12)));
    if (e.subbedIn > 0) icons.add(Text('🔄', style: TextStyle(fontSize: 12)));
    if (e.subbedOut > 0) icons.add(Text('🔻', style: TextStyle(fontSize: 12)));
    if (e.injury > 0) icons.add(const _InjuryIcon());
    if (e.penaltySaved > 0) icons.add(Text('🧤', style: TextStyle(fontSize: 12)));
    if (e.penaltyMissed > 0) icons.add(Text('⛔', style: TextStyle(fontSize: 12)));
    return icons;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }
    final r = _ratings;
    if (r == null || (r.homeTeam.players.isEmpty && r.awayTeam.players.isEmpty)) {
      return Center(
        child: Text(
          'Nessun voto disponibile',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _VotiTwoColumns(
            homeTeamName: r.homeTeam.name,
            awayTeamName: r.awayTeam.name,
            homeStarters: _sortByRole(r.homeTeam.starters),
            awayStarters: _sortByRole(r.awayTeam.starters),
            homeBench: _sortByRole(r.homeTeam.bench),
            awayBench: _sortByRole(r.awayTeam.bench),
            ratingColor: _ratingColor,
            roleLetter: _roleLetter,
            eventIcons: _eventIcons,
          ),
        ],
      ),
    );
  }
}

/// Icona infortunio: quadrato bianco con croce rossa (simbolo pronto soccorso). Solo per evento "injury".
class _InjuryIcon extends StatelessWidget {
  const _InjuryIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Icon(Icons.add, color: Colors.red, size: 16),
      ),
    );
  }
}

class _PulsingChip extends StatefulWidget {
  const _PulsingChip({required this.label});

  final String label;

  @override
  State<_PulsingChip> createState() => _PulsingChipState();
}

class _PulsingChipState extends State<_PulsingChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
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
        return Opacity(
          opacity: 0.6 + 0.4 * _controller.value,
          child: Chip(
            backgroundColor: Colors.red.shade700,
            label: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        );
      },
    );
  }
}

class _VotiTwoColumns extends StatelessWidget {
  const _VotiTwoColumns({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeStarters,
    required this.awayStarters,
    required this.homeBench,
    required this.awayBench,
    required this.ratingColor,
    required this.roleLetter,
    required this.eventIcons,
  });

  final String homeTeamName;
  final String awayTeamName;
  final List<MatchRatingPlayerModel> homeStarters;
  final List<MatchRatingPlayerModel> awayStarters;
  final List<MatchRatingPlayerModel> homeBench;
  final List<MatchRatingPlayerModel> awayBench;
  final Color Function(double?) ratingColor;
  final String Function(String) roleLetter;
  final List<Widget> Function(MatchRatingPlayerEventsModel, List<MatchRatingPlayerEventItemModel>) eventIcons;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final maxStarters = homeStarters.length > awayStarters.length ? homeStarters.length : awayStarters.length;
    for (var i = 0; i < maxStarters; i++) {
      final home = i < homeStarters.length ? homeStarters[i] : null;
      final away = i < awayStarters.length ? awayStarters[i] : null;
      rows.add(_VotiRow(
        home: home,
        away: away,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        ratingColor: ratingColor,
        roleLetter: roleLetter,
        eventIcons: eventIcons,
      ));
    }

    if (homeBench.isNotEmpty || awayBench.isNotEmpty) {
      rows.add(const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 8),
        child: Center(child: Text('—— Panchina ——', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ));
      final maxBench = homeBench.length > awayBench.length ? homeBench.length : awayBench.length;
      for (var i = 0; i < maxBench; i++) {
        final home = i < homeBench.length ? homeBench[i] : null;
        final away = i < awayBench.length ? awayBench[i] : null;
        rows.add(_VotiRow(
          home: home,
          away: away,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          ratingColor: ratingColor,
          roleLetter: roleLetter,
          eventIcons: eventIcons,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _VotiRow extends StatelessWidget {
  const _VotiRow({
    this.home,
    this.away,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.ratingColor,
    required this.roleLetter,
    required this.eventIcons,
  });

  final MatchRatingPlayerModel? home;
  final MatchRatingPlayerModel? away;
  final String homeTeamName;
  final String awayTeamName;
  final Color Function(double?) ratingColor;
  final String Function(String) roleLetter;
  final List<Widget> Function(MatchRatingPlayerEventsModel, List<MatchRatingPlayerEventItemModel>) eventIcons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: home != null
                ? _PlayerVotoCell(
                    player: home!,
                    teamName: homeTeamName,
                    ratingColor: ratingColor,
                    roleLetter: roleLetter,
                    eventIcons: eventIcons,
                  )
                : const SizedBox(height: 56),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: away != null
                ? _PlayerVotoCell(
                    player: away!,
                    teamName: awayTeamName,
                    ratingColor: ratingColor,
                    roleLetter: roleLetter,
                    eventIcons: eventIcons,
                    avatarRight: true,
                  )
                : const SizedBox(height: 56),
          ),
        ],
      ),
    );
  }
}

class _PlayerVotoCell extends StatelessWidget {
  const _PlayerVotoCell({
    required this.player,
    required this.teamName,
    required this.ratingColor,
    required this.roleLetter,
    required this.eventIcons,
    this.avatarRight = false,
  });

  final MatchRatingPlayerModel player;
  final String teamName;
  final Color Function(double?) ratingColor;
  final String Function(String) roleLetter;
  final List<Widget> Function(MatchRatingPlayerEventsModel, List<MatchRatingPlayerEventItemModel>) eventIcons;
  final bool avatarRight;

  static String _shortName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts[0];
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final hasRating = player.liveRating != null;
    final ratingStr = hasRating ? player.liveRating!.toStringAsFixed(1) : '—';
    final ratingColorValue = hasRating ? ratingColor(player.liveRating) : Colors.grey.shade400;
    final icons = eventIcons(player.events, player.eventList);
    final role = roleLetter(player.role);
    final avatar = PlayerAvatar(
      cutoutUrl: player.cutoutUrl,
      photoUrl: player.photoUrl,
      playerName: player.name,
      role: player.role,
      teamColor: getTeamColor(teamName),
      size: 44,
    );
    final content = Expanded(
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _shortName(player.name),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ratingStr,
                        style: TextStyle(
                          fontWeight: hasRating ? FontWeight.bold : FontWeight.normal,
                          color: ratingColorValue,
                          fontSize: hasRating ? 15 : 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        role,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (icons.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        ...icons,
                      ],
                    ],
                  ),
                ],
              ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: avatarRight
              ? [content, const SizedBox(width: 8), avatar]
              : [avatar, const SizedBox(width: 8), content],
        ),
      ),
    );
  }
}

/// Eventi cronaca stile ScoreBat: gol casa a sinistra, gol ospite a destra, minuto al centro con icona.
class _CronacaEventsScoreBatStyle extends StatelessWidget {
  const _CronacaEventsScoreBatStyle({
    required this.events,
    this.highlightEventIndices = const {},
  });

  final List<MatchEventDetailModel> events;
  final Set<int> highlightEventIndices;

  static bool _shouldShow(MatchEventDetailModel e) {
    final t = (e.type).trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t == 'kickoff' || t == 'halftime' || t == 'second half' || t == 'end' || t == 'full time') return false;
    return _kCronacaVisibleTypes.contains(e.type) ||
        (e.type == 'Goal' || e.type == 'Gol' || e.type == 'Own Goal' ||
            e.type.contains('Card') || e.type.contains('cartellino') ||
            e.type == 'Substitution' || e.type == 'Sostituzione');
  }

  static String _iconFor(String type) {
    if (type == 'Goal' || type == 'Own Goal' || type == 'Gol') return '⚽';
    if (type.contains('Yellow') || type.contains('giallo')) return '🟨';
    if (type.contains('Red') || type.contains('rosso')) return '🟥';
    if (type == 'Substitution' || type == 'Sostituzione') return '🔄';
    return '•';
  }

  static String _namePart(MatchEventDetailModel e) {
    if (e.type == 'Substitution' || e.type == 'Sostituzione') {
      final d = (e.detail ?? '').trim();
      if (d.contains(' → ')) return d.replaceAll(' → ', ' ↔ ');
      if (d.isNotEmpty && (e.player ?? '').trim().isNotEmpty) return '${e.player} ↔ $d';
      if (d.isNotEmpty) return d;
      return e.player ?? '';
    }
    return e.player ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final withIndex = <int, MatchEventDetailModel>{};
    for (var i = 0; i < events.length; i++) {
      if (_shouldShow(events[i])) withIndex[i] = events[i];
    }
    if (withIndex.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cronaca', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...withIndex.entries.map((e) {
              final ev = e.value;
              final isHome = ev.team == 'home';
              final icon = _iconFor(ev.type);
              final name = _namePart(ev);
              final highlight = highlightEventIndices.contains(e.key);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: highlight ? Colors.amber.withOpacity(0.35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        isHome ? name : '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ev.minuteDisplay, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(icon, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        !isHome ? name : '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Tab Formazioni: schema campo + tab Casa/Trasferta + panchina.
class _FormazioniTab extends StatefulWidget {
  const _FormazioniTab({required this.lineups});

  final Map<String, TeamLineupModel> lineups;

  @override
  State<_FormazioniTab> createState() => _FormazioniTabState();
}

class _FormazioniTabState extends State<_FormazioniTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.lineups['home'];
    final away = widget.lineups['away'];
    if (widget.lineups.isEmpty) {
      return const Center(child: Text('Nessuna formazione disponibile'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Casa'), Tab(text: 'Trasferta')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FormazionePitchAndBench(lineup: home),
              _FormazionePitchAndBench(lineup: away),
            ],
          ),
        ),
      ],
    );
  }
}

/// Schema campo con giocatori posizionati per modulo + panchina.
class _FormazionePitchAndBench extends StatelessWidget {
  const _FormazionePitchAndBench({this.lineup});

  final TeamLineupModel? lineup;

  @override
  Widget build(BuildContext context) {
    if (lineup == null) return const Center(child: Text('—'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 350,
            child: _PitchFormationPainter(lineup: lineup!),
          ),
          const SizedBox(height: 16),
          const Text('— Panchina —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...(lineup!.substitutes).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(p.number ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Campo da calcio con giocatori disposti secondo il modulo (es. 3-5-2).
class _PitchFormationPainter extends StatelessWidget {
  const _PitchFormationPainter({required this.lineup});

  final TeamLineupModel lineup;

  /// Widget compatto per un giocatore sul campo (numero + cognome) per evitare overflow.
  static Widget _buildPlayerOnField(String number, String name) {
    final surname = name.split(' ').lastOrNull ?? name;
    return SizedBox(
      width: 55,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            surname,
            style: const TextStyle(fontSize: 9, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Da "3-5-2" → [1, 3, 5, 2] (POR + righe). Da "3-4-2-1" → [1, 3, 4, 2, 1].
  static List<int> _formationRows(String? formation) {
    if (formation == null || formation.trim().isEmpty) return [1, 4, 4, 2];
    final parts = formation.trim().split(RegExp(r'[-–]'));
    if (parts.isEmpty) return [1, 4, 4, 2];
    final nums = parts.map((e) => int.tryParse(e.trim()) ?? 0).where((n) => n > 0).toList();
    if (nums.isEmpty) return [1, 4, 4, 2];
    return [1, ...nums];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _formationRows(lineup.formation);
    final starting = lineup.starting;
    if (starting.length < 11) return const Center(child: Text('Formazione incompleta'));
    int idx = 0;
    final rowsPlayers = <List<LineupPlayerModel>>[];
    for (final count in rows) {
      final end = (idx + count).clamp(0, starting.length);
      rowsPlayers.add(starting.sublist(idx, end));
      idx = end;
      if (idx >= starting.length) break;
    }
    final flatPlayers = rowsPlayers.expand((e) => e).toList();
    return CustomPaint(
      painter: _PitchPainter(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final positions = <Offset>[];
          final rowCount = rowsPlayers.length;
          for (var r = 0; r < rowCount; r++) {
            final playersInRow = rowsPlayers[r].length;
            final y = h * (0.08 + (r + 1) / (rowCount + 2) * 0.82);
            for (var i = 0; i < playersInRow; i++) {
              final x = w * (0.1 + (i + 1) / (playersInRow + 1) * 0.8);
              positions.add(Offset(x, y));
            }
          }
          return Stack(
            children: [
              for (var i = 0; i < positions.length && i < flatPlayers.length; i++)
                Positioned(
                  left: positions[i].dx - 27,
                  top: positions[i].dy - 21,
                  width: 55,
                  height: 44,
                  child: _buildPlayerOnField(
                    flatPlayers[i].number ?? '?',
                    flatPlayers[i].name,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), paint);
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy), 40, paint);
    canvas.drawLine(Offset(cx, 8), Offset(cx, size.height - 8), paint);
    final boxW = 80.0;
    final boxH = 120.0;
    canvas.drawRect(Rect.fromLTWH(cx - boxW / 2, 8, boxW, boxH), paint);
    canvas.drawRect(Rect.fromLTWH(cx - boxW / 2, size.height - 8 - boxH, boxW, boxH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tab Statistiche: barre orizzontali.
class _StatisticheTab extends StatelessWidget {
  const _StatisticheTab({required this.statistics});

  final List<StatisticsEntryModel> statistics;

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) return const Center(child: Text('Nessuna statistica disponibile'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatisticheSection(statistics: statistics),
      ],
    );
  }
}

/// Tab Classifica: Serie A con squadre della partita evidenziate.
class _ClassificaTab extends StatefulWidget {
  const _ClassificaTab({
    required this.standings,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeShort,
    this.awayShort,
    required this.onLoad,
  });

  final List<StandingRow> standings;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeShort;
  final String? awayShort;
  final VoidCallback onLoad;

  @override
  State<_ClassificaTab> createState() => _ClassificaTabState();
}

class _ClassificaTabState extends State<_ClassificaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  bool _isMatchTeam(StandingRow row) {
    final n = row.teamName.toLowerCase();
    final h = widget.homeTeamName.toLowerCase();
    final a = widget.awayTeamName.toLowerCase();
    if (n.contains(h) || h.contains(n)) return true;
    if (n.contains(a) || a.contains(n)) return true;
    final hs = widget.homeShort?.toLowerCase();
    final as = widget.awayShort?.toLowerCase();
    if (hs != null && n.contains(hs)) return true;
    if (as != null && n.contains(as)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Caricamento classifica...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Classifica Serie A', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...widget.standings.map((row) {
          final isHighlight = _isMatchTeam(row);
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isHighlight ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              leading: SizedBox(
                width: 28,
                child: Text('${row.position}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              title: Row(
                children: [
                  if (row.crest != null && row.crest!.isNotEmpty)
                    Image.network(
                      row.crest!.startsWith('http') ? row.crest! : '$kBackendOrigin${row.crest}',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 24),
                    )
                  else
                    const Icon(Icons.shield_outlined, size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(row.teamName, overflow: TextOverflow.ellipsis)),
                ],
              ),
              trailing: Text('${row.points} pt', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}

class _InfoPartita extends StatelessWidget {
  const _InfoPartita({required this.match});

  final MatchDetailFullModel match;

  @override
  Widget build(BuildContext context) {
    final kickOff = match.kickOff;
    final dateStr = kickOff != null
        ? '${kickOff.day.toString().padLeft(2, '0')}/${kickOff.month.toString().padLeft(2, '0')}/${kickOff.year} ${kickOff.hour.toString().padLeft(2, '0')}:${kickOff.minute.toString().padLeft(2, '0')}'
        : '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Info partita', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Text('Data e ora: $dateStr', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stadium, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Stadio: ${match.venue ?? "—"}', style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sports, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arbitro: ${match.referee != null ? match.referee!.name : "—"}${match.referee?.nationality != null && match.referee!.nationality!.isNotEmpty ? " (${match.referee!.nationality})" : ""}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tipi evento da mostrare in cronaca (EN + IT, dall'API ESPN tradotta).
const Set<String> _kCronacaVisibleTypes = {
  'Goal', 'Own Goal', 'Yellow Card', 'Red Card', 'Substitution',
  'Gol', 'Cartellino giallo', 'Cartellino rosso', 'Sostituzione',
};

/// Cronaca: timeline verticale, eventi casa a sx e trasferta a dx.
class _CronacaSection extends StatelessWidget {
  const _CronacaSection({
    required this.events,
    required this.homeSigla,
    required this.awaySigla,
    this.highlightEventIndices = const {},
  });

  final List<MatchEventDetailModel> events;
  final String homeSigla;
  final String awaySigla;
  final Set<int> highlightEventIndices;

  static bool _shouldShowEvent(MatchEventDetailModel e) {
    final t = e.type.trim();
    if (t.isEmpty) return false;
    final tLower = t.toLowerCase();
    if (tLower == 'kickoff' || tLower == 'halftime' || tLower == 'second half' || tLower == 'end' || tLower == 'full time') return false;
    return _kCronacaVisibleTypes.contains(t);
  }

  @override
  Widget build(BuildContext context) {
    final withIndex = <int, MatchEventDetailModel>{};
    for (var i = 0; i < events.length; i++) {
      if (_shouldShowEvent(events[i])) withIndex[i] = events[i];
    }
    if (withIndex.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cronaca', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...withIndex.entries.map((e) => _TimelineEventRow(event: e.value, highlight: highlightEventIndices.contains(e.key))),
          ],
        ),
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event, this.highlight = false});

  final MatchEventDetailModel event;
  final bool highlight;

  /// Icona per tipo evento (EN o IT).
  static String _iconFor(String type) {
    switch (type) {
      case 'Goal':
      case 'Own Goal':
      case 'Gol':
        return '⚽';
      case 'Yellow Card':
      case 'Cartellino giallo':
        return '🟨';
      case 'Red Card':
      case 'Cartellino rosso':
        return '🟥';
      case 'Substitution':
      case 'Sostituzione':
        return '🔄';
      default:
        return '•';
    }
  }

  /// Testo nome giocatore / sostituzione: "Loftus-Cheek", "Leão ↔ Pulisic".
  static String _namePart(MatchEventDetailModel e) {
    final isSub = e.type == 'Substitution' || e.type == 'Sostituzione';
    if (isSub) {
      final d = (e.detail ?? '').trim();
      if (d.contains(' → ')) return d.replaceAll(' → ', ' ↔ ');
      if (d.isNotEmpty && (e.player ?? '').trim().isNotEmpty) return '${e.player} ↔ $d';
      if (d.isNotEmpty) return d;
      return e.player ?? '';
    }
    return e.player ?? '';
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (event.type) {
      case 'Goal':
      case 'Own Goal':
      case 'Gol':
        color = Colors.green;
        break;
      case 'Yellow Card':
      case 'Cartellino giallo':
        color = Colors.amber;
        break;
      case 'Red Card':
      case 'Cartellino rosso':
        color = Colors.red;
        break;
      case 'Substitution':
      case 'Sostituzione':
        color = Colors.blue;
        break;
      default:
        color = Theme.of(context).colorScheme.onSurface;
    }
    final isHome = event.team == 'home';
    final icon = _iconFor(event.type);
    final minute = event.minuteDisplay;
    final name = _namePart(event);
    // Layout: [Spazio casa] | [linea] | [Spazio trasferta]. Per lato: minuto 50px, icona 30px, Expanded nome (maxLines 2, ellipsis).
    final eventRow = Row(
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(minute, style: TextStyle(fontSize: 12, color: color), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 4),
        SizedBox(width: 30, child: Text(icon, style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 12, color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isHome ? TextAlign.end : TextAlign.start,
          ),
        ),
      ],
    );
    final leftChild = isHome ? eventRow : const SizedBox.shrink();
    final rightChild = !isHome ? eventRow : const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.amber.withOpacity(0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftChild),
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
          Expanded(child: rightChild),
        ],
      ),
    );
  }
}

/// Statistiche: barre orizzontali (nome IT, valori casa/trasferta).
class _StatisticheSection extends StatelessWidget {
  const _StatisticheSection({required this.statistics});

  final List<StatisticsEntryModel> statistics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiche', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...statistics.map((s) => _StatBarRow(name: s.name, home: s.home, away: s.away)),
          ],
        ),
      ),
    );
  }
}

class _StatBarRow extends StatelessWidget {
  const _StatBarRow({required this.name, required this.home, required this.away});

  final String name;
  final String home;
  final String away;

  @override
  Widget build(BuildContext context) {
    double homeVal = 0.5;
    double awayVal = 0.5;
    if (name.contains('Possesso') || name.contains('%')) {
      final h = double.tryParse(home.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final a = double.tryParse(away.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final tot = h + a;
      if (tot > 0) {
        homeVal = h / tot;
        awayVal = a / tot;
      }
    } else {
      final h = double.tryParse(home) ?? 0;
      final a = double.tryParse(away) ?? 0;
      final tot = h + a;
      if (tot > 0) {
        homeVal = h / tot;
        awayVal = a / tot;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: 40, child: Text(home, textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: (homeVal * 100).round().clamp(1, 99), child: Container(height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), borderRadius: BorderRadius.circular(4)))),
                    Expanded(flex: (awayVal * 100).round().clamp(1, 99), child: Container(height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.6), borderRadius: BorderRadius.circular(4)))),
                  ],
                ),
              ),
              SizedBox(width: 40, child: Text(away, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Highlights video: tap apre video in app nativa (YouTube) o browser (ScoreBat).
class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({required this.highlights});

  final List<MatchHighlightModel> highlights;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📹 Highlights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...highlights.map((h) => _HighlightTile(highlight: h)),
          ],
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.highlight});

  final MatchHighlightModel highlight;

  Future<void> _openVideo() async {
    String url = highlight.watchUrl;
    if (url.isEmpty && highlight.videoId != null && highlight.videoId!.isNotEmpty) {
      url = 'https://www.youtube.com/watch?v=${highlight.videoId}';
    }
    if (url.isEmpty && highlight.matchviewUrl != null && highlight.matchviewUrl!.isNotEmpty) {
      url = highlight.matchviewUrl!;
    }
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = highlight.thumbnail;
    final sourceLabel = highlight.source.isNotEmpty ? highlight.source : 'Video';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _openVideo,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (thumb.isNotEmpty)
                      Image.network(
                        thumb,
                        width: 120,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800, child: const Icon(Icons.videocam, color: Colors.white54)),
                      )
                    else
                      Container(color: Colors.grey.shade800, child: const Icon(Icons.videocam, color: Colors.white54)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    highlight.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sourceLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.primary, size: 36),
          ],
        ),
      ),
    );
  }
}

/// Formazioni: due tab Casa / Trasferta.
class _FormazioniSection extends StatefulWidget {
  const _FormazioniSection({required this.lineups});

  final Map<String, TeamLineupModel> lineups;

  @override
  State<_FormazioniSection> createState() => _FormazioniSectionState();
}

class _FormazioniSectionState extends State<_FormazioniSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.lineups['home'];
    final away = widget.lineups['away'];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Formazioni', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Casa'), Tab(text: 'Trasferta')],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _LineupTab(lineup: home),
                _LineupTab(lineup: away),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupTab extends StatelessWidget {
  const _LineupTab({this.lineup});

  final TeamLineupModel? lineup;

  /// Badge colore per ruolo: POR giallo, DIF verde, CEN blu, ATT rosso, RIS grigio.
  static Color _badgeColorForPosition(String? position) {
    final p = (position ?? '').trim().toUpperCase();
    switch (p) {
      case 'POR':
        return Colors.amber.shade700;
      case 'DIF':
        return Colors.green.shade700;
      case 'CEN':
        return Colors.blue.shade700;
      case 'ATT':
        return Colors.red.shade700;
      case 'RIS':
      default:
        return Colors.grey.shade600;
    }
  }

  /// Etichetta badge: POR, DIF, CEN, ATT, o RIS per panchina.
  static String _badgeLabel(String? position, bool isSubstitute) {
    if (isSubstitute) return 'RIS';
    final p = (position ?? '').trim().toUpperCase();
    if (p == 'POR' || p == 'DIF' || p == 'CEN' || p == 'ATT' || p == 'RIS') return p;
    return 'RIS';
  }

  /// Riga: [Badge 36px] Nome Cognome
  static Widget _lineupRow(LineupPlayerModel p, bool isSubstitute, TextStyle textStyle) {
    final label = _badgeLabel(p.position, isSubstitute);
    final color = _badgeColorForPosition(isSubstitute ? 'RIS' : p.position);
    final name = p.name.trim().isNotEmpty ? p.name.trim() : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: textStyle, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lineup == null) return const Center(child: Text('—'));
    final l = lineup!;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final bodySmall = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (l.formation != null && l.formation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Modulo: ${l.formation}', style: Theme.of(context).textTheme.titleSmall),
            ),
          ...l.starting.map((p) => _lineupRow(p, false, bodyMedium)),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 6),
            child: Text('— Panchina —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          ...l.substitutes.map((p) => _lineupRow(p, true, bodySmall)),
        ],
      ),
    );
  }
}

/// Cronaca testuale: lista espandibile (ordinata per minuto desc).
class _CronacaTestualeSection extends StatefulWidget {
  const _CronacaTestualeSection({required this.commentary, this.highlightIndices = const {}});

  final List<CommentaryEntryModel> commentary;
  final Set<int> highlightIndices;

  @override
  State<_CronacaTestualeSection> createState() => _CronacaTestualeSectionState();
}

class _CronacaTestualeSectionState extends State<_CronacaTestualeSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.commentary;
    final show = _expanded ? list : list.take(5).toList();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Cronaca testuale', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          ...List.generate(show.length, (i) {
            final c = show[i];
            final highlight = widget.highlightIndices.contains(i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: highlight ? Colors.amber.withOpacity(0.35) : Colors.transparent,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 48, child: Text(c.minute, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
                  Expanded(child: Text(c.text, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            );
          }),
          if (!_expanded && list.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Altri ${list.length - 5} commenti...', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
        ],
      ),
    );
  }
}

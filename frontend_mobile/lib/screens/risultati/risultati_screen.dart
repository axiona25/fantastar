import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../services/match_service.dart';
import '../../utils/error_utils.dart';

/// Risultati giornata: partite Serie A per la giornata selezionata (GET /matches?matchday=X).
/// Dropdown parte dalla giornata corrente (/matches/current-matchday).
/// Card: data/ora in alto; [Stemma 30x30] TLA | risultato | TLA [Stemma 30x30]; TLA a 3 lettere per evitare overflow.
class RisultatiScreen extends StatefulWidget {
  const RisultatiScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<RisultatiScreen> createState() => _RisultatiScreenState();
}

class _RisultatiScreenState extends State<RisultatiScreen> {
  int _matchday = 1;
  List<MatchModel> _matches = [];
  bool _loading = false;
  bool _loadingMatchday = false;
  String? _error;

  Future<void> _loadCurrentMatchdayThenMatches() async {
    setState(() {
      _loadingMatchday = true;
      _error = null;
    });
    try {
      final current = await context.read<MatchService>().getCurrentMatchday();
      if (mounted) {
        setState(() {
          _matchday = current;
          _loadingMatchday = false;
        });
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMatchday = false;
          _error = userFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<MatchService>().getMatchesByMatchday(_matchday);
      if (mounted) {
        setState(() {
          _matches = list;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentMatchdayThenMatches());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Risultati giornata'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Giornata '),
                if (_loadingMatchday)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  DropdownButton<int>(
                    value: _matchday,
                    items: List.generate(38, (i) => i + 1)
                        .map((md) => DropdownMenuItem(value: md, child: Text('$md')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _matchday = v);
                        _load();
                      }
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _matches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _matches.isEmpty
                    ? Center(child: Text(_error!))
                    : _matches.isEmpty
                        ? const Center(child: Text('Nessun risultato per questa giornata'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _matches.length,
                            itemBuilder: (context, i) {
                              final m = _matches[i];
                              return _MatchCard(match: m);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchModel match;

  static const double _crestSize = 30.0;
  static const double _tlaMaxWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final played = match.isPlayed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (match.kickOff != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _formatKickOff(match.kickOff!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Crest(url: match.homeCrest, size: _crestSize),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: _tlaMaxWidth,
                        child: Text(
                          match.homeSigla,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: played
                      ? Text(
                          '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      : Text(
                          'Da giocare',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: _tlaMaxWidth,
                        child: Text(
                          match.awaySigla,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Crest(url: match.awayCrest, size: _crestSize),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatKickOff(DateTime d) {
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }
}

class _Crest extends StatelessWidget {
  const _Crest({this.url, this.size = 32.0});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.sports_soccer, size: size * 0.75),
      );
    }
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.sports_soccer, size: size * 0.75),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../services/match_service.dart';
import '../../services/websocket_service.dart';

/// Fantasy Matchday Live: punteggi giornata in tempo reale via WS live_scores; placeholder formazione.
class FantasyMatchdayLiveScreen extends StatefulWidget {
  const FantasyMatchdayLiveScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<FantasyMatchdayLiveScreen> createState() => _FantasyMatchdayLiveScreenState();
}

class _FantasyMatchdayLiveScreenState extends State<FantasyMatchdayLiveScreen> {
  List<Map<String, dynamic>> _updates = []; // { matchday, results: [ LiveScoreMatchResult ] }
  bool _wsConnected = false;
  final WebSocketService _ws = WebSocketService();

  void _connectWs() {
    final url = context.read<MatchService>().liveWsUrl(widget.leagueId);
    _ws.connect(url, onMessage: (data) {
      if (data is! Map || data['type'] != 'live_scores') return;
      if (!mounted) return;
      final updates = data['updates'] as List<dynamic>? ?? [];
      setState(() {
        _wsConnected = true;
        _updates = updates.map((u) => u as Map<String, dynamic>).toList();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWs());
  }

  @override
  void dispose() {
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_wsConnected)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Connessione in corso... (nessun aggiornamento dalla lega)'),
              ),
            )
          else if (_updates.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessun aggiornamento punteggi per questa giornata.'),
              ),
            )
          else
            ..._updates.map((u) {
              final matchday = u['matchday'] as int? ?? 0;
              final results = (u['results'] as List<dynamic>?) ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giornata $matchday', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...results.map((r) {
                        final res = LiveScoreMatchResult.fromJson(r as Map<String, dynamic>);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${res.homeScore.toStringAsFixed(1)} - ${res.awayScore.toStringAsFixed(1)} '
                            '(${res.homeGoals}-${res.awayGoals}) ${res.homeResult}-${res.awayResult}',
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('La mia formazione con punteggio in tempo reale (placeholder — in arrivo)'),
            ),
          ),
        ],
      ),
    );
  }
}

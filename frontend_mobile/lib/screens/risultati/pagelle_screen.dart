import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/player_rating.dart';
import '../../services/match_service.dart';
import '../../utils/error_utils.dart';

/// Pagelle partita: voti giocatori (da player_ai_ratings).
class PagelleScreen extends StatefulWidget {
  const PagelleScreen({super.key, required this.matchId});

  final int matchId;

  @override
  State<PagelleScreen> createState() => _PagelleScreenState();
}

class _PagelleScreenState extends State<PagelleScreen> {
  List<PlayerRatingModel> _ratings = [];
  bool _loading = false;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<MatchService>().getMatchRatingsAi(widget.matchId);
      if (mounted) {
        setState(() {
          _ratings = list;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _trendIcon(String trend) {
    switch (trend) {
      case 'up': return '↑';
      case 'down': return '↓';
      default: return '→';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Pagelle partita'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _ratings.isEmpty
                  ? const Center(child: Text('Nessuna pagella disponibile'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ratings.length,
                      itemBuilder: (context, i) {
                        final r = _ratings[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Text(_trendIcon(r.trend), style: const TextStyle(fontSize: 18)),
                            title: Text(r.playerName),
                            subtitle: Text('${r.mentions} menzioni · ${r.minute}\''),
                            trailing: Text(
                              r.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () => context.push('/player/${r.playerId}'),
                          ),
                        );
                      },
                    ),
    );
  }
}

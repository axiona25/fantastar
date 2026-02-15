import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/league_service.dart';
import '../../models/standing.dart';
import '../../utils/error_utils.dart';
import '../../widgets/league_logo.dart';

/// Classifica fantasy della lega: lista squadre con punti, W/D/L, differenza gol. Evidenzia la mia squadra.
class FantasyStandingsScreen extends StatefulWidget {
  const FantasyStandingsScreen({super.key});

  @override
  State<FantasyStandingsScreen> createState() => _FantasyStandingsScreenState();
}

class _FantasyStandingsScreenState extends State<FantasyStandingsScreen> {
  String? _selectedLeagueId;
  List<StandingModel> _standings = [];
  bool _loading = false;
  String? _error;

  Future<void> _loadStandings(String leagueId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<LeagueService>().getStandings(leagueId);
      if (mounted) {
        setState(() {
          _standings = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _standings = [];
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final leagues = home.leagues;
    final selectedId = _selectedLeagueId ?? (leagues.isNotEmpty ? leagues.first.id : null);
    if (selectedId != null && _standings.isEmpty && !_loading && _error == null && leagues.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadStandings(selectedId));
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Classifica Fantasy')),
      body: Column(
        children: [
          if (leagues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                items: leagues.map((l) => DropdownMenuItem(
                  value: l.id,
                  child: Row(
                    children: [
                      LeagueLogo(logoKey: l.logo, size: 32),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.displayTitle, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _selectedLeagueId = id);
                  _loadStandings(id);
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _standings.isEmpty
                        ? const Center(child: Text('Nessuna classifica per questa lega.'))
                        : RefreshIndicator(
                            onRefresh: () => selectedId != null ? _loadStandings(selectedId) : Future.value(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _standings.length,
                              itemBuilder: (context, i) {
                                final s = _standings[i];
                                final isMine = s.userId == userId;
                                return Card(
                                  color: isMine ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                                  child: ListTile(
                                    title: Text('${s.rank}. ${s.teamName}'),
                                    subtitle: Text('${s.totalPoints} pt — W${s.wins} D${s.draws} L${s.losses} — GF ${s.goalsFor} GA ${s.goalsAgainst}'),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

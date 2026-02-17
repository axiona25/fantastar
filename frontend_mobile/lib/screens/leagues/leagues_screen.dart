import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/league_service.dart';
import '../../models/fantasy_league.dart';
import '../../utils/error_utils.dart';
import '../../widgets/league_logo.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<FantasyLeagueModel> _leagues = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final list = await leagueService.getLeagues();
      setState(() {
        _leagues = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Le mie leghe')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _leagues.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Crea o unisciti a una lega per iniziare!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leagues.length,
                        itemBuilder: (context, i) {
                          final l = _leagues[i];
                          return Card(
                            child: ListTile(
                              leading: LeagueLogo(logoKey: l.logo, size: 40),
                              title: Text(l.displayTitle),
                              subtitle: Text(
                                'Squadre: ${l.teamCount ?? "?"}/${l.isPrivate ? (l.maxMembers ?? l.maxTeams) : "∞"} · Codice: ${l.inviteCode ?? "-"}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/league/${l.id}'),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/leagues/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

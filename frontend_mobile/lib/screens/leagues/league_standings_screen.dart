import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/standing.dart';
import '../../services/league_service.dart';
import '../../utils/error_utils.dart';

class LeagueStandingsScreen extends StatefulWidget {
  final String leagueId;

  const LeagueStandingsScreen({super.key, required this.leagueId});

  @override
  State<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends State<LeagueStandingsScreen> {
  List<StandingModel> _standings = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<LeagueService>().getStandings(widget.leagueId);
      setState(() {
        _standings = list;
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
    if (_loading) return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Classifica')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Classifica')), body: Center(child: Text(_error!)));
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Classifica')),
      body: ListView.builder(
        itemCount: _standings.length,
        itemBuilder: (context, i) {
          final s = _standings[i];
          return ListTile(
            leading: Text('${s.rank}'),
            title: Text(s.teamName),
            subtitle: Text('${s.totalPoints} pt · ${s.wins}V ${s.draws}P ${s.losses}S'),
          );
        },
      ),
    );
  }
}

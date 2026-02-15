import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/calendar_match.dart';
import '../../services/calendar_service.dart';
import '../../utils/error_utils.dart';

class LeagueCalendarScreen extends StatefulWidget {
  final String leagueId;

  const LeagueCalendarScreen({super.key, required this.leagueId});

  @override
  State<LeagueCalendarScreen> createState() => _LeagueCalendarScreenState();
}

class _LeagueCalendarScreenState extends State<LeagueCalendarScreen> {
  List<CalendarMatchModel> _matches = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<CalendarService>().getCalendar(widget.leagueId);
      setState(() {
        _matches = list;
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
    if (_loading) return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Calendario')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Calendario')), body: Center(child: Text(_error!)));
    final byMatchday = <int, List<CalendarMatchModel>>{};
    for (final m in _matches) {
      byMatchday.putIfAbsent(m.matchday, () => []).add(m);
    }
    final matchdays = byMatchday.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Calendario')),
      body: ListView.builder(
        itemCount: matchdays.length,
        itemBuilder: (context, i) {
          final md = matchdays[i];
          final games = byMatchday[md]!;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giornata $md', style: Theme.of(context).textTheme.titleMedium),
                  ...games.map((m) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${m.homeTeamName} – ${m.awayTeamName}'),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

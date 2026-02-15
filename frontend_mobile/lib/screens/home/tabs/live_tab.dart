import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/home_provider.dart';
import '../../../screens/home/main_shell_screen.dart';
import '../../../screens/live/fantasy_matchday_live_screen.dart';
import '../../../screens/live/live_overview_screen.dart';
import '../../../services/match_service.dart';

/// Tab Live: Partite in corso + La mia giornata.
/// Selettore giornata: [ < ] Giornata X [ > ] [📍 Oggi]. Pallino verde se giornata corrente.
/// Al ritorno sulla tab Live la giornata si resetta a quella corrente.
class LiveTab extends StatefulWidget {
  const LiveTab({super.key});

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentMatchday = 25;
  int _todayMatchday = 25;
  bool _matchdayLoaded = false;
  int? _previousShellIndex;

  Future<void> _loadCurrentMatchday() async {
    try {
      final current = await context.read<MatchService>().getCurrentMatchday();
      if (mounted) {
        setState(() {
          _todayMatchday = current.clamp(1, 38);
          if (!_matchdayLoaded) {
            _currentMatchday = _todayMatchday;
            _matchdayLoaded = true;
          }
        });
      }
    } catch (_) {}
  }

  void _goToToday() {
    setState(() => _currentMatchday = _todayMatchday);
  }

  void _prevDay() {
    setState(() => _currentMatchday = (_currentMatchday - 1).clamp(1, 38));
  }

  void _nextDay() {
    setState(() => _currentMatchday = (_currentMatchday + 1).clamp(1, 38));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentMatchday());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shellIndex = ShellIndexScope.of(context);
    if (_previousShellIndex != null &&
        _previousShellIndex != MainShellScreen.liveTabIndex &&
        shellIndex == MainShellScreen.liveTabIndex) {
      setState(() => _currentMatchday = _todayMatchday);
    }
    _previousShellIndex = shellIndex;
  }

  @override
  Widget build(BuildContext context) {
    final league = context.watch<HomeProvider>().firstLeague;
    final isToday = _currentMatchday == _todayMatchday;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Partite'),
            Tab(text: 'La mia giornata'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentMatchday > 1 ? _prevDay : null,
              ),
              GestureDetector(
                onLongPress: isToday ? null : _goToToday,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Giornata $_currentMatchday',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentMatchday < 38 ? _nextDay : null,
              ),
              if (!isToday) ...[
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Oggi'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LiveOverviewScreen(
                matchday: _currentMatchday,
                todayMatchday: _todayMatchday,
              ),
              league != null
                  ? FantasyMatchdayLiveScreen(leagueId: league.id)
                  : const Center(child: Text('Partecipa a una lega per vedere i punteggi live.')),
            ],
          ),
        ),
      ],
    );
  }
}

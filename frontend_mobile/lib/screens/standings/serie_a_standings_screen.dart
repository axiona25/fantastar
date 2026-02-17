import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/standing_row.dart';
import '../../services/stats_service.dart';
import '../../utils/error_utils.dart';
import '../../utils/team_utils.dart';

/// Classifica Serie A reale da GET /stats/standings.
class SerieAStandingsScreen extends StatefulWidget {
  const SerieAStandingsScreen({super.key});

  @override
  State<SerieAStandingsScreen> createState() => _SerieAStandingsScreenState();
}

class _SerieAStandingsScreenState extends State<SerieAStandingsScreen> {
  List<StandingRow> _rows = [];
  bool _loading = true;
  String? _error;

  static String? _resolveLogoUrl(String? crest) {
    if (crest == null || crest.isEmpty) return null;
    if (crest.startsWith('http://') || crest.startsWith('https://')) return crest;
    return '$kBackendOrigin$crest';
  }

  static String? _standingsBadgeUrl(StandingRow r) {
    final local = getTeamBadgeUrl(r.teamName);
    if (local.isNotEmpty) return local;
    return _resolveLogoUrl(r.crest);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<StatsService>().getStandings();
      if (mounted) {
        setState(() {
          _rows = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Classifica Serie A'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _rows.isEmpty
                      ? const Center(child: Text('Nessun dato classifica'))
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Table(
                            columnWidths: const {
                              0: FixedColumnWidth(32),
                              1: FixedColumnWidth(36),
                              2: FlexColumnWidth(),
                              3: FixedColumnWidth(28),
                              4: FixedColumnWidth(24),
                              5: FixedColumnWidth(24),
                              6: FixedColumnWidth(24),
                              7: FixedColumnWidth(26),
                              8: FixedColumnWidth(26),
                              9: FixedColumnWidth(32),
                            },
                            border: TableBorder.all(color: Theme.of(context).dividerColor),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                children: const [
                                  _HeaderCell('Pos'),
                                  _HeaderCell(''),
                                  _HeaderCell('Squadra'),
                                  _HeaderCell('Pts'),
                                  _HeaderCell('V'),
                                  _HeaderCell('P'),
                                  _HeaderCell('S'),
                                  _HeaderCell('GF'),
                                  _HeaderCell('GS'),
                                  _HeaderCell('Diff'),
                                ],
                              ),
                              ..._rows.map((r) => TableRow(
                                    children: [
                                      _Cell(Text('${r.position}')),
                                      _Cell(_Crest(crest: _standingsBadgeUrl(r), teamName: r.teamName)),
                                      _Cell(Text(getShortName(r.teamName), overflow: TextOverflow.ellipsis)),
                                      _Cell(Text('${r.points}')),
                                      _Cell(Text('${r.won}')),
                                      _Cell(Text('${r.draw}')),
                                      _Cell(Text('${r.lost}')),
                                      _Cell(Text('${r.goalsFor}')),
                                      _Cell(Text('${r.goalsAgainst}')),
                                      _Cell(Text(r.goalDifference >= 0 ? '+${r.goalDifference}' : '${r.goalDifference}')),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: child,
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({this.crest, this.teamName});

  final String? crest;
  final String? teamName;

  @override
  Widget build(BuildContext context) {
    final initial = (teamName != null && teamName!.isNotEmpty)
        ? getShortName(teamName!).isNotEmpty
            ? getShortName(teamName!).substring(0, 1).toUpperCase()
            : '?'
        : '?';
    if (crest == null || crest!.isEmpty) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            crest!,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

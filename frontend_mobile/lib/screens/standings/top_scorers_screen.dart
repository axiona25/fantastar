import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/stats_service.dart';
import '../../models/top_scorer.dart';
import '../../utils/error_utils.dart';

/// Classifica marcatori Serie A: top scorers con filtro per ruolo.
class TopScorersScreen extends StatefulWidget {
  const TopScorersScreen({super.key});

  @override
  State<TopScorersScreen> createState() => _TopScorersScreenState();
}

class _TopScorersScreenState extends State<TopScorersScreen> {
  List<TopScorerModel> _list = [];
  bool _loading = false;
  String? _error;
  String? _positionFilter;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<StatsService>().getTopScorers(
            limit: 20,
            position: _positionFilter?.isEmpty ?? true ? null : _positionFilter,
          );
      if (mounted) {
        setState(() {
          _list = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _list = [];
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
      appBar: AppBar(leading: const BackButton(), title: const Text('Classifica Marcatori')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Ruolo: '),
                DropdownButton<String>(
                  value: _positionFilter ?? '',
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tutti')),
                    DropdownMenuItem(value: 'POR', child: Text('POR')),
                    DropdownMenuItem(value: 'DIF', child: Text('DIF')),
                    DropdownMenuItem(value: 'CEN', child: Text('CEN')),
                    DropdownMenuItem(value: 'ATT', child: Text('ATT')),
                  ],
                  onChanged: (v) {
                    setState(() => _positionFilter = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _list.isEmpty
                        ? const Center(child: Text('Nessun dato.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _list.length,
                              itemBuilder: (context, i) {
                                final s = _list[i];
                                return ListTile(
                                  leading: CircleAvatar(child: Text('${i + 1}')),
                                  title: Text(s.name),
                                  subtitle: Text('${s.teamName ?? "—"} • ${s.position ?? ""}'),
                                  trailing: Text('${s.goals} gol', style: Theme.of(context).textTheme.titleMedium),
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

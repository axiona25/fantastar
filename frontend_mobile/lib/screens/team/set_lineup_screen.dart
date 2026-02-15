import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/team_detail.dart';
import '../../models/lineup.dart';
import '../../services/team_service.dart';
import '../../utils/error_utils.dart';

/// Imposta formazione: modulo, titolari per ruolo, panchina. UI minima (dropdown + liste).
class SetLineupScreen extends StatefulWidget {
  const SetLineupScreen({super.key, required this.teamId});

  final String teamId;

  @override
  State<SetLineupScreen> createState() => _SetLineupScreenState();
}

class _SetLineupScreenState extends State<SetLineupScreen> {
  TeamDetailModel? _team;
  int _matchday = 1;
  String _formation = '4-3-3';
  final Map<String, int?> _starterPlayerIds = {}; // positionSlot -> player_id
  List<int> _benchOrder = [];
  bool _loading = false;
  String? _error;

  /// Slots per formazione: (dif, cen, att) da kValidFormations.
  static const Map<String, List<String>> _formationSlots = {
    '3-4-3': ['POR', 'DIF1', 'DIF2', 'DIF3', 'CEN1', 'CEN2', 'CEN3', 'CEN4', 'ATT1', 'ATT2', 'ATT3'],
    '3-5-2': ['POR', 'DIF1', 'DIF2', 'DIF3', 'CEN1', 'CEN2', 'CEN3', 'CEN4', 'CEN5', 'ATT1', 'ATT2'],
    '4-3-3': ['POR', 'DIF1', 'DIF2', 'DIF3', 'DIF4', 'CEN1', 'CEN2', 'CEN3', 'ATT1', 'ATT2', 'ATT3'],
    '4-4-2': ['POR', 'DIF1', 'DIF2', 'DIF3', 'DIF4', 'CEN1', 'CEN2', 'CEN3', 'CEN4', 'ATT1', 'ATT2'],
    '4-5-1': ['POR', 'DIF1', 'DIF2', 'DIF3', 'DIF4', 'CEN1', 'CEN2', 'CEN3', 'CEN4', 'CEN5', 'ATT1'],
    '5-3-2': ['POR', 'DIF1', 'DIF2', 'DIF3', 'DIF4', 'DIF5', 'CEN1', 'CEN2', 'CEN3', 'ATT1', 'ATT2'],
    '5-4-1': ['POR', 'DIF1', 'DIF2', 'DIF3', 'DIF4', 'DIF5', 'CEN1', 'CEN2', 'CEN3', 'CEN4', 'ATT1'],
  };

  String _slotToPosition(String slot) {
    if (slot == 'POR') return 'POR';
    if (slot.startsWith('DIF')) return 'DIF';
    if (slot.startsWith('CEN')) return 'CEN';
    if (slot.startsWith('ATT')) return 'ATT';
    return 'CEN';
  }

  List<RosterPlayerModel> _playersForSlot(String slot) {
    if (_team == null) return [];
    final pos = _slotToPosition(slot);
    return _team!.roster.where((p) => (p.position.toUpperCase().length >= 3 ? p.position.toUpperCase().substring(0, 3) : p.position) == pos).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teamService = context.read<TeamService>();
      final team = await teamService.getTeam(widget.teamId);
      LineupResponseModel? lineup;
      try {
        lineup = await teamService.getLineup(widget.teamId, _matchday);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _team = team;
          _loading = false;
          _starterPlayerIds.clear();
          if (lineup != null && lineup.formation != null) {
            _formation = lineup.formation!;
            for (final s in lineup.starters) {
              _starterPlayerIds[s.positionSlot] = s.playerId;
            }
            _benchOrder = lineup.bench.map((e) => e.playerId).toList();
          }
          if (_benchOrder.isEmpty && team.roster.isNotEmpty) {
            final used = _starterPlayerIds.values.whereType<int>().toSet();
            _benchOrder = team.roster.map((e) => e.playerId).where((id) => !used.contains(id)).toList();
          }
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

  Future<void> _save() async {
    if (_team == null) return;
    final slots = <Map<String, dynamic>>[];
    final starterSlots = _formationSlots[_formation] ?? _formationSlots['4-3-3']!;
    for (var i = 0; i < starterSlots.length; i++) {
      final pid = _starterPlayerIds[starterSlots[i]];
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assegna tutti i titolari.')));
        return;
      }
      slots.add({'player_id': pid, 'position_slot': starterSlots[i], 'is_starter': true, 'bench_order': null});
    }
    for (var i = 0; i < _benchOrder.length; i++) {
      slots.add({'player_id': _benchOrder[i], 'position_slot': 'B${i + 1}', 'is_starter': false, 'bench_order': i});
    }
    setState(() => _loading = true);
    try {
      await context.read<TeamService>().setLineup(widget.teamId, _matchday, _formation, slots);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formazione salvata.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _team == null) {
      return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Formazione')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _team == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Formazione')),
        body: Center(child: Text(_error!)),
      );
    }
    final team = _team;
    if (team == null) return const SizedBox.shrink();

    final starterSlots = _formationSlots[_formation] ?? _formationSlots['4-3-3']!;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Imposta formazione')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Giornata: '),
                DropdownButton<int>(
                  value: _matchday,
                  items: List.generate(38, (i) => i + 1).map((md) => DropdownMenuItem(value: md, child: Text('$md'))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _matchday = v);
                    _load();
                  },
                ),
                const SizedBox(width: 16),
                const Text('Modulo: '),
                DropdownButton<String>(
                  value: _formation,
                  items: kValidFormations.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _formation = v);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Titolari', style: TextStyle(fontWeight: FontWeight.bold)),
                ...starterSlots.map((slot) {
                  final players = _playersForSlot(slot);
                  final currentId = _starterPlayerIds[slot];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 48, child: Text(slot)),
                        Expanded(
                          child: DropdownButton<int>(
                            value: currentId,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('—')),
                              ...players.map((p) => DropdownMenuItem(value: p.playerId, child: Text(p.playerName))),
                            ],
                            onChanged: (id) {
                              setState(() {
                                _starterPlayerIds[slot] = id;
                                final used = _starterPlayerIds.values.whereType<int>().toSet();
                                _benchOrder = team.roster.map((p) => p.playerId).where((pid) => !used.contains(pid)).toList();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('Panchina (ordine subentri)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('(Ordine attuale: primi in lista = primi a subentrare)', style: TextStyle(fontSize: 12)),
                ..._benchOrder.asMap().entries.map((e) {
                  final name = team.roster.where((p) => p.playerId == e.value).map((p) => p.playerName).firstOrNull ?? '?';
                  return ListTile(dense: true, title: Text('${e.key + 1}. $name'));
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Conferma formazione'),
            ),
          ),
        ],
      ),
    );
  }
}

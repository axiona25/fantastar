import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player_list_item.dart';
import '../../widgets/player_avatar.dart';
import '../../models/team_detail.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/market_service.dart';
import '../../services/team_service.dart';
import '../../utils/error_utils.dart';

/// Mercato: svincolati (acquista), mia rosa (rilascia), scambi (proponi/rispondi).
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlayerListItemModel> _freeAgents = [];
  List<Map<String, dynamic>> _marketTeams = [];
  TeamDetailModel? _myTeam;
  Map<String, dynamic> _trades = {'sent': [], 'received': []};
  bool _loading = false;
  String? _error;
  // Filtri tab Svincolati
  String? _roleFilter;
  int? _teamFilter;
  final TextEditingController _searchController = TextEditingController();
  static const _roleOptions = ['Tutti', 'POR', 'DIF', 'CEN', 'ATT'];

  Future<void> _loadMarketTeams() async {
    try {
      final list = await context.read<MarketService>().getMarketTeams(widget.leagueId);
      if (mounted) setState(() => _marketTeams = list);
    } catch (_) {}
  }

  Future<void> _loadFreeAgents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = (_roleFilter != null && _roleFilter!.isNotEmpty && _roleFilter != 'Tutti') ? _roleFilter : null;
      final search = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
      final r = await context.read<MarketService>().getFreeAgents(
        widget.leagueId,
        role: role,
        teamId: _teamFilter,
        search: search,
      );
      if (mounted) {
        setState(() {
          _freeAgents = r.players;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = userFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _loadMyTeam() async {
    final userId = context.read<AuthProvider>().user?.id;
    final myStanding = context.read<HomeProvider>().myStandingFor(userId);
    final teamId = myStanding?.fantasyTeamId;
    if (teamId == null) {
      setState(() => _myTeam = null);
      return;
    }
    try {
      final t = await context.read<TeamService>().getTeam(teamId);
      if (mounted) setState(() => _myTeam = t);
    } catch (_) {}
  }

  Future<void> _loadTrades() async {
    try {
      final r = await context.read<MarketService>().getTrades(widget.leagueId);
      if (mounted) setState(() => _trades = r);
    } catch (_) {}
  }

  Future<void> _loadAll() async {
    await context.read<HomeProvider>().load();
    if (!mounted) return;
    _loadMarketTeams();
    _loadFreeAgents();
    _loadTrades();
    _loadMyTeam();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Mercato'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Svincolati'),
            Tab(text: 'Rilascia'),
            Tab(text: 'Scambi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFreeAgentsTab(),
          _myTeam == null
              ? const Center(child: Text('Nessuna squadra in questa lega.'))
              : ListView.builder(
                  itemCount: _myTeam!.roster.length,
                  itemBuilder: (context, i) {
                    final r = _myTeam!.roster[i];
                    return ListTile(
                      title: Text(r.playerName),
                      subtitle: Text('${r.position} • acquisto ${r.purchasePrice?.toStringAsFixed(0) ?? "—"}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await context.read<MarketService>().release(widget.leagueId, r.playerId);
                            if (mounted) {
                              messenger.showSnackBar(const SnackBar(content: Text('Rilasciato (50% rimborso)')));
                              _loadMyTeam();
                              _loadFreeAgents();
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Rilascia'),
                      ),
                    );
                  },
                ),
          _buildTradesTab(),
        ],
      ),
    );
  }

  Widget _buildFreeAgentsTab() {
    final home = context.watch<HomeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtri: Ruolo, Squadra, Cerca
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _roleFilter ?? 'Tutti',
                      decoration: const InputDecoration(
                        labelText: 'Ruolo',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _roleFilter = (v == 'Tutti') ? null : v;
                          _loadFreeAgents();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _teamFilter,
                      decoration: const InputDecoration(
                        labelText: 'Squadra',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Tutti')),
                        ..._marketTeams.map((t) {
                          final short = t['short_name'] as String?;
                          final name = t['name'] as String? ?? '';
                          return DropdownMenuItem<int?>(
                            value: (t['id'] as num?)?.toInt(),
                            child: Text((short != null && short.isNotEmpty) ? short : name, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _teamFilter = v;
                          _loadFreeAgents();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca giocatore',
                  hintText: 'Nome...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _loadFreeAgents(),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _loadFreeAgents(),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Applica filtri'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _freeAgents.isEmpty
                      ? const Center(child: Text('Nessun svincolato con questi filtri.'))
                      : ListView.builder(
                          itemCount: _freeAgents.length,
                          itemBuilder: (context, i) {
                            final p = _freeAgents[i];
                            return _FreeAgentRow(
                              player: p,
                              onAcquista: () => _onAcquista(p, home),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showNoLeagueDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nessuna lega'),
        content: const Text(
          'Devi prima creare o unirti a una lega dalla tab Squadra',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _onAcquista(PlayerListItemModel player, HomeProvider home) async {
    if (home.leagues.isEmpty) {
      _showNoLeagueDialog();
      return;
    }
    final price = player.initialPrice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma acquisto'),
        content: Text('Acquistare ${player.name} per ${price.toStringAsFixed(0)} crediti?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Conferma')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MarketService>().buy(widget.leagueId, player.id, price: price);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Giocatore acquistato!')));
        setState(() => _freeAgents = _freeAgents.where((p) => p.id != player.id).toList());
        _loadMyTeam();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTradesTab() {
    final sent = _trades['sent'] as List<dynamic>? ?? [];
    final received = _trades['received'] as List<dynamic>? ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Inviate', style: TextStyle(fontWeight: FontWeight.bold)),
        ...sent.map((t) => ListTile(
              dense: true,
              title: Text('A squadra: ${t['to_team_id']}'),
              subtitle: Text('Status: ${t['status']}'),
            )),
        const SizedBox(height: 16),
        const Text('Ricevute', style: TextStyle(fontWeight: FontWeight.bold)),
        ...received.map((t) => ListTile(
              dense: true,
              title: Text('Da: ${t['from_team_id']}'),
              subtitle: Text('Status: ${t['status']}'),
              trailing: (t['status'] == 'PENDING')
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => _respondTrade(t['id'], true), child: const Text('Accetta')),
                        TextButton(onPressed: () => _respondTrade(t['id'], false), child: const Text('Rifiuta')),
                      ],
                    )
                  : null,
            )),
        const SizedBox(height: 16),
        const Text('(Proponi scambio: da implementare con selezione squadra e giocatori)', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _respondTrade(int tradeId, bool accept) async {
    try {
      await context.read<MarketService>().tradeRespond(widget.leagueId, tradeId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? 'Scambio accettato' : 'Scambio rifiutato')));
        _loadTrades();
        _loadMyTeam();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Riga svincolato: [Foto] Nome · Ruolo · Squadra, badge prezzo (cr), pulsante Acquista.
class _FreeAgentRow extends StatelessWidget {
  const _FreeAgentRow({required this.player, required this.onAcquista});

  final PlayerListItemModel player;
  final VoidCallback onAcquista;

  @override
  Widget build(BuildContext context) {
    final priceCr = player.initialPrice.toInt();
    final priceLabel = priceCr == player.initialPrice ? '$priceCr cr' : '${player.initialPrice.toStringAsFixed(1)} cr';
    return ListTile(
      leading: PlayerAvatar(
        playerId: player.id,
        role: player.position,
        playerName: player.name,
        teamColor: getTeamColor(player.realTeamName),
        size: 40,
      ),
      title: Text(player.name),
      subtitle: Text('${player.position} · ${player.realTeamName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 1, offset: const Offset(0, 1))],
            ),
            child: Text(
              priceLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAcquista,
            child: const Text('Acquista'),
          ),
        ],
      ),
    );
  }
}

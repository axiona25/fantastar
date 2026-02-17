import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/player_avatar.dart';
import '../../../providers/home_provider.dart';
import '../../../services/team_service.dart';
import '../../../services/market_service.dart';
import '../../../services/league_service.dart';
import '../../../models/team_detail.dart';
import '../../../utils/error_utils.dart';
import '../../../widgets/league_logo.dart';

/// Tab Squadra: nessuna lega → Crea/Unisciti; rosa vuota → Asta/Mercato; con giocatori → formazione + lista.
class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  TeamDetailModel? _team;
  bool _loading = false;
  String? _error;

  Future<void> _loadTeam() async {
    final home = context.read<HomeProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    if (home.leagues.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => home.load());
      return;
    }
    final myStanding = home.myStandingFor(userId);
    final teamId = myStanding?.fantasyTeamId;
    if (teamId == null) {
      setState(() {
        _team = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await context.read<TeamService>().getTeam(teamId);
      if (mounted) {
        setState(() {
          _team = t;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _team = null;
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

  static const _roleOrder = ['POR', 'DIF', 'CEN', 'ATT'];
  static const _formationCount = {'POR': 1, 'DIF': 4, 'CEN': 4, 'ATT': 2};

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final myStanding = home.myStandingFor(userId);
    final teamId = myStanding?.fantasyTeamId;

    if (teamId != null && _team == null && !_loading && _error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeam());
    }

    // 1) Non sei in nessuna lega
    if (home.leagues.isEmpty && !home.loading) {
      return _NoLeagueContent();
    }

    // In lega ma nessuna squadra (non in classifica = non hai creato la squadra)
    if (myStanding == null && home.leagues.isNotEmpty) {
      final league = home.firstLeague!;
      return _NoTeamContent(leagueName: league.displayTitle, leagueId: league.id, logoKey: league.logo);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadTeam, child: const Text('Ricarica')),
          ],
        ),
      );
    }
    if (_team == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nessuna squadra caricata.'),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadTeam, child: const Text('Ricarica')),
          ],
        ),
      );
    }

    final team = _team!;
    String leagueName = team.name;
    String? inviteCode;
    String logoKey = 'trophy';
    for (final l in home.leagues) {
      if (l.id == team.leagueId) {
        leagueName = l.displayTitle;
        inviteCode = l.inviteCode;
        logoKey = l.logo;
        break;
      }
    }

    // 2) In lega, hai squadra ma rosa vuota
    if (team.roster.isEmpty) {
      return _EmptyRosterContent(
        leagueName: leagueName,
        logoKey: logoKey,
        inviteCode: inviteCode ?? '',
        budgetRemaining: team.budgetRemaining,
        rosterCount: 0,
        leagueId: team.leagueId,
        onRefresh: _loadTeam,
      );
    }

    // 3) Rosa con giocatori: lista per ruolo, swipe Rilascia, Vai al mercato, Imposta formazione
    return _RosterContent(
      leagueName: leagueName,
      logoKey: logoKey,
      inviteCode: inviteCode ?? '',
      team: team,
      leagueId: team.leagueId,
      onRefresh: _loadTeam,
      onRelease: (int playerId) async {
        try {
          await context.read<MarketService>().release(team.leagueId, playerId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rilasciato (50% rimborso)')));
            _loadTeam();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
  }
}

/// Messaggio e pulsanti quando l'utente non è in nessuna lega.
class _NoLeagueContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Benvenuto in FANTASTAR!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Per iniziare, crea una nuova lega o unisciti a una lega esistente',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateLeagueDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crea una lega'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showJoinWithCodeDialog(context),
              icon: const Icon(Icons.group_add),
              label: const Text('Unisciti con codice'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showCreateLeagueDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Crea una lega'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome lega',
              border: OutlineInputBorder(),
              hintText: 'Es. Lega Amici',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            onSubmitted: (_) {
              final n = nameController.text.trim();
              Navigator.of(ctx).pop(n.isEmpty ? null : n);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                final n = nameController.text.trim();
                Navigator.of(ctx).pop(n.isEmpty ? null : n);
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final home = context.read<HomeProvider>();
    try {
      final leagueService = context.read<LeagueService>();
      await leagueService.createLeague(name: name, leagueType: 'private', maxMembers: 8, budget: 500);
      if (context.mounted) {
        await home.load();
        messenger.showSnackBar(const SnackBar(content: Text('Lega creata!')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
      }
    }
  }

  static Future<void> _showJoinWithCodeDialog(BuildContext context) async {
    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unisciti con codice'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Codice invito',
              border: OutlineInputBorder(),
              hintText: 'XXXXXXXX',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            onSubmitted: (_) {
              final c = codeController.text.trim().toUpperCase();
              Navigator.of(ctx).pop(c.length == 8 ? c : null);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                final c = codeController.text.trim().toUpperCase();
                Navigator.of(ctx).pop(c.length == 8 ? c : null);
              },
              child: const Text('Unisciti'),
            ),
          ],
        );
      },
    );
    if (code == null || code.length != 8 || !context.mounted) {
      if (context.mounted && code != null && code.isNotEmpty && code.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il codice deve essere di 8 caratteri')),
        );
      }
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final home = context.read<HomeProvider>();
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.lookupByInviteCode(code);
      await leagueService.joinLeague(league.id, code);
      if (context.mounted) {
        await home.load();
        messenger.showSnackBar(const SnackBar(content: Text('Ti sei unito alla lega!')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(userFriendlyErrorMessage(e))));
      }
    }
  }
}

/// In lega ma non hai ancora creato la squadra.
class _NoTeamContent extends StatelessWidget {
  const _NoTeamContent({required this.leagueName, required this.leagueId, required this.logoKey});

  final String leagueName;
  final String leagueId;
  final String logoKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                LeagueLogo(logoKey: logoKey, size: 40),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    leagueName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Crea la tua squadra per partecipare.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/league/$leagueId/create-team'),
              icon: const Icon(Icons.add),
              label: const Text('Crea la mia squadra'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header con nome lega, codice invito (copia), budget e rosa.
Widget _buildLeagueHeader(
  BuildContext context, {
  required String leagueName,
  required String logoKey,
  required String inviteCode,
  required double budgetRemaining,
  required int rosterCount,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            LeagueLogo(logoKey: logoKey, size: 40),
            const SizedBox(width: 8),
            Expanded(child: Text(leagueName, style: Theme.of(context).textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 8),
        if (inviteCode.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Codice invito: ', style: Theme.of(context).textTheme.bodyMedium),
                SelectableText(inviteCode, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copia',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice copiato')));
                  },
                ),
              ],
            ),
          ),
        Text(
          'Budget: ${budgetRemaining.toStringAsFixed(0)} cr  |  Rosa: $rosterCount/$_kMaxRoster',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

const int _kMaxRoster = 25;

/// Genera deep link e messaggio invito; apre WhatsApp se disponibile, altrimenti share generico.
Future<void> _shareInvite(
  BuildContext context, {
  required String leagueName,
  required String inviteCode,
}) async {
  const baseUrl = 'https://fantastar.app';
  final joinUrl = '$baseUrl/join/$inviteCode';
  final message = '🏆 Ti invito nella mia lega FANTASTAR!\n\n'
      'Lega: $leagueName\n'
      'Codice: $inviteCode\n\n'
      'Unisciti qui: $joinUrl\n\n'
      'Scarica l\'app: $baseUrl/download';
  try {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  if (context.mounted) {
    await Share.share(message, subject: 'Invito lega FANTASTAR');
  }
}

/// Rosa vuota: header, LA MIA ROSA, messaggio, Vai all'asta, Vai al mercato, Invita amici.
class _EmptyRosterContent extends StatelessWidget {
  const _EmptyRosterContent({
    required this.leagueName,
    required this.logoKey,
    required this.inviteCode,
    required this.budgetRemaining,
    required this.rosterCount,
    required this.leagueId,
    required this.onRefresh,
  });

  final String leagueName;
  final String logoKey;
  final String inviteCode;
  final double budgetRemaining;
  final int rosterCount;
  final String leagueId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLeagueHeader(
            context,
            leagueName: leagueName,
            logoKey: logoKey,
            inviteCode: inviteCode,
            budgetRemaining: budgetRemaining,
            rosterCount: rosterCount,
          ),
          const SizedBox(height: 24),
          Text('LA MIA ROSA', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const Text(
            'Non hai ancora giocatori. Vai all\'asta o al mercato!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/league/$leagueId/auction');
              if (context.mounted) onRefresh();
            },
            icon: const Icon(Icons.gavel),
            label: const Text('Vai all\'Asta'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/league/$leagueId/market'),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Vai al Mercato'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _shareInvite(context, leagueName: leagueName, inviteCode: inviteCode),
            icon: const Icon(Icons.share),
            label: const Text('Invita amici'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ],
      ),
    );
  }
}

/// Limiti rosa (allineati al backend).
const Map<String, int> _kRoleLimits = {'POR': 3, 'DIF': 8, 'CEN': 8, 'ATT': 6};
const Map<String, String> _kRoleLabels = {'POR': 'PORTIERI', 'DIF': 'DIFENSORI', 'CEN': 'CENTROCAMPISTI', 'ATT': 'ATTACCANTI'};
const Map<String, String> _kRoleEmoji = {'POR': '🟡', 'DIF': '🟢', 'CEN': '🔵', 'ATT': '🔴'};

/// Rosa con giocatori: header con codice invito, sezioni per ruolo, Vai al mercato, Imposta formazione, Invita amici.
class _RosterContent extends StatelessWidget {
  const _RosterContent({
    required this.leagueName,
    required this.logoKey,
    required this.inviteCode,
    required this.team,
    required this.leagueId,
    required this.onRefresh,
    required this.onRelease,
  });

  final String leagueName;
  final String logoKey;
  final String inviteCode;
  final TeamDetailModel team;
  final String leagueId;
  final VoidCallback onRefresh;
  final Future<void> Function(int playerId) onRelease;

  static const _roleOrder = ['POR', 'DIF', 'CEN', 'ATT'];

  List<RosterPlayerModel> _byRole(String role) {
    final prefix = role.length >= 3 ? role.substring(0, 3) : role;
    return team.roster
        .where((p) => p.position.length >= 3 && p.position.toUpperCase().substring(0, 3) == prefix)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final byRole = {for (final r in _roleOrder) r: _byRole(r)};
    final count = team.roster.length;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLeagueHeader(
            context,
            leagueName: leagueName,
            logoKey: logoKey,
            inviteCode: inviteCode,
            budgetRemaining: team.budgetRemaining,
            rosterCount: count,
          ),
          const SizedBox(height: 20),

          // Sezioni per ruolo: 🟡 PORTIERI (1/3), ...
          ..._roleOrder.map((role) {
            final players = byRole[role] ?? [];
            final limit = _kRoleLimits[role] ?? 8;
            final label = _kRoleLabels[role] ?? role;
            final emoji = _kRoleEmoji[role] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $label (${players.length}/$limit)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ...players.map((p) => _RosterPlayerTile(
                      player: p,
                      onTap: () => context.push('/player/${p.playerId}'),
                      onRelease: () async => onRelease(p.playerId),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }),

          const Divider(height: 32),
          // 1. Asta - prima azione, ben visibile
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.deepOrange, size: 28),
            title: const Text(
              'Asta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepOrange,
              ),
            ),
            subtitle: const Text('Avvia o partecipa all\'asta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push('/league/$leagueId/auction');
              if (context.mounted) onRefresh();
            },
          ),
          const Divider(),
          // 2. Vai al mercato
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Vai al mercato'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/league/$leagueId/market'),
          ),
          // 3. Imposta formazione
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Imposta formazione'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/team/${team.id}/lineup'),
          ),
          // 4. Invita amici
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Invita amici'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _shareInvite(context, leagueName: leagueName, inviteCode: inviteCode),
          ),
        ],
      ),
    );
  }
}

/// Riga giocatore in rosa: [Foto] Nome - Squadra - X cr, swipe per Rilascia.
class _RosterPlayerTile extends StatelessWidget {
  const _RosterPlayerTile({
    required this.player,
    required this.onTap,
    required this.onRelease,
  });

  final RosterPlayerModel player;
  final VoidCallback onTap;
  final Future<void> Function() onRelease;

  @override
  Widget build(BuildContext context) {
    final teamName = player.realTeamName ?? '—';
    final priceStr = player.purchasePrice != null ? '${player.purchasePrice!.toStringAsFixed(0)} cr' : '—';
    return Dismissible(
      key: ValueKey<int>(player.playerId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Text('Rilascia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      confirmDismiss: (direction) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rilascia giocatore'),
            content: Text('Rilasciare ${player.playerName}? Rimborso 50% del prezzo di acquisto.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Rilascia')),
            ],
          ),
        );
        if (ok == true) {
          await onRelease();
        }
        return ok == true;
      },
      child: ListTile(
        leading: PlayerAvatar(
          playerId: player.playerId,
          role: player.position,
          playerName: player.playerName,
          teamColor: getTeamColor(player.realTeamName),
          size: 40,
        ),
        title: Text(player.playerName),
        subtitle: Text('$teamName - $priceStr'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Griglia formazione: POR (1), DIF (4), CEN (4), ATT (2).
class _FormationGrid extends StatelessWidget {
  const _FormationGrid({required this.byRole});

  final Map<String, List<RosterPlayerModel>> byRole;

  static const _roleOrder = ['POR', 'DIF', 'CEN', 'ATT'];
  static const _counts = [1, 4, 4, 2];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            for (var i = 0; i < _roleOrder.length; i++) ...[
              _FormationRow(
                role: _roleOrder[i],
                count: _counts[i],
                players: byRole[_roleOrder[i]] ?? [],
              ),
              if (i < _roleOrder.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormationRow extends StatelessWidget {
  const _FormationRow({
    required this.role,
    required this.count,
    required this.players,
  });

  final String role;
  final int count;
  final List<RosterPlayerModel> players;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 36,
          child: Text(role, style: Theme.of(context).textTheme.labelSmall),
        ),
        ...List.generate(count, (i) {
          final p = i < players.length ? players[i] : null;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: p != null
                  ? Tooltip(
                      message: p.playerName,
                      child: PlayerAvatar(
                        playerId: p.playerId,
                        role: p.position,
                        playerName: p.playerName,
                        teamColor: getTeamColor(p.realTeamName),
                        size: 36,
                      ),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text('—', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                    ),
            ),
          );
        }),
      ],
    );
  }
}

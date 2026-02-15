import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/fantasy_league.dart';
import '../../models/league_member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/league_service.dart';
import '../../utils/error_utils.dart';
import '../../widgets/league_logo.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  FantasyLeagueModel? _league;
  List<LeagueMemberModel> _members = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.getLeague(widget.leagueId);
      final members = await leagueService.getLeagueMembers(widget.leagueId);
      if (mounted) {
        setState(() {
          _league = league;
          _members = members;
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

  Future<void> _removeMember(LeagueMemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi membro'),
        content: Text(
          'Sei sicuro di voler rimuovere ${member.name} dalla lega? I suoi giocatori torneranno disponibili.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<LeagueService>().removeLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente rimosso')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockMember(LeagueMemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blocca membro'),
        content: const Text(
          'Bloccare questo utente? Non potrà più rientrare nella lega.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Blocca')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<LeagueService>().blockLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente bloccato')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockMember(LeagueMemberModel member) async {
    try {
      await context.read<LeagueService>().unblockLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente sbloccato')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteLeague() async {
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final name = _league?.name ?? 'questa lega';
        return AlertDialog(
          title: const Text('Elimina lega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai per eliminare la lega $name.\n\nQuesta azione è IRREVERSIBILE.\nScrivi ELIMINA per confermare.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Scrivi ELIMINA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (confirmController.text.trim().toUpperCase() == 'ELIMINA') {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<LeagueService>().deleteLeague(widget.leagueId);
      if (mounted) {
        context.read<HomeProvider>().load();
        context.go('/team');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lega eliminata')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _league == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Gestisci lega')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _league == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Gestisci lega')),
        body: Center(child: Text(_error!)),
      );
    }
    final league = _league!;
    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider>().user?.id?.toString();

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Gestisci lega')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                LeagueLogo(logoKey: league.logo, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(league.displayTitle, style: theme.textTheme.headlineSmall)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: ${league.isPrivate ? "🔒 Privata" : "🌍 Pubblica"} (${league.isPrivate ? (league.maxMembers ?? league.maxTeams) : "∞"} max)'),
                    Text('Membri: ${league.teamCount ?? "?"}/${league.isPrivate ? (league.maxMembers ?? league.maxTeams) : "∞"}'),
                    Text('Codice invito: ${league.inviteCode ?? "-"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Membri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._members.map((m) {
              final isMe = m.userId == currentUserId;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(m.isAdmin ? Icons.admin_panel_settings : Icons.person, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.name}${m.isAdmin ? " (Admin)" : ""}${m.isBlocked ? " (Bloccato)" : ""}${m.isKicked ? " (Rimosso)" : ""}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (!m.isBlocked && !m.isKicked)
                                  Text('${m.budget.toInt()} cr | ${m.rosterCount}/25 rosa', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!m.isAdmin && !isMe && m.status == 'active') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.person_remove, size: 18),
                              label: const Text('Rimuovi'),
                              onPressed: () => _removeMember(m),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Blocca'),
                              onPressed: () => _blockMember(m),
                            ),
                          ],
                        ),
                      ],
                      if (!m.isAdmin && !isMe && m.isBlocked) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Sblocca'),
                          onPressed: () => _unblockMember(m),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            const Text('Zona pericolosa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Elimina lega'),
                subtitle: const Text('Questa azione è irreversibile'),
                onTap: _deleteLeague,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

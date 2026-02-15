import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/fantasy_league.dart';
import '../../models/standing.dart';
import '../../providers/auth_provider.dart';
import '../../services/league_service.dart';
import '../../utils/error_utils.dart';
import '../../widgets/league_logo.dart';

class LeagueDetailScreen extends StatefulWidget {
  final String leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  FantasyLeagueModel? _league;
  List<StandingModel> _standings = [];
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
      final standings = await leagueService.getStandings(widget.leagueId);
      setState(() {
        _league = league;
        _standings = standings;
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

  void _copyInviteCode() {
    final code = _league?.inviteCode;
    if (code != null && code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice copiato')));
    }
  }

  void _shareInvite() {
    final code = _league?.inviteCode ?? '';
    Share.share('Unisciti alla mia lega FANTASTAR! Usa il codice: $code');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(leading: const BackButton(), title: const Text('Dettaglio lega')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _league == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Dettaglio lega')),
        body: Center(child: Text(_error ?? 'Lega non trovata')),
      );
    }
    final league = _league!;
    final user = context.watch<AuthProvider>().user;
    final myStanding = user != null ? _standings.cast<StandingModel?>().firstWhere((s) => s?.userId == user.id, orElse: () => null) : null;
    final isAdmin = league.isAdminFor(user?.id);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LeagueLogo(logoKey: league.logo, size: 40),
            const SizedBox(width: 8),
            Flexible(child: Text(league.displayTitle, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'manage') context.push('/league/${widget.leagueId}/management');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'manage', child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Gestisci lega')])),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Codice invito: ${league.inviteCode ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyInviteCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    league.isPrivate
                        ? 'Squadre: ${league.teamCount ?? "?"}/${league.maxMembers ?? league.maxTeams} · Budget: ${league.budget.toInt()} cr'
                        : 'Squadre: ${league.teamCount ?? "?"} (illimitato) · Budget: ${league.budget.toInt()} cr',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (myStanding == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crea la mia squadra'),
                onPressed: () => context.push('/league/${widget.leagueId}/create-team'),
              ),
            ),
          const Text('Squadre iscritte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ..._standings.map((s) => ListTile(
                title: Text(s.teamName),
                subtitle: Text('${s.totalPoints} pt · ${s.wins}V ${s.draws}P ${s.losses}S'),
              )),
          const SizedBox(height: 16),
          const Text('Azioni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Classifica'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/league/${widget.leagueId}/standings'),
          ),
          if (league.isPrivate)
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Asta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/league/${widget.leagueId}/auction'),
            ),
          if (league.isPublic)
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Mercato'),
              subtitle: const Text('Acquisto libero dal listone'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/league/${widget.leagueId}/market'),
            ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Risultati'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/league/${widget.leagueId}/risultati'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Calendario'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/league/${widget.leagueId}/calendar'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Invita amici'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _shareInvite,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Genera calendario'),
              onPressed: () async {
                try {
                  await context.read<LeagueService>().generateCalendar(widget.leagueId);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calendario generato')));
                  _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

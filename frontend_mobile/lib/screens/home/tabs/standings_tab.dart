import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/home_provider.dart';

/// Tab Classifica: link a Classifica Serie A, Classifica Fantasy, Marcatori, Risultati.
class StandingsTab extends StatelessWidget {
  const StandingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final league = context.watch<HomeProvider>().firstLeague;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Classifica Serie A'),
          subtitle: const Text('20 squadre con posizione, punti, W/D/L'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/standings/serie-a'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Classifica Fantasy'),
          subtitle: const Text('Squadre della lega con punti e differenza gol'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/standings/fantasy'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Classifica Marcatori'),
          subtitle: const Text('Top marcatori Serie A con filtro per ruolo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/standings/scorers'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Risultati giornata'),
          subtitle: const Text('Risultati partite fantasy per giornata'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (league != null) {
              context.push('/league/${league.id}/risultati');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partecipa a una lega')));
            }
          },
        ),
      ],
    );
  }
}

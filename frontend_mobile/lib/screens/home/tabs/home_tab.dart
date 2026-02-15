import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/news.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../services/news_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<NewsModel> _newsPreview = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
      _loadNews();
    });
  }

  Future<void> _loadNews() async {
    try {
      final list = await context.read<NewsService>().getNews(limit: 3);
      if (mounted) setState(() => _newsPreview = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final home = context.watch<HomeProvider>();
    final myStanding = home.myStandingFor(user?.id);

    return RefreshIndicator(
      onRefresh: () => home.load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text('Benvenuto, ${user?.displayName ?? "..."}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Card Le mie leghe
            Card(
              child: ListTile(
                title: const Text('Le mie leghe'),
                subtitle: const Text('Crea o unisciti a una lega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/leagues'),
              ),
            ),
            const SizedBox(height: 12),
            // Card Prossima giornata (placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prossima giornata', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Giornata 15 — Inizio tra X giorni (placeholder)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Card La mia squadra
            Card(
              child: ListTile(
                title: const Text('La mia squadra'),
                subtitle: home.loading
                    ? null
                    : home.error != null
                        ? Text(home.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                        : myStanding != null
                            ? Text('${myStanding.teamName} — ${myStanding.totalPoints} pt')
                            : const Text('Crea o unisciti a una lega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (myStanding != null) {
                    context.push('/league/${home.firstLeague?.id}');
                  } else {
                    context.push('/leagues');
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // Card Classifica fantasy top 3
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classifica fantasy (top 3)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (home.loading)
                      const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    else if (home.topThree.isEmpty)
                      const Text('Nessuna classifica disponibile.')
                    else
                      ...home.topThree.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('${s.rank}. ${s.teamName} — ${s.totalPoints} pt (W${s.wins} D${s.draws} L${s.losses})'),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Ultime news
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ultime news', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_newsPreview.isEmpty)
                      const Text('Nessuna news.')
                    else
                      ..._newsPreview.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Partite live (placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partite live', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('(Nessuna partita in corso — placeholder)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Listone
            Card(
              child: ListTile(
                title: const Text('Listone'),
                subtitle: const Text('Tutti i giocatori Serie A'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/players'),
              ),
            ),
            const SizedBox(height: 12),
            // Asta & Mercato
            if (home.firstLeague != null) ...[
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Asta'),
                      subtitle: const Text('Asta live, offerte in tempo reale'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/league/${home.firstLeague!.id}/auction'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Mercato'),
                      subtitle: const Text('Svincolati, acquista, rilascia, scambi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/league/${home.firstLeague!.id}/market'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

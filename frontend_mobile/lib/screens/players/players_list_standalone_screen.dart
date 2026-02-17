import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/player_list_item.dart';
import '../../services/player_service.dart';
import '../../widgets/player_list_tile.dart';

/// Listone globale (route /players) — filtri e tap su giocatore.
class PlayersListStandaloneScreen extends StatefulWidget {
  const PlayersListStandaloneScreen({super.key});

  @override
  State<PlayersListStandaloneScreen> createState() => _PlayersListStandaloneScreenState();
}

class _PlayersListStandaloneScreenState extends State<PlayersListStandaloneScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PlayerListItemModel> _players = [];
  int _total = 0;
  int _currentPage = 1;
  bool _loading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _position;
  String _search = '';
  String _sortBy = 'initial_price';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
      _players = [];
      _hasMore = true;
    });
    try {
      final result = await context.read<PlayerService>().getPlayers(
            position: _position,
            search: _search.isEmpty ? null : _search,
            sortBy: _sortBy,
            sortOrder: _sortBy == 'initial_price' ? 'desc' : 'asc',
            page: 1,
          );
      if (mounted) {
        setState(() {
          _players = result.players;
          _total = result.total;
          _hasMore = 1 < result.totalPages;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    try {
      final result = await context.read<PlayerService>().getPlayers(
            position: _position,
            search: _search.isEmpty ? null : _search,
            sortBy: _sortBy,
            sortOrder: _sortBy == 'initial_price' ? 'desc' : 'asc',
            page: nextPage,
          );
      if (mounted) {
        setState(() {
          _players.addAll(result.players);
          _currentPage = nextPage;
          _hasMore = nextPage < result.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200 && !_isLoadingMore && _hasMore && !_loading) {
        _loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Listone ($_total)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Cerca', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (v) {
                      setState(() => _search = v);
                      _load();
                    },
                  ),
                ),
                DropdownButton<String?>(
                  value: _position,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tutti')),
                    DropdownMenuItem(value: 'POR', child: Text('POR')),
                    DropdownMenuItem(value: 'DIF', child: Text('DIF')),
                    DropdownMenuItem(value: 'CEN', child: Text('CEN')),
                    DropdownMenuItem(value: 'ATT', child: Text('ATT')),
                  ],
                  onChanged: (v) {
                    setState(() => _position = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _players.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _players.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final p = _players[i];
                      return PlayerListTile(
                        player: p,
                        onTap: () => context.push('/player/${p.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

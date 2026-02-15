import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/player_list_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/player_service.dart';
import '../../services/auction_service.dart';
import '../../utils/error_utils.dart';
import '../../widgets/player_list_tile.dart';

/// Listone giocatori: filtri ruolo/search, ordinamento. Se mode=auction, tap → "Metti all'asta" (solo se è il proprio turno; lista filtrata per categoria).
class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key, required this.leagueId, this.forAuction = false, this.auctionCategory});

  final String leagueId;
  final bool forAuction;
  /// Quando forAuction è true, filtra inizialmente per questa categoria (POR/DIF/CEN/ATT).
  final String? auctionCategory;

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PlayerListItemModel> _players = [];
  int _total = 0;
  int _currentPage = 1;
  bool _loading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _position;
  String _search = '';
  String _sortBy = 'name';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
      _players = [];
      _hasMore = true;
    });
    try {
      final result = await context.read<PlayerService>().getPlayers(
            leagueId: widget.leagueId,
            position: _position,
            search: _search.isEmpty ? null : _search,
            sortBy: _sortBy,
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
            leagueId: widget.leagueId,
            position: _position,
            search: _search.isEmpty ? null : _search,
            sortBy: _sortBy,
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
    if (widget.forAuction &&
        widget.auctionCategory != null &&
        widget.auctionCategory!.isNotEmpty &&
        ['POR', 'DIF', 'CEN', 'ATT'].contains(widget.auctionCategory)) {
      _position = widget.auctionCategory;
    }
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
    final league = context.watch<HomeProvider>().leagues.where((l) => l.id == widget.leagueId).toList();
    final isAdmin = league.isNotEmpty && (league.first.isAdminFor(context.watch<AuthProvider>().user?.id));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${widget.forAuction ? "Scegli giocatore per asta" : "Listone"} ($_total)'),
      ),
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
                DropdownButton<String>(
                  value: _position ?? '',
                  items: widget.forAuction && widget.auctionCategory != null && widget.auctionCategory!.isNotEmpty
                      ? [
                          DropdownMenuItem(value: widget.auctionCategory!, child: Text(widget.auctionCategory!)),
                        ]
                      : const [
                          DropdownMenuItem(value: '', child: Text('Tutti')),
                          DropdownMenuItem(value: 'POR', child: Text('POR')),
                          DropdownMenuItem(value: 'DIF', child: Text('DIF')),
                          DropdownMenuItem(value: 'CEN', child: Text('CEN')),
                          DropdownMenuItem(value: 'ATT', child: Text('ATT')),
                        ],
                  onChanged: (v) {
                    if (widget.forAuction && widget.auctionCategory != null && widget.auctionCategory!.isNotEmpty) return;
                    setState(() => _position = v?.isEmpty == true ? null : v);
                    _load();
                  },
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Nome')),
                    DropdownMenuItem(value: 'initial_price', child: Text('Prezzo')),
                  ],
                  onChanged: (v) {
                    setState(() => _sortBy = v ?? 'name');
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
                        trailing: widget.forAuction ? const Icon(Icons.gavel) : const Icon(Icons.chevron_right),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          if (widget.forAuction) {
                            try {
                              await context.read<AuctionService>().nominate(widget.leagueId, p.id);
                              if (mounted) {
                                messenger.showSnackBar(const SnackBar(content: Text('Giocatore messo all\'asta')));
                                router.pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
                                );
                              }
                            }
                          } else {
                            context.push('/player/${p.id}');
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

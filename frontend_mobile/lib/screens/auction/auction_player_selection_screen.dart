import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/player_list_item.dart';
import '../../services/player_service.dart';
import '../../widgets/player_avatar.dart';

/// Listone per selezionare un giocatore da chiamare all'asta. Ricerca, filtro ruoli, giocatori aggiudicati non selezionabili.
class AuctionPlayerSelectionScreen extends StatefulWidget {
  const AuctionPlayerSelectionScreen({
    super.key,
    required this.leagueId,
    required this.purchasedPlayerIds,
  });

  final String leagueId;
  final List<int> purchasedPlayerIds;

  @override
  State<AuctionPlayerSelectionScreen> createState() => _AuctionPlayerSelectionScreenState();
}

class _AuctionPlayerSelectionScreenState extends State<AuctionPlayerSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PlayerListItemModel> _players = [];
  List<PlayerListItemModel> _filteredPlayers = [];
  bool _loading = true;
  String? _selectedRole; // null = Tutti, else P/D/C/A -> position POR/DIF/CEN/ATT

  static const Map<String, String> _roleToPosition = {
    'P': 'POR',
    'D': 'DIF',
    'C': 'CEN',
    'A': 'ATT',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _loading = true);
    try {
      final playerService = context.read<PlayerService>();
      final List<PlayerListItemModel> all = [];
      int page = 1;
      const int pageSize = 100;
      int totalPages = 1;
      final position = _selectedRole != null ? _roleToPosition[_selectedRole] : null;
      do {
        final result = await playerService.getPlayers(
          leagueId: widget.leagueId,
          position: position,
          sortBy: 'initial_price',
          sortOrder: 'desc',
          page: page,
          pageSize: pageSize,
        );
        all.addAll(result.players);
        totalPages = result.totalPages;
        page++;
      } while (page <= totalPages && totalPages > 1);
      if (mounted) {
        setState(() {
          _players = all;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('AuctionPlayerSelection: errore $e');
      if (mounted) {
        setState(() {
          _players = [];
          _loading = false;
        });
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredPlayers = _players.where((p) {
        if (_selectedRole != null && _roleToPosition[_selectedRole] != null) {
          if (p.position != _roleToPosition[_selectedRole]) return false;
        }
        if (query.isEmpty) return true;
        return p.name.toLowerCase().contains(query) ||
            p.realTeamName.toLowerCase().contains(query) ||
            (p.realTeamShortName?.toLowerCase().contains(query) ?? false);
      }).toList()
        ..sort((a, b) => b.initialPrice.compareTo(a.initialPrice));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seleziona Giocatore',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca giocatore...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildRoleChip('Tutti', null),
                _buildRoleChip('P', 'P'),
                _buildRoleChip('D', 'D'),
                _buildRoleChip('C', 'C'),
                _buildRoleChip('A', 'A'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, i) {
                      return _buildPlayerRow(_filteredPlayers[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRole = role;
            _loadPlayers();
          });
        },
      ),
    );
  }

  Widget _buildPlayerRow(PlayerListItemModel player) {
    final isPurchased = widget.purchasedPlayerIds.contains(player.id);
    final roleColor = getRoleBadgeColor(player.position);
    final roleLetter = getRoleLetter(player.position);

    return Opacity(
      opacity: isPurchased ? 0.5 : 1.0,
      child: ListTile(
        enabled: !isPurchased,
        onTap: isPurchased
            ? null
            : () {
                final map = {
                  'id': player.id,
                  'name': player.name,
                  'position': player.position,
                  'real_team_name': player.realTeamName,
                  'real_team_short_name': player.realTeamShortName,
                  'initial_price': player.initialPrice,
                  'photo_url': player.photoUrl,
                  'real_team_badge': player.realTeamBadgeUrl,
                };
                Navigator.pop(context, map);
              },
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: roleColor, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  getPlayerAvatarUrl(player.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: roleColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: roleColor),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleLetter,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          player.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPurchased ? Colors.grey : const Color(0xFF1A1A2E),
            decoration: isPurchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (player.realTeamBadgeUrl != null && player.realTeamBadgeUrl!.isNotEmpty)
              Image.network(
                player.realTeamBadgeUrl!.startsWith('http')
                    ? player.realTeamBadgeUrl!
                    : '$kBackendOrigin${player.realTeamBadgeUrl}',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            if (player.realTeamBadgeUrl != null && player.realTeamBadgeUrl!.isNotEmpty) const SizedBox(width: 4),
            Text(
              player.realTeamShortName ?? player.realTeamName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isPurchased ? Colors.grey : const Color(0xFF5C6B7A),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              roleLetter,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ],
        ),
        trailing: isPurchased
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Aggiudicato',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              )
            : Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D47A1),
                ),
                child: Center(
                  child: Text(
                    '${player.initialPrice.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

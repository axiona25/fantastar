import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/player_list_item.dart';
import '../../widgets/player_avatar.dart';
import '../../services/player_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/team_utils.dart';
import '../../widgets/fantastar_background.dart';

/// Listone: lista completa giocatori Serie A con avatar, ruolo, squadra, quotazione.
/// Stile Fantastar (palette blu navy, card, ruoli P/D/C/A colorati).
class ListoneScreen extends StatefulWidget {
  const ListoneScreen({super.key});

  @override
  State<ListoneScreen> createState() => _ListoneScreenState();
}

class _ListoneScreenState extends State<ListoneScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PlayerListItemModel> _allPlayers = [];
  List<PlayerListItemModel> _filteredPlayers = [];
  bool _isLoading = true;
  String? _selectedRole; // null = tutti, else POR/DIF/CEN/ATT
  String _sortBy = 'quotation'; // quotation, name, role

  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryDark = Color(0xFF0A3D7A);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textGrey = Color(0xFF5C6B7A);
  static const Color _border = Color(0xFFB0BEC5);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _filterPlayers());
    _fetchPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoading = true);
    try {
      final playerService = context.read<PlayerService>();
      final List<PlayerListItemModel> all = [];
      int page = 1;
      const int pageSize = 100;
      int totalPages = 1;
      do {
        final result = await playerService.getPlayers(
          sortBy: _sortBy == 'quotation' ? 'initial_price' : _sortBy,
          sortOrder: _sortBy == 'quotation' ? 'desc' : 'asc',
          page: page,
          pageSize: pageSize,
        );
        all.addAll(result.players);
        totalPages = result.totalPages;
        page++;
      } while (page <= totalPages && totalPages > 1);
      if (mounted) {
        setState(() {
          _allPlayers = all;
          _filteredPlayers = List.from(all);
          _isLoading = false;
        });
        _filterPlayers();
      }
    } catch (e) {
      debugPrint('Listone: errore caricamento $e');
      if (mounted) {
        setState(() {
          _allPlayers = [];
          _filteredPlayers = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterPlayers() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      _filteredPlayers = _allPlayers.where((p) {
        if (_selectedRole != null && p.position != _selectedRole) return false;
        if (query.isNotEmpty) {
          final matchName = p.name.toLowerCase().contains(query);
          final matchTeam = (p.realTeamName).toLowerCase().contains(query);
          return matchName || matchTeam;
        }
        return true;
      }).toList();
      _sortPlayers();
    });
  }

  void _sortPlayers() {
    _filteredPlayers.sort((a, b) {
      switch (_sortBy) {
        case 'quotation':
          return b.initialPrice.compareTo(a.initialPrice);
        case 'name':
          return a.name.compareTo(b.name);
        case 'role':
          return _roleOrder(a.position).compareTo(_roleOrder(b.position));
        default:
          return 0;
      }
    });
  }

  int _roleOrder(String position) {
    switch (position.toUpperCase()) {
      case 'POR':
        return 0;
      case 'DIF':
        return 1;
      case 'CEN':
        return 2;
      case 'ATT':
        return 3;
      default:
        return 4;
    }
  }

  Color _getRoleColor(String position) {
    final r = _positionToRoleLetter(position);
    switch (r) {
      case 'P':
        return const Color(0xFFFF8F00);
      case 'D':
        return const Color(0xFF2E7D32);
      case 'C':
        return const Color(0xFF1565C0);
      case 'A':
        return const Color(0xFFC62828);
      default:
        return _textGrey;
    }
  }

  String _positionToRoleLetter(String position) {
    switch (position.toUpperCase()) {
      case 'POR':
        return 'P';
      case 'DIF':
        return 'D';
      case 'CEN':
        return 'C';
      case 'ATT':
        return 'A';
      default:
        return position.isNotEmpty ? position[0].toUpperCase() : '?';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ordina per',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Quotazione (alta → bassa)', 'quotation'),
            _buildSortOption('Nome (A → Z)', 'name'),
            _buildSortOption('Ruolo (P → A)', 'role'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = value);
        _sortPlayers();
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: _primary,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    final Color chipColor = role == null
        ? _primary
        : (role == 'POR'
            ? const Color(0xFFFF8F00)
            : role == 'DIF'
                ? const Color(0xFF2E7D32)
                : role == 'CEN'
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFC62828));
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
        _filterPlayers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : _border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(PlayerListItemModel player) {
    final teamLogoUrl = player.realTeamBadgeUrl != null && player.realTeamBadgeUrl!.isNotEmpty
        ? (player.realTeamBadgeUrl!.startsWith('http')
            ? player.realTeamBadgeUrl
            : '$kBackendOrigin${player.realTeamBadgeUrl}')
        : getTeamBadgeUrl(player.realTeamName);
    final teamShort = player.realTeamShortName ?? getShortName(player.realTeamName);
    final displayShort = teamShort.length >= 3 ? teamShort.substring(0, 3).toUpperCase() : teamShort.toUpperCase();

    return GestureDetector(
      onTap: () => context.push('/player/${player.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            PlayerAvatar(
              playerId: player.id,
              role: player.position,
              size: 52,
              showRoleBadge: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (teamLogoUrl != null && teamLogoUrl.isNotEmpty)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              teamLogoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield,
                                size: 12,
                                color: _textGrey,
                              ),
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.shield, size: 12, color: _textGrey),
                      const SizedBox(width: 6),
                      Text(
                        displayShort,
                        style: GoogleFonts.poppins(fontSize: 12, color: _textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
                border: Border.all(color: _primary.withOpacity(0.3), width: 2),
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
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: _textGrey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: FantastarBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 24),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    const Spacer(),
                    Text(
                      'Listone',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryDark,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showSortOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune, size: 20, color: _textDark),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _filterPlayers(),
                      style: GoogleFonts.poppins(fontSize: 14, color: _textDark),
                      decoration: InputDecoration(
                        hintText: 'Cerca giocatore...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.95),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search, color: _primary),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (_, value, __) => value.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _filterPlayers();
                                  },
                                  child: const Icon(Icons.close, color: _textGrey),
                                )
                              : const SizedBox.shrink(),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRoleChip('Tutti', null),
                          const SizedBox(width: 8),
                          _buildRoleChip('P', 'POR'),
                          const SizedBox(width: 8),
                          _buildRoleChip('D', 'DIF'),
                          const SizedBox(width: 8),
                          _buildRoleChip('C', 'CEN'),
                          const SizedBox(width: 8),
                          _buildRoleChip('A', 'ATT'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _primary))
                    : _filteredPlayers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: _textGrey.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  'Nessun giocatore trovato',
                                  style: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredPlayers.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: _border.withOpacity(0.3),
                            ),
                            itemBuilder: (context, index) => _buildPlayerRow(_filteredPlayers[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

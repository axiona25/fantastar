import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';
import '../../services/auction_random_service.dart';

const Color _kAccentMagenta = Color(0xFFE91E8C);

class AuctionResultsScreen extends StatefulWidget {
  const AuctionResultsScreen({super.key, required this.leagueId, required this.turnNumber});

  final String leagueId;
  final int turnNumber;

  @override
  State<AuctionResultsScreen> createState() => _AuctionResultsScreenState();
}

class _AuctionResultsScreenState extends State<AuctionResultsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<AuctionRandomService>().getTurnResults(widget.leagueId, widget.turnNumber);
      if (mounted) setState(() {
        _data = data;
        _loading = false;
        _error = data == null ? 'Risultati non disponibili' : null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FantastarBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null || _data == null
                          ? Center(child: Text(_error ?? 'Nessun risultato', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey)))
                          : _buildContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final role = _data?['role'] as String? ?? '?';
    final roleLabel = _roleLabel(role);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 24),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Risultati turno ${widget.turnNumber} – $roleLabel',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final results = _data!['results'] as List<dynamic>? ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        ...results.map((r) => _ResultCard(result: r as Map<String, dynamic>)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: _kAccentMagenta,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: () => context.go('/league/${widget.leagueId}/auction/turn'),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Vai al prossimo turno',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'P': return 'Portieri';
      case 'D': return 'Difensori';
      case 'C': return 'Centrocampisti';
      case 'A': return 'Attaccanti';
      default: return role;
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final playerName = result['player_name'] as String? ?? '–';
    final position = result['position'] as String? ?? '–';
    final realTeam = result['real_team'] as String?;
    final winnerName = result['winner_username'] as String? ?? result['winner_team_name'] as String?;
    final winningBid = result['winning_bid'] as int? ?? 0;
    final status = result['status'] as String? ?? '–';
    final allBids = result['all_bids'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(playerName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Text('$position${realTeam != null ? ' · $realTeam' : ''}', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          if (status == 'sold' && winnerName != null && winnerName.isNotEmpty)
            Text('Vincitore: $winnerName – $winningBid cr', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kAccentMagenta))
          else if (status == 'unsold')
            Text('Nessuna offerta', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey)),
          if (allBids.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Tutte le offerte:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 4),
            ...allBids.map((b) {
              final bid = b as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('${bid['username'] ?? '?'}: ${bid['amount'] ?? 0} cr', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
              );
            }),
          ],
        ],
      ),
    );
  }
}

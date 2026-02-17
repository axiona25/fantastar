import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';
import '../../services/auction_random_service.dart';

const Color _kAccentMagenta = Color(0xFFE91E8C);

class AuctionOverviewScreen extends StatefulWidget {
  const AuctionOverviewScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<AuctionOverviewScreen> createState() => _AuctionOverviewScreenState();
}

class _AuctionOverviewScreenState extends State<AuctionOverviewScreen> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<AuctionRandomService>().getStatus(widget.leagueId);
      if (mounted) setState(() {
        _status = data;
        _loading = false;
        _error = data == null ? 'Nessuna asta random' : null;
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
                      : _error != null || _status == null
                          ? Center(child: Text(_error ?? '–', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey)))
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
                'Riepilogo Asta',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  String _num(dynamic v) {
    if (v == null) return '0';
    if (v is int) return v.toString();
    if (v is double) return v.toStringAsFixed(0);
    return v.toString();
  }

  Widget _buildContent(BuildContext context) {
    final status = _status!['status'] as String? ?? '–';
    final currentRole = _status!['current_role'] as String? ?? '–';
    final currentTurn = _status!['current_turn'] as int? ?? 0;
    final teams = _status!['teams'] as List<dynamic>? ?? [];
    final activeTurn = _status!['active_turn'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Stato: $status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            Text('Ruolo: $currentRole · Turno $currentTurn', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey)),
            if (activeTurn != null) ...[
              const SizedBox(height: 16),
              Material(
                color: _kAccentMagenta,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: () => context.push('/league/${widget.leagueId}/auction/turn'),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('Vai al turno attivo', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Squadre', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),
            ...teams.map((t) {
              final team = t as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(team['team_name'] as String? ?? '–', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark)),
                    Text('${_num(team['budget_remaining'])} cr · Rosa ${team['roster_size'] ?? 0}', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/fantasy_league.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/league_logo.dart';
import '../../services/league_service.dart';
import '../../services/auction_random_service.dart';

const Color _kAccentMagenta = Color(0xFFE91E8C);

class AuctionTabScreen extends StatefulWidget {
  const AuctionTabScreen({super.key});

  @override
  State<AuctionTabScreen> createState() => _AuctionTabScreenState();
}

class _AuctionTabScreenState extends State<AuctionTabScreen> {
  List<FantasyLeagueModel> _leagues = [];
  final Map<String, Map<String, dynamic>?> _statusByLeague = {};
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _statusByLeague.clear();
    });
    try {
      final leagueService = context.read<LeagueService>();
      final auctionService = context.read<AuctionRandomService>();
      final list = await leagueService.getLeagues();
      final statuses = <String, Map<String, dynamic>?>{};
      for (final l in list) {
        try {
          statuses[l.id] = await auctionService.getStatus(l.id);
        } catch (_) {
          statuses[l.id] = null;
        }
      }
      if (mounted) {
        setState(() {
          _leagues = list;
          _statusByLeague.addAll(statuses);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Center(
                    child: Text(
                      'Asta',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey)))
                          : _leagues.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Crea o unisciti a una lega per partecipare all\'asta.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                    children: _leagues.map((l) => _LeagueAuctionCard(
                                      league: l,
                                      status: _statusByLeague[l.id],
                                      onConfig: () => context.push('/league/${l.id}/auction/config'),
                                      onTurn: () => context.push('/league/${l.id}/auction/turn'),
                                      onOverview: () => context.push('/league/${l.id}/auction/overview'),
                                    )).toList(),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueAuctionCard extends StatelessWidget {
  const _LeagueAuctionCard({
    required this.league,
    required this.status,
    required this.onConfig,
    required this.onTurn,
    required this.onOverview,
  });

  final FantasyLeagueModel league;
  final Map<String, dynamic>? status;
  final VoidCallback onConfig;
  final VoidCallback onTurn;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) {
    final st = status?['status'] as String? ?? '';
    final hasActiveTurn = status?['active_turn'] != null;
    final isActive = st == 'active' || hasActiveTurn;
    final isCompleted = st == 'completed';

    String actionLabel;
    VoidCallback action;
    if (isActive) {
      actionLabel = 'Vai al turno';
      action = onTurn;
    } else if (isCompleted) {
      actionLabel = 'Riepilogo';
      action = onOverview;
    } else {
      actionLabel = 'Configura asta';
      action = onConfig;
    }

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
      child: Row(
        children: [
          LeagueLogo(logoKey: league.logo, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  league.displayName ?? league.name,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                if (isActive)
                  Text('Asta in corso', style: GoogleFonts.poppins(fontSize: 13, color: _kAccentMagenta))
                else if (isCompleted)
                  Text('Completata', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey)),
              ],
            ),
          ),
          Material(
            color: _kAccentMagenta,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/standing_row.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/team_utils.dart';
import '../../widgets/fantastar_background.dart';

/// Pagina classifica Serie A completa: tutte le 20 squadre, header fisso, colori posizioni.
class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  List<StandingRow> _rows = [];
  bool _loading = true;
  String? _error;

  static String? _resolveLogoUrl(String? crest) {
    if (crest == null || crest.isEmpty) return null;
    if (crest.startsWith('http://') || crest.startsWith('https://')) return crest;
    return '$kBackendOrigin$crest';
  }

  static String _standingsBadgeUrl(StandingRow r) {
    final local = getTeamBadgeUrl(r.teamName);
    if (local.isNotEmpty) return local;
    return _resolveLogoUrl(r.crest) ?? '';
  }

  static Color _positionColor(int position) {
    if (position >= 1 && position <= 4) return AppColors.primary;
    if (position >= 5 && position <= 6) return Colors.orange.shade700;
    if (position >= 18 && position <= 20) return Colors.red.shade700;
    return AppColors.textDark;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<StatsService>().getStandings();
      if (mounted) {
        setState(() {
          _rows = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rows = [];
          _loading = false;
          _error = 'error';
        });
      }
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
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildPlaceholder()
                        : _rows.isEmpty
                            ? _buildPlaceholder()
                            : _buildCard(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Header: indietro a sinistra, logo e titolo centrati alla riga, refresh a destra.
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.emoji_events_outlined, color: AppColors.textGrey, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Classifica Serie A',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryDark, size: 24),
            onPressed: _loading ? null : _load,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Classifica non disponibile',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _load,
              child: Text(
                'Riprova',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header colonne: #, logo, nome, G, V, P, S, GF, GS, Pts
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 28, child: Text('#', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.center)),
                  const SizedBox(width: 36),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Squadra', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey))),
                  SizedBox(width: 24, child: Center(child: Text('G', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 24, child: Center(child: Text('V', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 20, child: Center(child: Text('P', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 20, child: Center(child: Text('S', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 28, child: Center(child: Text('GF', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 28, child: Center(child: Text('GS', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey)))),
                  SizedBox(width: 32, child: Text('Pts', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.right)),
                ],
              ),
            ),
            // ListView righe (tutte le 20)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 12, endIndent: 12, color: AppColors.inputBorder.withOpacity(0.6)),
              itemBuilder: (context, i) {
                final r = _rows[i];
                final logoUrl = _standingsBadgeUrl(r);
                final posColor = _positionColor(r.position);
                final initial = getShortName(r.teamName).isNotEmpty ? getShortName(r.teamName).substring(0, 1).toUpperCase() : '?';
                return InkWell(
                  onTap: () {
                    // Futuro: dettaglio squadra
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${r.position}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: posColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: logoUrl.isEmpty
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    logoUrl,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getShortName(r.teamName),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 24, child: Text('${r.played}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(width: 24, child: Text('${r.won}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(width: 20, child: Text('${r.draw}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(width: 20, child: Text('${r.lost}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(width: 28, child: Text('${r.goalsFor}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(width: 28, child: Text('${r.goalsAgainst}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center)),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${r.points}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

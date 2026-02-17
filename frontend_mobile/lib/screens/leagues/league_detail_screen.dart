import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants.dart';
import '../../models/fantasy_league.dart';
import '../../models/standing.dart';
import '../../providers/auth_provider.dart';
import '../../services/league_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/league_logo.dart';

class LeagueDetailScreen extends StatefulWidget {
  final String leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> with TickerProviderStateMixin {
  FantasyLeagueModel? _league;
  List<StandingModel> _standings = [];
  bool _loading = true;
  String? _error;
  bool _isGenerating = false;

  AnimationController? _cardBgController;
  Animation<double>? _cardBgScale;
  Animation<double>? _cardBgSlideX;
  Animation<double>? _cardBgSlideY;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.getLeague(widget.leagueId);
      final standings = await leagueService.getStandings(widget.leagueId);
      setState(() {
        _league = league;
        _standings = standings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
    _cardBgController = controller;
    _cardBgScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    _cardBgSlideX = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    _cardBgSlideY = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cardBgController?.dispose();
    super.dispose();
  }

  void _copyInviteCode() {
    final code = _league?.inviteCode;
    if (code != null && code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codice copiato!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _shareInvite() {
    final code = _league?.inviteCode ?? '';
    Share.share('Unisciti alla mia lega FANTASTAR! Usa il codice: $code');
  }

  Future<void> _generateCalendar() async {
    if (_league == null || _isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await context.read<LeagueService>().generateCalendar(widget.leagueId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendario generato!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  static Color _getPositionColor(int position) {
    if (position == 1) return const Color(0xFFFFB300);
    if (position == 2) return const Color(0xFF78909C);
    if (position == 3) return const Color(0xFF8D6E63);
    return const Color(0xFF0D47A1);
  }

  /// STATO A — Placeholder: squadra NON creata (nessun nome scelto dall'utente), invito a creare.
  Widget _buildCreateTeamPlaceholder() {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>('/league/${widget.leagueId}/create-team');
        if (result == true && mounted) _load();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0D47A1).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E8F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 28, color: Color(0xFF0D47A1)),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFF0D47A1),
                      child: Icon(Icons.add, size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crea la tua Squadra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Scegli nome, stemma e inizia a giocare',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C6B7A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// STATO B — Riepilogo: squadra CREATA (stemma + avatar, nome, crediti, posizione).
  Widget _buildTeamSummaryCard(FantasyLeagueModel league, StandingModel myStanding) {
    final position = myStanding.rank;
    final credits = myStanding.budgetRemaining ?? league.budget.toDouble();
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          '/league/${widget.leagueId}/my-team',
          extra: [league, myStanding, _standings],
        );
        if (result == true && mounted) _load();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Stemma + Avatar affiancati, entrambi CIRCOLARI, sovrapposti
            SizedBox(
              width: 80,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // STEMMA SQUADRA — cerchio, sotto (z-index basso)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0E8F2),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (myStanding.logoUrl != null && myStanding.logoUrl!.isNotEmpty)
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.network(
                                  '$kBackendOrigin${myStanding.logoUrl}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 22, color: Color(0xFF0D47A1)),
                                ),
                              )
                            : const Icon(Icons.shield, size: 22, color: Color(0xFF0D47A1)),
                      ),
                    ),
                  ),
                  // AVATAR ALLENATORE — cerchio, sopra (z-index alto), sovrapposto a destra
                  Positioned(
                    left: 32, // sovrapposto di ~18px (50 - 32 = 18px di overlap)
                    top: 2,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0E8F2),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (myStanding.coachAvatarUrl != null && myStanding.coachAvatarUrl!.isNotEmpty)
                            ? Image.network(
                                '$kBackendOrigin${myStanding.coachAvatarUrl}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 22, color: Color(0xFF0D47A1)),
                              )
                            : const Icon(Icons.person, size: 22, color: Color(0xFF0D47A1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    myStanding.teamName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${credits is int ? credits : credits.toInt()} crediti',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C6B7A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPositionColor(position),
              ),
              child: Center(
                child: Text(
                  position > 0 ? '$position°' : '–',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// URL stemma lega da backend (per badge network). Vuoto se logo è icona (trophy, star, ...).
  String _leagueBadgeUrl(FantasyLeagueModel league) {
    final logo = league.logo;
    if (logo.startsWith('http')) return logo;
    if (logo.startsWith('/static/') || logo.contains('league_badges')) {
      return '$kBackendOrigin${logo.startsWith('/') ? logo : '/$logo'}';
    }
    if (RegExp(r'^badge_\d{2}$').hasMatch(logo)) {
      return '$kBackendOrigin/static/media/league_badges/3d/$logo.png';
    }
    return '';
  }

  static const List<Map<String, dynamic>> _managementButtons = [
    {'icon': Icons.calendar_month, 'label': 'Calendario'},
    {'icon': Icons.group, 'label': 'Partecipanti\ne inviti'},
    {'icon': Icons.calculate, 'label': 'Calcolo\nGiornata'},
    {'icon': Icons.edit_note, 'label': 'Modifica\npunti'},
    {'icon': Icons.person_add, 'label': 'Richieste\niscrizione'},
    {'icon': Icons.settings, 'label': 'Impostazioni\nLega'},
    {'icon': Icons.history, 'label': 'Registro\nattività'},
    {'icon': Icons.gavel, 'label': 'Avvia asta', 'route': 'auction_config'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: FantastarBackground(
            child: SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null || _league == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: FantastarBackground(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ?? 'Lega non trovata',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final league = _league!;
    final user = context.watch<AuthProvider>().user;
    final myStanding = user != null
        ? _standings.cast<StandingModel?>().firstWhere(
              (s) => s?.userId == user.id,
              orElse: () => null,
            )
        : null;
    // Squadra "creata" solo se configurata dalla pagina Crea Squadra (nome, stemma, ecc.).
    final hasCreatedTeam = myStanding != null && myStanding.isConfigured;
    final isAdmin = league.isAdminFor(user?.id);
    final maxTeams = league.maxMembers ?? league.maxTeams;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FantastarBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1) HEADER — allineato al padding del body (20px), solo padding verticale
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 20),
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
                                LeagueLogo(logoKey: league.logo, size: 48),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    league.displayTitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: AppColors.primaryDark, size: 24),
                            onPressed: () => context.push('/league/${widget.leagueId}/management'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          )
                        else
                          const SizedBox(width: 44, height: 44),
                      ],
                    ),
                  ),

                  // 2) SEZIONE 1 — Card Principale Lega (sfondo da backend, altezza fissa come quando c'era il logo)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 240),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.antiAlias,
                        children: [
                          Positioned.fill(
                          child: _cardBgController != null && _cardBgScale != null && _cardBgSlideX != null && _cardBgSlideY != null
                              ? AnimatedBuilder(
                                  animation: _cardBgController!,
                                  builder: (context, child) {
                                    return Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..translate(_cardBgSlideX!.value, _cardBgSlideY!.value)
                                        ..scale(_cardBgScale!.value),
                                      child: child,
                                    );
                                  },
                                  child: Image.network(
                                    '$kBackendOrigin/static/media/Sfondi/Sfondo01.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                )
                              : Image.network(
                                  '$kBackendOrigin/static/media/Sfondi/Sfondo01.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.group, size: 16, color: AppColors.textGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${league.teamCount ?? 0}/$maxTeams squadre',
                                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.account_balance_wallet, size: 16, color: AppColors.textGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${league.budget.toInt()} cr',
                                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.vpn_key, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        league.inviteCode ?? '–',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _copyInviteCode,
                                        child: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),

                  // Bottone Genera Calendario (solo se non generato e utente è admin)
                  if (!league.calendarGenerated && isAdmin) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateCalendar,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.calendar_month, color: Colors.white),
                        label: Text(
                          _isGenerating ? 'Generazione...' : 'Genera Calendario',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],

                  // 3) SEZIONE 2 — La Mia Squadra (doppio stato: placeholder / riepilogo)
                  const SizedBox(height: 24),
                  Text(
                    'La mia Squadra',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  !hasCreatedTeam
                      ? _buildCreateTeamPlaceholder()
                      : _buildTeamSummaryCard(league, myStanding!),

                  // 4) SEZIONE — Calendario
                  const SizedBox(height: 24),
                  Text(
                    'Calendario',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today, size: 40, color: AppColors.textGrey.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'Nessuna partita in programma',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),

                  // 5) SEZIONE — Gestione Lega (solo 7 bottoni)
                  const SizedBox(height: 24),
                  Text(
                    'Gestione Lega',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _managementButtons.length,
                    itemBuilder: (context, index) {
                      final btn = _managementButtons[index];
                      final label = btn['label'] as String;
                      final route = btn['route'] as String?;
                      return GestureDetector(
                        onTap: () {
                          if (route == 'auction_config') {
                            if (isAdmin) {
                              context.push('/league/${widget.leagueId}/auction/config', extra: league);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solo l\'admin può configurare e avviare l\'asta.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          } else if (route != null) {
                            context.push('/league/${widget.leagueId}/$route');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${label.replaceAll('\n', ' ')} - Coming soon!'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(btn['icon'] as IconData, size: 28, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

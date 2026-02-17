import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/fantasy_league.dart';
import '../../models/standing.dart';
import '../../providers/auth_provider.dart';
import '../../services/auction_random_service.dart';
import '../../services/league_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';

/// Pagina "La mia Squadra": dettaglio della propria squadra fantasy nella lega.
/// Stile Fantastar (stesso sfondo/card della dettaglio lega).
class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({
    super.key,
    required this.leagueId,
    required this.league,
    required this.myStanding,
    this.standings = const [],
  });

  final String leagueId;
  final FantasyLeagueModel league;
  final StandingModel myStanding;
  /// Classifica della lega (opzionale, per evidenziare la propria riga).
  final List<StandingModel> standings;

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  List<StandingModel> _standings = [];
  bool _standingsLoaded = false;
  /// True se l'utente ha inserito la formazione per la giornata in corso; quando l'admin fa calcolo giornata si resetta.
  bool _hasFormazioneInserita = false;
  @override
  void initState() {
    super.initState();
    if (widget.standings.isNotEmpty) {
      _standings = List.from(widget.standings);
      _standingsLoaded = true;
    } else {
      _loadStandings();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfNotConfigured());
  }

  /// Se la squadra non è stata ancora configurata (nome = username/default), vai a Crea Squadra.
  void _redirectIfNotConfigured() {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    final my = widget.myStanding;
    final name = my.teamName.trim();
    final isDefaultName = name.isEmpty ||
        (user != null && name == user.username) ||
        name == 'La mia squadra';
    if (isDefaultName) {
      context.pushReplacement('/league/${widget.leagueId}/create-team');
    }
  }

  Future<void> _loadStandings() async {
    try {
      final list = await context.read<LeagueService>().getStandings(widget.leagueId);
      if (mounted) {
        setState(() {
          _standings = list;
          _standingsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _standingsLoaded = true);
    }
  }

  /// Mock: partita live (null = nessuna)
  dynamic get liveMatch => null;

  /// Mock: ultime 5 partite (V/P/S)
  List<Map<String, String>> get lastFiveResults => [];

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C6B7A),
          ),
        ),
      ],
    );
  }

  Widget _buildPuntiRiquadro(String outcome) {
    Color bgColor;
    String label;
    switch (outcome) {
      case 'V':
        bgColor = const Color(0xFF2E7D32);
        label = 'V';
        break;
      case 'P':
        bgColor = const Color(0xFFFFB300);
        label = 'P';
        break;
      case 'S':
        bgColor = Colors.red.shade700;
        label = 'S';
        break;
      default:
        bgColor = const Color(0xFFE0E8F2);
        label = '–';
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: outcome == '–' ? Border.all(color: const Color(0xFFB0BEC5), width: 1) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: outcome == '–' ? const Color(0xFF5C6B7A) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Placeholder card Live: nessuna formazione inserita; pulsante "Inserisci formazione" (valida per la giornata in corso).
  /// Dopo il calcolo giornata dall'admin la card si svuota e ritorna questo placeholder.
  Widget _buildLivePlaceholderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 44,
            color: const Color(0xFF5C6B7A).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Inserisci la formazione per la giornata in corso',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF5C6B7A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: navigare a schermata inserimento formazione; al ritorno con successo setState(() => _hasFormazioneInserita = true)
                setState(() => _hasFormazioneInserita = true);
              },
              icon: const Icon(Icons.edit_calendar, size: 20),
              label: const Text('Inserisci formazione'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Live con partita: due squadre con stemmi, VS, e punteggio in tempo reale.
  Widget _buildLiveMatchCard(StandingModel my, FantasyLeagueModel league) {
    // TODO: avversario e punteggi da API (giornata corrente, calcolo live); per ora placeholder
    const String opponentName = 'Avversario';
    const int myPoints = 0;
    const int opponentPoints = 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stemma mia squadra
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _liveStemma(my.logoUrl, 56),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 90,
                    child: Text(
                      my.teamName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                    ),
                  ),
                ],
              ),
              // VS
              Text(
                'VS',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
              // Stemma avversario (placeholder)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _liveStemma(null, 56),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 90,
                    child: Text(
                      opponentName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Punteggio in tempo reale
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$myPoints',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '–',
                  style: GoogleFonts.poppins(fontSize: 20, color: const Color(0xFF5C6B7A)),
                ),
              ),
              Text(
                '$opponentPoints',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveStemma(String? logoUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0E8F2),
        border: Border.all(color: const Color(0xFFB0BEC5), width: 1.5),
      ),
      child: ClipOval(
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: Image.network(
                  '$kBackendOrigin$logoUrl',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 28, color: Color(0xFF0D47A1)),
                ),
              )
            : const Icon(Icons.shield, size: 28, color: Color(0xFF0D47A1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final league = widget.league;
    final my = widget.myStanding;
    final user = context.watch<AuthProvider>().user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FantastarBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1) HEADER — identico alla pagina La mia Lega
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 24),
                          onPressed: () => context.pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        const Spacer(),
                        const Text(
                          'La mia Squadra',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A3D7A),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // 2) CARD PRINCIPALE con sfondo immagine (altezza fissa per evitare overflow e infinite height)
                  Container(
                    width: double.infinity,
                    height: 220,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            '$kBackendOrigin/static/media/Sfondi/Sfondo02.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                          // Contenuto centrato sulla card con sfondo (più padding in alto per stemma/avatar più in basso)
                          Padding(
                            padding: const EdgeInsets.only(top: 36, bottom: 16, left: 16, right: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // STEMMA + AVATAR ALLENATORE affiancati circolari sovrapposti
                                SizedBox(
                                  width: 130,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // STEMMA SQUADRA — cerchio, a sinistra
                                      Positioned(
                                        left: 10,
                                        child: Container(
                                          width: 74,
                                          height: 74,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFE0E8F2),
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: my.logoUrl != null && my.logoUrl!.isNotEmpty
                                                ? Padding(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Image.network(
                                                      '$kBackendOrigin${my.logoUrl}',
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 34, color: Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.shield, size: 34, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      // AVATAR ALLENATORE — cerchio, sovrapposto a destra
                                      Positioned(
                                        left: 58,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFE0E8F2),
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: my.coachAvatarUrl != null && my.coachAvatarUrl!.isNotEmpty
                                                ? Image.network(
                                                    '$kBackendOrigin${my.coachAvatarUrl}',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Color(0xFF0D47A1)),
                                                  )
                                                : const Icon(Icons.person, size: 30, color: Color(0xFF0D47A1)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Nome squadra
                                Text(
                                  my.teamName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Nome lega
                                Text(
                                  league.name,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3) CARD STATS — 3 badge
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                        Expanded(
                          child: _buildStatBadge(
                            icon: Icons.account_balance_wallet,
                            value: '${league.budget.toInt()}',
                            label: 'Budget',
                            color: const Color(0xFF0D47A1),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: const Color(0xFFB0BEC5).withOpacity(0.5),
                        ),
                        Expanded(
                          child: _buildStatBadge(
                            icon: Icons.bar_chart,
                            value: '–',
                            label: 'Media',
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: const Color(0xFFB0BEC5).withOpacity(0.5),
                        ),
                        Expanded(
                          child: _buildStatBadge(
                            icon: Icons.sports_soccer,
                            value: '–',
                            label: 'Ultima',
                            color: const Color(0xFF0A3D7A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4) CARD LIVE — placeholder con "Inserisci formazione" oppure partita con stemmi e punteggio
                  const SizedBox(height: 24),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A3D7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _hasFormazioneInserita ? _buildLiveMatchCard(my, league) : _buildLivePlaceholderCard(),

                  // 5) CLASSIFICA — identica alla pagina La mia Lega
                  const SizedBox(height: 24),
                  const Text(
                    'Classifica',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A3D7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: !_standingsLoaded || _standings.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(Icons.emoji_events_outlined, size: 40, color: const Color(0xFF5C6B7A).withOpacity(0.6)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Classifica non disponibile',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF5C6B7A),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 24, child: Text('#', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A)))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Squadra', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A)))),
                                  SizedBox(width: 28, child: Center(child: Text('Pt', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A))))),
                                  SizedBox(width: 24, child: Center(child: Text('V', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A))))),
                                  SizedBox(width: 24, child: Center(child: Text('P', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A))))),
                                  SizedBox(width: 24, child: Center(child: Text('S', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5C6B7A))))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, color: const Color(0xFFB0BEC5).withOpacity(0.6)),
                              ..._standings.map((s) {
                                final isMyRow = user != null && s.userId == user.id;
                                return Container(
                                  color: isMyRow ? const Color(0xFF0D47A1).withOpacity(0.08) : null,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 24, child: Text('${s.rank}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A1A2E)))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s.teamName,
                                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A1A2E)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${s.totalPoints}',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
                                        ),
                                      ),
                                      SizedBox(width: 24, child: Center(child: Text('${s.wins}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A1A2E))))),
                                      SizedBox(width: 24, child: Center(child: Text('${s.draws}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A1A2E))))),
                                      SizedBox(width: 24, child: Center(child: Text('${s.losses}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A1A2E))))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),

                  // 6) CARD PUNTI — Totale + Ultime 5 partite
                  const SizedBox(height: 24),
                  const Text(
                    'Punti',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A3D7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prima fila: stemma squadra + nome squadra
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE0E8F2),
                                border: Border.all(color: const Color(0xFFB0BEC5), width: 1),
                              ),
                              child: ClipOval(
                                child: my.logoUrl != null && my.logoUrl!.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Image.network(
                                          '$kBackendOrigin${my.logoUrl}',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 22, color: Color(0xFF0D47A1)),
                                        ),
                                      )
                                    : const Icon(Icons.shield, size: 22, color: Color(0xFF0D47A1)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                my.teamName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${my.totalPoints} pt',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                        // Seconda fila: 5 riquadri che coprono tutta la larghezza
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (int i = 0; i < 5; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: _buildPuntiRiquadro(
                                  i < lastFiveResults.length ? lastFiveResults[i]['outcome'] ?? '–' : '–',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 7) MENU GESTIONE — Griglia identica alla pagina La mia Lega
                  const SizedBox(height: 24),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A3D7A),
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
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _menuButtons.length,
                    itemBuilder: (context, i) {
                      final btn = _menuButtons[i];
                      final label = btn['label'] as String;
                      final isAsta = label == 'Asta';
                      final isListone = label == 'Listone';
                      return GestureDetector(
                        onTap: () async {
                          if (isListone) {
                            context.push('/listone');
                            return;
                          }
                          if (isAsta) {
                            try {
                              final data = await context.read<AuctionRandomService>().getConfig(widget.leagueId);
                              if (!mounted) return;
                              final config = data['config'] as Map<String, dynamic>?;
                              final status = config?['status'] as String?;
                              final astaStarted = data['asta_started'] as bool? ?? false;

                              if (status == 'completed') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('L\'asta è già stata completata'),
                                    backgroundColor: Color(0xFF0D47A1),
                                  ),
                                );
                                return;
                              }
                              if (status == 'active' || status == 'paused' || astaStarted) {
                                context.push('/league/${widget.leagueId}/auction/live', extra: league);
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('L\'asta non è ancora iniziata. Attendi che l\'admin la avvii.'),
                                  backgroundColor: Color(0xFFFFB300),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('L\'asta non è ancora stata configurata'),
                                  backgroundColor: Color(0xFF5C6B7A),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$label - Coming soon!'),
                                backgroundColor: const Color(0xFF0D47A1),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
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
                              Icon(btn['icon'] as IconData, size: 28, color: const Color(0xFF0D47A1)),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A2E),
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

  static const List<Map<String, dynamic>> _menuButtons = [
    {'icon': Icons.calendar_month, 'label': 'Calendario'},
    {'icon': Icons.emoji_events, 'label': 'Competizioni'},
    {'icon': Icons.list_alt, 'label': 'Rose'},
    {'icon': Icons.gavel, 'label': 'Asta'},
    {'icon': Icons.store, 'label': 'Mercato'},
    {'icon': Icons.swap_horiz, 'label': 'Scambi'},
    {'icon': Icons.trending_up, 'label': 'Andamento'},
    {'icon': Icons.person_off, 'label': 'Svincolati'},
    {'icon': Icons.format_list_numbered, 'label': 'Listone'},
    {'icon': Icons.local_hospital, 'label': 'Infortunati'},
    {'icon': Icons.group, 'label': 'Partecipanti'},
    {'icon': Icons.search, 'label': "Chi ce l'ha?"},
  ];
}

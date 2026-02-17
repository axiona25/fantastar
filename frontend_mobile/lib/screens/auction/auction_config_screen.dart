import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/fantasy_league.dart';
import '../../services/auction_random_service.dart';
import '../../services/league_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/fantastar_button.dart';

// Palette: Primary #0D47A1, PrimaryDark #0A3D7A, Accent Magenta #E91E8C (solo asta)
const Color _kAccentMagenta = Color(0xFFE91E8C);
const Color _kPrimary = Color(0xFF0D47A1);
const Color _kPrimaryDark = Color(0xFF0A3D7A);
const Color _kTextDark = Color(0xFF1A1A2E);
const Color _kTextGrey = Color(0xFF5C6B7A);
const Color _kBorder = Color(0xFFB0BEC5);

class AuctionConfigScreen extends StatefulWidget {
  const AuctionConfigScreen({super.key, required this.leagueId, this.league});

  final String leagueId;
  final FantasyLeagueModel? league;

  @override
  State<AuctionConfigScreen> createState() => _AuctionConfigScreenState();
}

class _AuctionConfigScreenState extends State<AuctionConfigScreen> {
  FantasyLeagueModel? _league;
  Map<String, dynamic>? _config;
  bool _astaStarted = false;
  bool _loading = true;
  bool _isSaving = false;
  bool _isStarting = false;
  bool _loadingReset = false;
  String? _error;

  // Rosa (comuni)
  final _budgetController = TextEditingController(text: '500');
  final _maxPlayersController = TextEditingController(text: '25');
  final _minGkController = TextEditingController(text: '3');
  final _minDefController = TextEditingController(text: '8');
  final _minMidController = TextEditingController(text: '8');
  final _minFwdController = TextEditingController(text: '6');
  final _basePriceController = TextEditingController(text: '1');

  // Classica
  int _bidTimerSeconds = 60;
  final _minRaiseController = TextEditingController(text: '1');
  String _callOrder = 'random';
  bool _allowNomination = true;
  final _pauseController = TextEditingController(text: '10');

  // Busta chiusa
  final _roundsCountController = TextEditingController(text: '3');
  final _maxBidsController = TextEditingController(text: '5');
  bool _revealBids = false;
  bool _allowSamePlayerBids = true;
  String _tieBreaker = 'budget';
  int _playersPerTurnP = 3;
  int _playersPerTurnD = 5;
  int _playersPerTurnC = 5;
  int _playersPerTurnA = 3;
  int _turnDurationHours = 24;

  String get _auctionType => _league?.auctionType ?? 'classic';

  @override
  void initState() {
    super.initState();
    if (widget.league != null) {
      _league = widget.league;
      _loadConfig();
    } else {
      _loadLeague();
    }
  }

  Future<void> _loadLeague() async {
    try {
      final league = await context.read<LeagueService>().getLeague(widget.leagueId);
      if (mounted) {
        setState(() => _league = league);
        _loadConfig();
      }
    } catch (_) {
      if (mounted) setState(() {
        _league = FantasyLeagueModel(id: widget.leagueId, name: '', leagueType: 'private');
        _loading = false;
      });
    }
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<AuctionRandomService>().getConfig(widget.leagueId);
      if (!mounted) return;
      final auctionType = data['auction_type'] as String? ?? 'classic';
      final astaStarted = data['asta_started'] as bool? ?? false;
      final config = data['config'] as Map<String, dynamic>?;
      setState(() {
        _config = config;
        _astaStarted = astaStarted;
        if (_league == null) _league = FantasyLeagueModel(id: widget.leagueId, name: '', leagueType: 'private', auctionType: auctionType);
        if (config != null) {
          _budgetController.text = '${config['budget_per_team'] ?? 500}';
          _maxPlayersController.text = '${config['max_roster_size'] ?? 25}';
          _minGkController.text = '${config['min_goalkeepers'] ?? 3}';
          _minDefController.text = '${config['min_defenders'] ?? 8}';
          _minMidController.text = '${config['min_midfielders'] ?? 8}';
          _minFwdController.text = '${config['min_attackers'] ?? 6}';
          _basePriceController.text = '${config['base_price'] ?? 1}';
          _bidTimerSeconds = config['bid_timer_seconds'] as int? ?? 60;
          _minRaiseController.text = '${config['min_raise'] ?? 1}';
          _callOrder = config['call_order'] as String? ?? 'random';
          _allowNomination = config['allow_nomination'] as bool? ?? true;
          _pauseController.text = '${config['pause_between_players'] ?? 10}';
          _roundsCountController.text = '${config['rounds_count'] ?? 3}';
          _maxBidsController.text = '${config['max_bids_per_round'] ?? 5}';
          _revealBids = config['reveal_bids'] as bool? ?? false;
          _allowSamePlayerBids = config['allow_same_player_bids'] as bool? ?? true;
          _tieBreaker = config['tie_breaker'] as String? ?? 'budget';
          _playersPerTurnP = config['players_per_turn_p'] as int? ?? 3;
          _playersPerTurnD = config['players_per_turn_d'] as int? ?? 5;
          _playersPerTurnC = config['players_per_turn_c'] as int? ?? 5;
          _playersPerTurnA = config['players_per_turn_a'] as int? ?? 3;
          _turnDurationHours = config['turn_duration_hours'] as int? ?? 24;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _maxPlayersController.dispose();
    _minGkController.dispose();
    _minDefController.dispose();
    _minMidController.dispose();
    _minFwdController.dispose();
    _basePriceController.dispose();
    _minRaiseController.dispose();
    _pauseController.dispose();
    _roundsCountController.dispose();
    _maxBidsController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final budget = int.tryParse(_budgetController.text.trim()) ?? 500;
    if (budget < 1) {
      setState(() => _error = 'Budget non valido');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await context.read<AuctionRandomService>().configure(
        widget.leagueId,
        budgetPerTeam: budget,
        maxRosterSize: int.tryParse(_maxPlayersController.text.trim()) ?? 25,
        minGoalkeepers: int.tryParse(_minGkController.text.trim()) ?? 3,
        minDefenders: int.tryParse(_minDefController.text.trim()) ?? 8,
        minMidfielders: int.tryParse(_minMidController.text.trim()) ?? 8,
        minAttackers: int.tryParse(_minFwdController.text.trim()) ?? 6,
        basePrice: int.tryParse(_basePriceController.text.trim()) ?? 1,
        playersPerTurnP: _playersPerTurnP,
        playersPerTurnD: _playersPerTurnD,
        playersPerTurnC: _playersPerTurnC,
        playersPerTurnA: _playersPerTurnA,
        turnDurationHours: _turnDurationHours,
        bidTimerSeconds: _bidTimerSeconds,
        minRaise: int.tryParse(_minRaiseController.text.trim()),
        callOrder: _callOrder,
        allowNomination: _allowNomination,
        pauseBetweenPlayers: int.tryParse(_pauseController.text.trim()),
        roundsCount: int.tryParse(_roundsCountController.text.trim()),
        maxBidsPerRound: int.tryParse(_maxBidsController.text.trim()),
        revealBids: _revealBids,
        allowSamePlayerBids: _allowSamePlayerBids,
        tieBreaker: _tieBreaker,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurazione salvata.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _startAuction() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });
    try {
      await context.read<LeagueService>().startLeague(widget.leagueId);
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asta avviata. Notifiche inviate a tutti i partecipanti.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _resetAsta() async {
    setState(() {
      _loadingReset = true;
      _error = null;
    });
    try {
      await context.read<LeagueService>().resetAsta(widget.leagueId);
      if (!mounted) return;
      await _loadLeague();
      if (!mounted) return;
      await _loadConfig();
      if (!mounted) return;
      setState(() => _loadingReset = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asta resettata. Puoi avviare di nuovo l\'asta.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _loadingReset = false;
        });
      }
    }
  }

  Widget _buildNumberField(String label, TextEditingController controller, {required IconData icon, String? suffix}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(suffix, style: GoogleFonts.poppins(fontSize: 11, color: _kTextGrey)),
        ],
      ],
    );
  }

  Widget _buildSwitchField(String label, bool value, {required IconData icon, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _kPrimary,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, {required List<String> labels, required IconData icon, required ValueChanged<String> onChanged}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            items: List.generate(options.length, (i) => DropdownMenuItem(value: options[i], child: Text(labels[i]))),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField(String label, int value, List<int> options, {required IconData icon, String? suffix, required ValueChanged<int> onChanged}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            items: options.map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(suffix, style: GoogleFonts.poppins(fontSize: 11, color: _kTextGrey)),
        ],
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FantastarBackground(
          child: SafeArea(
            child: _loading || _league == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        _buildBadgeTipoAsta(),
                        const SizedBox(height: 24),
                        Text(
                          'Impostazioni Rosa',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          children: [
                            _buildNumberField('Budget per squadra', _budgetController, icon: Icons.account_balance_wallet),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Max giocatori per squadra', _maxPlayersController, icon: Icons.group),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Portieri (min)', _minGkController, icon: Icons.sports_handball),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Difensori (min)', _minDefController, icon: Icons.shield),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Centrocampisti (min)', _minMidController, icon: Icons.swap_horiz),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Attaccanti (min)', _minFwdController, icon: Icons.sports_soccer),
                            const Divider(color: _kBorder, height: 24),
                            _buildNumberField('Prezzo base', _basePriceController, icon: Icons.sell),
                          ],
                        ),
                        if (_auctionType == 'classic') ..._buildSezioneClassica(),
                        if (_auctionType == 'random') ..._buildSezioneBusteChiuse(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 32),
                        if (_astaStarted) ...[
                          Text(
                            'La lega è già stata avviata',
                            style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          FantastarButton(
                            label: 'Resetta asta',
                            onPressed: _loadingReset ? null : _resetAsta,
                            loading: _loadingReset,
                            accentColor: _kAccentMagenta,
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.save, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Salva Configurazione',
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isStarting ? null : _startAuction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kAccentMagenta,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isStarting
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Avvia Asta',
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSezioneClassica() {
    return [
      const SizedBox(height: 24),
      Text(
        'Impostazioni Asta Classica',
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark),
      ),
      const SizedBox(height: 12),
      _card(
        children: [
          _buildPickerField('Timer rilancio', _bidTimerSeconds, const [30, 45, 60, 90, 120], icon: Icons.timer, onChanged: (v) => setState(() => _bidTimerSeconds = v)),
          const Divider(color: _kBorder, height: 24),
          _buildNumberField('Rilancio minimo', _minRaiseController, icon: Icons.trending_up),
          const Divider(color: _kBorder, height: 24),
          _buildDropdownField('Ordine chiamata', _callOrder, ['random', 'round_robin', 'snake'], labels: const ['Casuale', 'A turno', 'Snake'], icon: Icons.format_list_numbered, onChanged: (v) => setState(() => _callOrder = v)),
          const Divider(color: _kBorder, height: 24),
          _buildSwitchField('Utente nomina il giocatore', _allowNomination, icon: Icons.record_voice_over, onChanged: (v) => setState(() => _allowNomination = v)),
          const Divider(color: _kBorder, height: 24),
          _buildNumberField('Pausa tra giocatori', _pauseController, icon: Icons.pause_circle),
        ],
      ),
    ];
  }

  List<Widget> _buildSezioneBusteChiuse() {
    return [
      const SizedBox(height: 24),
      Text(
        'Impostazioni Buste Chiuse',
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark),
      ),
      const SizedBox(height: 12),
      _card(
        children: [
          _buildNumberField('Numero turni', _roundsCountController, icon: Icons.repeat),
          const Divider(color: _kBorder, height: 24),
          _buildNumberField('Max offerte per turno', _maxBidsController, icon: Icons.ballot),
          const Divider(color: _kBorder, height: 24),
          _buildSwitchField('Mostra offerte dopo assegnazione', _revealBids, icon: Icons.visibility, onChanged: (v) => setState(() => _revealBids = v)),
          const Divider(color: _kBorder, height: 24),
          _buildSwitchField('Più utenti sullo stesso giocatore', _allowSamePlayerBids, icon: Icons.people, onChanged: (v) => setState(() => _allowSamePlayerBids = v)),
          const Divider(color: _kBorder, height: 24),
          _buildDropdownField('Criterio spareggio', _tieBreaker, ['budget', 'random'], labels: const ['Chi ha più budget', 'Casuale'], icon: Icons.compare_arrows, onChanged: (v) => setState(() => _tieBreaker = v)),
        ],
      ),
    ];
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            'Configura Asta',
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
    );
  }

  Widget _buildBadgeTipoAsta() {
    final isClassic = _auctionType == 'classic';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isClassic ? Icons.gavel : Icons.mark_email_read, size: 26, color: _kPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClassic ? 'Asta Classica' : 'Buste Chiuse',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: _kTextDark),
                ),
                const SizedBox(height: 2),
                Text(
                  isClassic
                      ? 'A rilancio con timer — il miglior offerente vince'
                      : 'Offerte segrete — chi offre di più si aggiudica il giocatore',
                  style: GoogleFonts.poppins(fontSize: 12, color: _kTextGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

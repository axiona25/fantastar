import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/player_avatar.dart';
import '../../services/auction_random_service.dart';

const Color _kAccentMagenta = Color(0xFFE91E8C);

class AuctionTurnScreen extends StatefulWidget {
  const AuctionTurnScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<AuctionTurnScreen> createState() => _AuctionTurnScreenState();
}

class _AuctionTurnScreenState extends State<AuctionTurnScreen> {
  Map<String, dynamic>? _turn;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    if (seconds <= 0) return;
    _secondsLeft = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, 999999);
      });
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final data = await context.read<AuctionRandomService>().getCurrentTurn(widget.leagueId);
      if (mounted) {
        setState(() {
          _turn = data;
          _loading = false;
          _error = data == null ? 'Nessun turno attivo' : null;
          if (data != null && data['seconds_remaining'] != null) {
            final sec = data['seconds_remaining'] as int;
            if (sec != _secondsLeft) _startCountdown(sec);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = userFriendlyErrorMessage(e);
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
                      : _error != null || _turn == null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _error ?? 'Nessun turno attivo',
                                  style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textGrey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
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
    final roleLabel = _roleLabel(_turn?['role'] as String?);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Turno ${_turn?['turn_number'] ?? '?'} – $roleLabel',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  if (_turn != null && _secondsLeft >= 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatCountdown(_secondsLeft),
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _kAccentMagenta),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final players = _turn!['players'] as List<dynamic>? ?? [];
    final myBudget = _turn!['my_budget_remaining'] as num?;
    final configBudget = _turn!['config_budget'] as int? ?? 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Fai la tua offerta (busta chiusa). Solo tu vedi la tua offerta.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: players.length,
            itemBuilder: (context, i) {
              final p = players[i] as Map<String, dynamic>;
              return _PlayerCard(
                leagueId: widget.leagueId,
                player: p,
                onBidSent: _load,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          color: AppColors.cardBg,
          child: SafeArea(
            top: false,
            child: Text(
              'Il tuo budget: ${myBudget?.toInt() ?? 0}/$configBudget crediti',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'P': return 'Portieri';
      case 'D': return 'Difensori';
      case 'C': return 'Centrocampisti';
      case 'A': return 'Attaccanti';
      default: return role ?? '–';
    }
  }
}

class _PlayerCard extends StatefulWidget {
  const _PlayerCard({required this.leagueId, required this.player, required this.onBidSent});

  final String leagueId;
  final Map<String, dynamic> player;
  final VoidCallback onBidSent;

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  final _amountController = TextEditingController();
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    final myBid = widget.player['my_bid'];
    if (myBid != null) _amountController.text = myBid.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sendBid() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _sendError = 'Inserisci almeno 1 credito');
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await context.read<AuctionRandomService>().placeBid(widget.leagueId, widget.player['player_id'] as int, amount);
      if (mounted) {
        setState(() => _sending = false);
        widget.onBidSent();
      }
    } catch (e) {
      if (mounted) setState(() {
        _sending = false;
        _sendError = userFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.player['name'] as String? ?? '–';
    final position = widget.player['position'] as String? ?? '–';
    final realTeam = widget.player['real_team'] as String?;
    final initialPrice = (widget.player['initial_price'] as num?)?.toDouble() ?? 1;
    final playerId = (widget.player['player_id'] ?? widget.player['id']) as int? ?? 0;
    final myBid = widget.player['my_bid'];

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
          Row(
            children: [
              PlayerAvatar(
                playerId: playerId,
                role: position,
                playerName: name,
                teamColor: getTeamColor(realTeam),
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    Text('$position${realTeam != null ? ' · $realTeam' : ''}', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey)),
                    Text('Quotazione: ${initialPrice.toInt()} cr', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (myBid != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('La tua offerta: $myBid crediti', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kAccentMagenta)),
            ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Offerta',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: _kAccentMagenta,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _sending ? null : _sendBid,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _sending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : Text('Offri', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          if (_sendError != null) ...[
            const SizedBox(height: 8),
            Text(_sendError!, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

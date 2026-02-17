import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/auction.dart';
import '../../widgets/player_avatar.dart';
import '../../models/standing.dart';
import '../../providers/auth_provider.dart';
import '../../services/auction_service.dart';
import '../../services/league_service.dart';
import '../../services/websocket_service.dart';
import 'auction_player_selection_screen.dart';

/// Pagina Asta Live: sfondo tavolo, stemmi sulle sedie, card giocatore al centro, UI timer/budget/rilancio.
class AuctionLiveScreen extends StatefulWidget {
  const AuctionLiveScreen({super.key, required this.leagueId, this.auctionType = 'classic'});

  final String leagueId;
  final String auctionType;

  @override
  State<AuctionLiveScreen> createState() => _AuctionLiveScreenState();
}

class _AuctionLiveScreenState extends State<AuctionLiveScreen> {
  AuctionStatusModel? _status;
  List<StandingModel> _standings = [];
  bool _loading = true;
  Timer? _pollTimer;
  Timer? _localTimer;
  Timer? _seatPollTimer;
  Timer? _heartbeatTimer;
  int? _timerSeconds;
  final WebSocketService _ws = WebSocketService();
  final TextEditingController _sealedBidController = TextEditingController();
  String? _lastWinnerId;
  Set<String> _onlineUserIds = {};

  /// Sedie tavolo: join all'apertura, leave alla chiusura, polling 3s, heartbeat 10s.
  int? _mySeatNumber;
  String? _myTeamId; // UUID della mia squadra (per confronto badge isMe)
  List<Map<String, dynamic>> _seats = [];
  int _maxSeats = 8;

  /// Portfolio / budget in tempo reale.
  int _initialBudget = 500;
  int _totalSpent = 0;
  int _remainingBudget = 500;
  int _totalPlayers = 0;
  int _maxPlayers = 25;
  Map<String, int> _roleCounts = {'P': 0, 'D': 0, 'C': 0, 'A': 0};
  Map<String, int> _minRoles = {'P': 3, 'D': 8, 'C': 8, 'A': 6};
  List<Map<String, dynamic>> _myPurchases = [];
  List<Map<String, dynamic>> _allPortfolios = [];

  /// Cache-buster per la carta coperta: aggiornando questo si ricarica l'immagine dal backend.
  int _cartaCacheBuster = 0;

  @override
  void initState() {
    super.initState();
    _cartaCacheBuster = DateTime.now().millisecondsSinceEpoch;
    debugPrint('🏁 AuctionLiveScreen initState - leagueId: ${widget.leagueId} (empty=${widget.leagueId.isEmpty})');
    _load();
    _joinAuctionAndFetchSeats();
    _fetchMyPortfolio();
    _fetchAllPortfolios();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _loadStatus();
    });
    _seatPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchSeats();
        _fetchAllPortfolios();
        _fetchMyPortfolio();
      }
    });
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _sendHeartbeat();
    });
    _connectWs();
  }

  Future<void> _fetchMyPortfolio() async {
    try {
      final data = await context.read<AuctionService>().getMyPortfolio(widget.leagueId);
      if (!mounted) return;
      setState(() {
        _initialBudget = data['initial_budget'] as int? ?? 500;
        _totalSpent = data['total_spent'] as int? ?? 0;
        _remainingBudget = data['remaining'] as int? ?? 500;
        _totalPlayers = data['total_players'] as int? ?? 0;
        _maxPlayers = data['max_players'] as int? ?? 25;
        _roleCounts = Map<String, int>.from((data['role_counts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? _roleCounts);
        _minRoles = Map<String, int>.from((data['min_roles'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? _minRoles);
        _myPurchases = List<Map<String, dynamic>>.from(data['purchases'] as List<dynamic>? ?? []);
      });
    } catch (e) {
      debugPrint('Errore fetch portfolio: $e');
    }
  }

  Future<void> _fetchAllPortfolios() async {
    try {
      final list = await context.read<AuctionService>().getAllPortfolios(widget.leagueId);
      if (!mounted) return;
      setState(() => _allPortfolios = list);
    } catch (e) {
      debugPrint('Errore fetch portfolios: $e');
    }
  }

  Future<void> _joinAuctionAndFetchSeats() async {
    if (widget.leagueId.isEmpty) {
      debugPrint('❌ Join asta saltato: leagueId vuoto');
      return;
    }
    try {
      debugPrint('🎯 Chiamando join asta per league ${widget.leagueId}...');
      final data = await context.read<AuctionService>().joinAuction(widget.leagueId);
      if (!mounted) return;
      setState(() {
        _mySeatNumber = data['seat_number'] as int?;
        _myTeamId = data['my_team_id'] as String?;
        _seats = List<Map<String, dynamic>>.from(data['seats'] as List<dynamic>? ?? []);
      });
      debugPrint('🎯 Join ok: sedia $_mySeatNumber, sedie occupate: ${_seats.length}');
      await _fetchSeats();
    } catch (e) {
      debugPrint('❌ Errore join asta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore ingresso asta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchSeats() async {
    try {
      final data = await context.read<AuctionService>().getAuctionSeats(widget.leagueId);
      if (!mounted) return;
      setState(() {
        _maxSeats = data['max_seats'] as int? ?? 8;
        _seats = List<Map<String, dynamic>>.from(data['seats'] as List<dynamic>? ?? []);
      });
    } catch (e) {
      debugPrint('Errore fetch sedie: $e');
    }
  }

  Future<void> _handleExitTap() async {
    final leave = await _showExitConfirmDialog();
    if (leave == true && mounted) {
      await _leaveAuction();
      context.pop();
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      await context.read<AuctionService>().sendAuctionHeartbeat(widget.leagueId);
    } catch (e) {
      debugPrint('Errore heartbeat: $e');
    }
  }

  Future<void> _leaveAuction() async {
    try {
      debugPrint('👋 Uscendo dall\'asta...');
      await context.read<AuctionService>().leaveAuction(widget.leagueId);
      debugPrint('👋 Leave completato');
    } catch (e) {
      debugPrint('❌ Errore leave asta: $e');
      // Non bloccare l'uscita anche se il leave fallisce
    }
  }

  void _connectWs() {
    final url = context.read<AuctionService>().auctionWsUrl(widget.leagueId);
    _ws.connect(url, onMessage: (data) {
      if (data is Map && mounted) _loadStatus();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadStatus(), _loadStandings()]);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStatus() async {
    try {
      final s = await context.read<AuctionService>().getStatus(widget.leagueId);
      if (!mounted) return;
      setState(() {
        _status = s;
        _timerSeconds = s.timerRemaining;
        _onlineUserIds = s.participants.map((e) => e.id).toSet();
        if (_localTimer == null || _localTimer!.isActive == false) _startLocalTimer();
      });
    } catch (_) {}
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status == null) return;
      final t = _timerSeconds;
      if (t != null && t > 0) setState(() => _timerSeconds = t - 1);
    });
  }

  Future<void> _loadStandings() async {
    try {
      final list = await context.read<LeagueService>().getStandings(widget.leagueId);
      if (mounted) setState(() => _standings = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _seatPollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _localTimer?.cancel();
    _ws.disconnect();
    _sealedBidController.dispose();
    super.dispose();
  }

  String? _logoUrlForParticipant(String userId) {
    final s = _standings.cast<StandingModel?>().firstWhere(
          (e) => e?.userId == userId,
          orElse: () => null,
        );
    return s?.logoUrl;
  }

  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Esci dall\'asta?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: const Text(
          'La tua sedia al tavolo verrà liberata.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF5C6B7A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Resta',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Esci',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [amount]: se [isIncrement] è true è l'incremento (+1, +5), altrimenti è l'offerta totale (dialog).
  Future<void> _bid(double amount, {bool isIncrement = true}) async {
    final currentBid = _status?.currentBid?.amount ?? _status?.currentPlayer?.basePrice ?? 1.0;
    final newBid = isIncrement ? (currentBid + amount) : amount;
    if (newBid > _remainingBudget) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget insufficiente! Hai solo $_remainingBudget crediti'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final playersNeeded = _maxPlayers - _totalPlayers - 1;
    final minReserve = playersNeeded > 0 ? playersNeeded : 0;
    if ((_remainingBudget - newBid) < minReserve) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Devi tenere almeno $minReserve cr per i restanti $playersNeeded giocatori'),
          backgroundColor: const Color(0xFFFFB300),
        ),
      );
      return;
    }
    try {
      await context.read<AuctionService>().placeBid(widget.leagueId, newBid);
      if (mounted) _loadStatus();
    } catch (_) {}
  }

  void _pass() {
    // Passo = non offrire (opzionale: chiamata API se il backend supporta)
    _loadStatus();
  }

  void _showCustomBidDialog() {
    final currentBid = _status?.currentBid?.amount ?? _status?.currentPlayer?.basePrice ?? 1;
    final controller = TextEditingController(text: '${(currentBid + 1).toInt()}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offerta personalizzata'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Crediti'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(ctx);
              if (v != null && v > 0) _bid(v, isIncrement: false);
            },
            child: const Text('Offri'),
          ),
        ],
      ),
    );
  }

  void _submitSealedBid() {
    final v = int.tryParse(_sealedBidController.text.trim());
    if (v != null && v > 0) _bid(v.toDouble(), isIncrement: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _status == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white.withOpacity(0.8)),
        ),
      );
    }

    final status = _status;
    final currentPlayer = status?.currentPlayer;
    final currentBid = status?.currentBid;
    final participants = status?.participants ?? [];
    final currentBidderId = currentBid?.bidderId;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExitTap();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/tavolo_asta.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0A3D7A)),
              ),
              ..._buildTeamSeats(screenWidth, screenHeight),
              _buildCenterCard(currentPlayer, currentBid),
              _buildAuctionUI(currentPlayer, currentBid, currentBidderId),
            ],
          ),
        ),
      ),
    );
  }

  static const double _badgeSize = 68.0;
  static const double _badgeHalf = _badgeSize / 2;

  /// Ellisse lungo la linea esterna verde del tavolo: raggi più ampi per uniformità sull'ovale.
  List<Offset> _calculateSeatPositions(double screenWidth, double screenHeight, int totalSeats) {
    final centerX = screenWidth / 2;
    final centerY = screenHeight * 0.42;
    final radiusX = screenWidth * 0.42;
    final radiusY = screenHeight * 0.28;
    const startAngle = -math.pi / 2;
    final positions = <Offset>[];
    for (int i = 0; i < totalSeats; i++) {
      final angle = startAngle + (2 * math.pi * i / totalSeats);
      final x = centerX + radiusX * math.cos(angle);
      final y = centerY + radiusY * math.sin(angle);
      positions.add(Offset(x, y));
    }
    return positions;
  }

  List<Widget> _buildTeamSeats(double screenWidth, double screenHeight) {
    final positions = _calculateSeatPositions(screenWidth, screenHeight, _maxSeats);
    // Posizione in basso al centro: con startAngle = -pi/2, l'indice a metà ellisse è il bottom center
    final int bottomCenterIndex = positions.isEmpty ? 0 : _maxSeats ~/ 2;
    int shift = 0;
    if (_mySeatNumber != null && _mySeatNumber! >= 0 && _maxSeats > 0) {
      shift = (bottomCenterIndex - _mySeatNumber!) % _maxSeats;
      if (shift < 0) shift += _maxSeats;
    }
    final List<Widget> seats = [];
    for (int seatNum = 0; seatNum < _maxSeats; seatNum++) {
      final visualIndex = (seatNum + shift) % _maxSeats;
      if (visualIndex >= positions.length) continue;
      final pos = positions[visualIndex];
      Map<String, dynamic>? seatData;
      for (final s in _seats) {
        if ((s['seat_number'] as int?) == seatNum) {
          seatData = s;
          break;
        }
      }
      final isOccupied = seatData != null;
      final bool isMe = seatNum == _mySeatNumber;
      seats.add(
        Positioned(
          left: pos.dx - _badgeHalf,
          top: pos.dy - _badgeHalf,
          child: _buildSeatWidget(seatData, isOccupied, isMe, seatNum),
        ),
      );
    }
    return seats;
  }

  Widget _buildSeatWidget(Map<String, dynamic>? seatData, bool isOccupied, bool isMe, int seatNumber) {
    final badgeUrl = seatData?['badge_url'] ?? seatData?['logo_url'];
    final hasBadge = badgeUrl != null && badgeUrl.toString().isNotEmpty;
    // Blu navy (#0D47A1) per gli altri, magenta (#E91E8C) solo per me
    final Color seatColor = isOccupied
        ? (isMe ? const Color(0xFFE91E8C) : const Color(0xFF0D47A1))
        : const Color(0xFF1A1A2E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: _badgeSize,
          height: _badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOccupied ? seatColor : const Color(0xFF1A1A2E).withOpacity(0.4),
            border: Border.all(
              color: isMe
                  ? const Color(0xFFE91E8C)
                  : isOccupied
                      ? const Color(0xFFFFD700)
                      : Colors.white.withOpacity(0.12),
              width: isOccupied ? 3 : 1.5,
            ),
            boxShadow: isOccupied
                ? [
                    BoxShadow(
                      color: seatColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipOval(
            child: isOccupied && hasBadge
                ? Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.network(
                      badgeUrl.toString().startsWith('http') ? badgeUrl.toString() : '$kBackendOrigin$badgeUrl',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildSeatFallbackIcon(seatColor),
                    ),
                  )
                : isOccupied
                    ? _buildSeatFallbackIcon(seatColor)
                    : Icon(Icons.event_seat, size: 22, color: Colors.white.withOpacity(0.15)),
          ),
        ),
        const SizedBox(height: 3),
        if (isOccupied && seatData != null)
          _buildSeatInfoBox(seatData!, isMe),
      ],
    );
  }

  Widget _buildSeatFallbackIcon(Color bgColor) {
    return Container(
      color: bgColor,
      child: const Icon(Icons.shield, color: Colors.white, size: 40),
    );
  }

  /// Info sotto il badge: Nome Squadra, @username, crediti spesi/totale.
  Widget _buildSeatInfoBox(Map<String, dynamic> seatData, bool isMe) {
    final budgetTotal = (seatData['budget_total'] as num?)?.toInt() ?? 500;
    final budgetSpent = (seatData['budget_spent'] as num?)?.toInt() ?? 0;
    final creditColor = budgetTotal > 0 && budgetSpent > (budgetTotal * 0.8)
        ? const Color(0xFFFF5252)
        : const Color(0xFFFFD700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFE91E8C).withOpacity(0.85)
            : Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (seatData['team_name'] as String?) ?? '???',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '@${seatData['username'] ?? ''}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$budgetSpent/$budgetTotal',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: creditColor,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Card al centro del tavolo con effetto 3D: parte superiore inclinata verso lo schermo.
  static const double _cardTiltRad = 0.14; // ~8°: top verso viewer

  Widget _buildCenterCard(AuctionStatusPlayer? currentPlayer, AuctionStatusBid? currentBid) {
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0.0, -0.28),
        child: Transform.translate(
          offset: const Offset(0, -10),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-_cardTiltRad),
            child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: currentPlayer == null ? _buildAuctionCardPlaceholder() : _buildPlayerShowcaseCard(currentPlayer, currentBid),
          ),
        ),
      ),
      ),
    );
  }

  /// Placeholder al centro: carta coperta sotto; icona e testo sopra, nella finestra libera della carta (nessuno sfondo che fuoriesce).
  Widget _buildAuctionCardPlaceholder() {
    const w = 178.0;
    const h = 252.0;
    const radius = 16.0;
    final cartaUrl = '$kBackendOrigin/static/media/Sfondi/carta.png?v=$_cartaCacheBuster';

    return GestureDetector(
      onTap: _openPlayerSelection,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // Carta coperta sotto (solo immagine, nessuno sfondo bianco che fuoriesce)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.network(
                  cartaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Icona e testo sopra la carta, centrati nella finestra libera (leggermente sopra il centro per allinearsi alla finestra)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.0, -0.22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                          border: Border.all(
                            color: const Color(0xFF0D47A1).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tocca per chiamare\nun giocatore',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seleziona dal listone',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0D47A1).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayerSelection() async {
    List<int> purchasedIds = [];
    try {
      purchasedIds = await context.read<AuctionService>().getHistory(widget.leagueId)
          .then((items) => items.map((e) => e.playerId).toList());
    } catch (e) {
      debugPrint('Storico asta non disponibile (asta non attiva?): $e');
      // Apri comunque il listone con lista vuota di aggiudicati
    }
    if (!mounted) return;
    final selectedPlayer = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => AuctionPlayerSelectionScreen(
          leagueId: widget.leagueId,
          purchasedPlayerIds: purchasedIds,
        ),
      ),
    );
    if (selectedPlayer != null && mounted) {
      _nominatePlayer(selectedPlayer);
    }
  }

  void _nominatePlayer(Map<String, dynamic> player) async {
    final playerId = (player['id'] as num?)?.toInt() ?? (player['id'] as int?);
    if (playerId == null) return;
    try {
      await context.read<AuctionService>().nominate(widget.leagueId, playerId);
      if (!mounted) return;
      // Aggiorna subito lo status così la card con la foto del giocatore appare al centro
      await _loadStatus();
      if (!mounted) return;
      // Secondo refresh dopo breve attesa (il backend può metterci un attimo ad aggiornare)
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giocatore chiamato all\'asta')),
        );
      }
    } catch (e) {
      debugPrint('Errore nomina: $e');
      if (mounted) {
        final msg = e.toString();
        final isNoActiveAuction = msg.contains('Nessuna asta attiva') || msg.contains('asta attiva');
        final userMsg = isNoActiveAuction
            ? 'L\'asta non è attiva. Avvia la sessione asta (pulsante Avvia) per poter chiamare un giocatore.'
            : 'Errore: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Gettone sotto la foto: logo circolare squadra Serie A (o sigla come fallback).
  Widget _buildAuctionCardGettone(AuctionStatusPlayer currentPlayer) {
    final logoUrl = currentPlayer.realTeamLogoUrl;
    final shortName = currentPlayer.realTeamShortName ?? '?';
    final hasLogo = logoUrl != null && logoUrl.toString().trim().isNotEmpty;
    final url = hasLogo
        ? (logoUrl.toString().startsWith('http') ? logoUrl : '$kBackendOrigin$logoUrl')
        : null;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0D47A1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    shortName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  shortName,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
              ),
      ),
    );
  }

  /// Badge sotto il gettone: nome giocatore su sfondo blu.
  Widget _buildAuctionCardBadge(String playerName) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Text(
        playerName,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPlayerShowcaseCard(AuctionStatusPlayer currentPlayer, AuctionStatusBid? currentBid) {
    final price = (currentBid?.amount ?? currentPlayer.basePrice).toInt();

    return Container(
      key: ValueKey(currentPlayer.id),
          width: 178,
          height: 252,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFD700),
                Color(0xFFB8860B),
                Color(0xFFFFD700),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A3D7A).withOpacity(0.95),
                  const Color(0xFF0D47A1).withOpacity(0.95),
                  const Color(0xFF1A1A2E),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(currentPlayer.role),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    _getRoleLabel(currentPlayer.role),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: PlayerAvatar(
                      playerId: currentPlayer.id,
                      role: currentPlayer.role,
                      playerName: currentPlayer.name,
                      size: 140,
                      showRoleBadge: true,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildAuctionCardGettone(currentPlayer),
                const SizedBox(height: 4),
                _buildAuctionCardBadge(currentPlayer.name),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    '$price cr',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _playerPlaceholder() {
    return Container(
      color: const Color(0xFFE0E8F2),
      child: const Icon(Icons.person, size: 50, color: Color(0xFF0D47A1)),
    );
  }

  static Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'P':
        return const Color(0xFFFF8F00);
      case 'D':
        return const Color(0xFF2E7D32);
      case 'C':
        return const Color(0xFF1565C0);
      case 'A':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF5C6B7A);
    }
  }

  static String _getRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'P':
        return 'PORTIERE';
      case 'D':
        return 'DIFENSORE';
      case 'C':
        return 'CENTROCAMPISTA';
      case 'A':
        return 'ATTACCANTE';
      default:
        return role;
    }
  }

  Widget _buildAuctionUI(AuctionStatusPlayer? currentPlayer, AuctionStatusBid? currentBid, String? currentBidderId) {
    final timerSeconds = _timerSeconds ?? 0;
    final currentBidderName = currentBid?.bidder;
    final currentBidAmount = currentBid?.amount?.toInt();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _handleExitTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  ),
                ),
                const Spacer(),
                if (currentPlayer != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: timerSeconds <= 10 ? Colors.red.withOpacity(0.8) : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${timerSeconds}s',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _remainingBudget < 50
                          ? Colors.red.withOpacity(0.5)
                          : const Color(0xFFFFD700).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 16,
                            color: _remainingBudget < 50 ? Colors.red : const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: const Color(0xFF81D4FA), // celeste chiaro
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$_remainingBudget',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _remainingBudget < 50 ? Colors.red : Colors.white,
                            ),
                          ),
                          Text(
                            '$_totalPlayers/$_maxPlayers',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (currentPlayer != null && widget.auctionType == 'classic')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  if (currentBidderName != null && currentBidAmount != null)
                    Text(
                      'Offerta: $currentBidderName — $currentBidAmount cr',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pass,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              'PASSO',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _bid(1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '+1',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _bid(5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E8C),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '+5',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showCustomBidDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'BID',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (currentPlayer != null && widget.auctionType == 'random')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sealedBidController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'La tua offerta',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submitSealedBid,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'OFFRI',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

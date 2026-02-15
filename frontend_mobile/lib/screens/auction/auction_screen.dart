import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/auction.dart';
import '../../widgets/player_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/auction_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/error_utils.dart';

/// Asta live: timer, giocatore, offerta attuale, partecipanti, pulsante OFFRI, polling ogni 3s.
class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  AuctionStatusModel? _status;
  List<AuctionHistoryItemModel> _history = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  Timer? _localTimer;
  int? _serverTimerRemaining; // countdown locale aggiornato ogni 1s; il polling ogni 3s riallinea
  final WebSocketService _ws = WebSocketService();
  String? _lastAssignedMessage;
  bool _showAssignedOverlay = false;
  String? _overlayType; // 'me' | 'other' | 'no_sale'
  String? _overlaySubtitle; // messaggio seconda riga
  bool _overlayFadeOut = false;
  String? _previousCategory; // per rilevare cambio categoria
  bool _showCategoryChangeOverlay = false;
  String? _categoryChangeOldLabel;
  String? _categoryChangeNewLabel;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadHistory();
    _startPolling();
    _connectWs();
  }

  void _connectWs() {
    final url = context.read<AuctionService>().auctionWsUrl(widget.leagueId);
    _ws.connect(url, onMessage: _handleWsMessage);
  }

  void _handleWsMessage(dynamic data) {
    if (data is! Map) return;
    final event = data['event'] as String?;
    if (event == 'nominate' || event == 'bid' || event == 'assigned' || event == 'expired_no_sale' || event == 'category_change') {
      if (mounted) _loadStatus();
    }
    if (event == 'assigned' && mounted) {
      final playerName = data['player_name'] as String? ?? '';
      final winnerName = data['winner_name'] as String? ?? '';
      final winnerId = data['winner_id'] as String? ?? '';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final userId = context.read<AuthProvider>().user?.id?.toString() ?? '';
      final isMe = winnerId.isNotEmpty && winnerId.toString() == userId;
      setState(() {
        _lastAssignedMessage = isMe ? 'Hai vinto $playerName per ${amount.toInt()} cr!' : '$winnerName vince $playerName per ${amount.toInt()} cr';
        _overlayType = isMe ? 'me' : 'other';
        _overlaySubtitle = _lastAssignedMessage;
        _showAssignedOverlay = true;
      });
      _scheduleOverlayDismiss();
    }
    if (event == 'expired_no_sale' && mounted) {
      final playerName = data['player_name'] as String? ?? '';
      setState(() {
        _lastAssignedMessage = '⏰ Nessuna offerta';
        _overlayType = 'no_sale';
        _overlaySubtitle = '$playerName torna disponibile';
        _showAssignedOverlay = true;
      });
      _scheduleOverlayDismiss();
    }
  }

  void _scheduleOverlayDismiss() {
    _overlayFadeOut = false;
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) setState(() => _overlayFadeOut = true);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAssignedOverlay = false;
          _lastAssignedMessage = null;
          _overlayType = null;
          _overlaySubtitle = null;
          _overlayFadeOut = false;
        });
        _loadStatus();
        _loadHistory();
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadStatus();
    });
  }

  Future<void> _loadStatus() async {
    final leagueId = widget.leagueId;
    debugPrint('=== AUCTION: inizio caricamento ===');
    try {
      final auth = context.read<AuthProvider>().authService;
      final token = await auth.getAccessToken();
      debugPrint('AUCTION token: ${token != null ? "OK (${token.length} chars)" : "NULL!"}');
      debugPrint('AUCTION leagueId: $leagueId (type: ${leagueId.runtimeType})');

      final service = context.read<AuctionService>();
      final result = await service.getStatus(leagueId);
      debugPrint('AUCTION status OK: ${result.status}');

      if (mounted) {
        final hadPlayer = _status?.currentPlayer != null;
        final hasPlayerNow = result.currentPlayer != null;
        if (hadPlayer && !hasPlayerNow && !_showAssignedOverlay) {
          final prev = _status!;
          final playerName = prev.currentPlayer!.name;
          final bid = prev.currentBid;
          final userId = context.read<AuthProvider>().user?.id?.toString() ?? '';
          if (bid != null && bid.bidderId.toString() == userId) {
            _overlayType = 'me';
            _overlaySubtitle = 'Hai vinto $playerName per ${bid.amount.toInt()} cr!';
          } else if (bid != null) {
            _overlayType = 'other';
            _overlaySubtitle = '${bid.bidder} vince $playerName per ${bid.amount.toInt()} cr';
          } else {
            _overlayType = 'no_sale';
            _overlaySubtitle = '$playerName torna disponibile';
          }
          _lastAssignedMessage = _overlayType == 'no_sale' ? '⏰ Nessuna offerta' : '🏆 AGGIUDICATO!';
          _showAssignedOverlay = true;
          _scheduleOverlayDismiss();
          _localTimer?.cancel();
          _serverTimerRemaining = null;
        }
        final newCategory = result.currentCategory;
        final hadCategory = _previousCategory != null;
        final categoryChanged = hadCategory && newCategory != null && _previousCategory != newCategory;
        String? oldLabel;
        String? newLabel;
        if (categoryChanged) {
          oldLabel = AuctionStatusModel.categoryLabel(_previousCategory);
          newLabel = AuctionStatusModel.categoryLabel(newCategory);
        }
        if (newCategory != null) _previousCategory = newCategory;
        setState(() {
          _status = result;
          _error = null;
          _loading = false;
          _serverTimerRemaining = result.currentPlayer != null ? result.timerRemaining : null;
          if (categoryChanged) {
            _showCategoryChangeOverlay = true;
            _categoryChangeOldLabel = oldLabel;
            _categoryChangeNewLabel = newLabel;
          }
        });
        if (categoryChanged) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() {
              _showCategoryChangeOverlay = false;
              _categoryChangeOldLabel = null;
              _categoryChangeNewLabel = null;
            });
          });
        }
        if (result.currentPlayer != null && result.timerRemaining != null) {
          _startLocalTimer();
        } else {
          _localTimer?.cancel();
        }
      }
    } catch (e, stack) {
      debugPrint('=== AUCTION ERROR ===');
      debugPrint('$e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _status = null;
          _error = 'Errore caricamento stato asta';
          _loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_serverTimerRemaining != null && _serverTimerRemaining! > 0) {
          _serverTimerRemaining = _serverTimerRemaining! - 1;
        } else if (_serverTimerRemaining == 0) {
          timer.cancel();
          _localTimer = null;
        }
      });
    });
  }

  Future<void> _loadHistory() async {
    try {
      final list = await context.read<AuctionService>().getHistory(widget.leagueId);
      if (mounted) setState(() => _history = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _localTimer?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  String? get _currentUserId => context.read<AuthProvider>().user?.id;

  bool get _isMyBid {
    if (_status?.currentBid == null || _currentUserId == null) return false;
    return _status!.currentBid!.bidderId == _currentUserId;
  }

  bool get _canBid {
    if (_status == null || _currentUserId == null) return false;
    final userId = _currentUserId!.toString();
    final eligible = _status!.eligibleBidders.map((e) => e.toString()).toList();
    if (!eligible.contains(userId)) return false;
    try {
      final p = _status!.participants.firstWhere((p) => p.id.toString() == userId);
      return p.canBid;
    } catch (_) {
      return false;
    }
  }

  double get _minNextBid {
    final bid = _status?.currentBid?.amount ?? 0;
    final base = _status?.currentPlayer?.basePrice ?? 1;
    if (bid < base) return base;
    return bid + 1;
  }

  Future<void> _placeBid(double amount) async {
    setState(() => _error = null);
    try {
      HapticFeedback.mediumImpact();
      await context.read<AuctionService>().placeBid(widget.leagueId, amount);
      if (mounted) await _loadStatus();
    } catch (e) {
      if (mounted) {
        setState(() => _error = userFriendlyErrorMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leagues = context.watch<HomeProvider>().leagues.where((l) => l.id == widget.leagueId).toList();
    final league = leagues.isEmpty ? null : leagues.first;
    final isAdmin = league?.isAdminFor(context.watch<AuthProvider>().user?.id) ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(league?.name ?? 'Asta'),
        actions: [
          if ((_status?.status == 'active' || _status?.status == 'paused') && (_status?.isMyTurn == true)) ...[
            TextButton(
              onPressed: () => context.push('/league/${widget.leagueId}/players?mode=auction&category=${_status?.currentCategory ?? ""}'),
              child: const Text('Scegli giocatore'),
            ),
          ],
          if (isAdmin && (_status?.status == 'active' || _status?.status == 'paused')) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                try {
                  if (value == 'pause') {
                    await context.read<AuctionService>().pauseSession(widget.leagueId);
                  } else if (value == 'stop') {
                    await context.read<AuctionService>().stopSession(widget.leagueId);
                  }
                  if (mounted) _loadStatus();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pause', child: Text('Pausa asta')),
                const PopupMenuItem(value: 'stop', child: Text('Termina asta')),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadStatus();
              await _loadHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _loading && _status == null
                  ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                  : _buildContent(context, isAdmin),
            ),
          ),
          if (_showAssignedOverlay) _buildAssignedOverlay(context),
          if (_showCategoryChangeOverlay && _categoryChangeOldLabel != null && _categoryChangeNewLabel != null)
            _buildCategoryChangeOverlay(context),
        ],
      ),
    );
  }

  Widget _buildCategoryChangeOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 2)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅ Categoria completata!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Text('$_categoryChangeOldLabel completati!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white)),
                Text('Si passa ai $_categoryChangeNewLabel', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isAdmin) {
    if (_status == null) {
      return const Center(child: Text('Errore caricamento stato asta'));
    }
    if (_status!.status == 'idle' || _status!.status == 'completed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nessuna asta in corso.'),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                try {
                  await context.read<AuctionService>().startSession(widget.leagueId);
                  if (mounted) _loadStatus();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Avvia asta'),
            ),
          ],
          const SizedBox(height: 24),
          ..._historySection(),
        ],
      );
    }

    final hasPlayer = _status!.currentPlayer != null;
    final remaining = _serverTimerRemaining ?? _status!.timerRemaining;
    final showTimerBanner = hasPlayer && (remaining != null && remaining > 0);
    final isMyTurn = _status!.isMyTurn == true;
    final turnName = _status!.currentTurnUserName ?? '—';
    final categoryLabel = AuctionStatusModel.categoryLabel(_status!.currentCategory);
    final progressShort = _status!.categoryProgressShort;
    final progressText = _status!.categoryProgressText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status!.currentCategory != null && (_status!.status == 'active' || _status!.status == 'paused')) ...[
          _CategoryTurnBanner(
            categoryLabel: categoryLabel,
            progressShort: progressShort,
            progressText: progressText,
            turnName: turnName,
            isMyTurn: isMyTurn,
          ),
          const SizedBox(height: 16),
        ],
        if (_status!.isOnlyOneLeftInCategory == true) ...[
          _OnlyOneLeftBanner(categoryLabel: categoryLabel),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/league/${widget.leagueId}/players?mode=auction&category=${_status!.currentCategory ?? ""}'),
            icon: const Icon(Icons.person_search),
            label: Text('SCEGLI $categoryLabel'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green.shade700),
          ),
          const SizedBox(height: 16),
        ],
        if (showTimerBanner) ...[
          _AuctionTimer(seconds: remaining!, hasPlayer: true),
          const SizedBox(height: 16),
          _PlayerCard(player: _status!.currentPlayer!),
          const SizedBox(height: 16),
          _CurrentBidCard(bid: _status!.currentBid, isMyBid: _isMyBid),
          const SizedBox(height: 16),
          _ParticipantsSection(
            participants: _status!.participants,
            currentBidderId: _status?.currentBid?.bidderId,
            currentTurnUserId: _status?.currentTurnUserId,
            currentCategory: _status?.currentCategory,
          ),
          const SizedBox(height: 16),
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          _BidControls(
            minNextBid: _minNextBid,
            canBid: _canBid,
            onBid: _placeBid,
          ),
        ] else if (_status!.status == 'active' || _status!.status == 'paused' && _status!.isOnlyOneLeftInCategory != true) ...[
          const SizedBox(height: 24),
          Text(
            isMyTurn ? 'È il tuo turno! Scegli un giocatore da mettere all\'asta.' : 'Attendi che $turnName scelga...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isMyTurn ? FontWeight.bold : null,
              color: isMyTurn ? Colors.green.shade800 : null,
            ),
          ),
          if (isMyTurn) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/league/${widget.leagueId}/players?mode=auction&category=${_status!.currentCategory ?? ""}'),
              icon: const Icon(Icons.person_search),
              label: Text('SCEGLI $categoryLabel'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ],
        const SizedBox(height: 24),
        ..._historySection(),
      ],
    );
  }

  List<Widget> _historySection() {
    return [
      Text('Storico acquisti', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_history.isEmpty)
        const Text('(Nessun acquisto)')
      else
        ..._history.take(10).map((h) => ListTile(dense: true, title: Text(h.playerName), subtitle: Text('${h.teamName} — ${h.amount.toStringAsFixed(0)} cr'))),
    ];
  }

  Widget _buildAssignedOverlay(BuildContext context) {
    Color bgColor = Colors.grey;
    if (_overlayType == 'me') bgColor = Colors.green.shade700;
    if (_overlayType == 'other') bgColor = Colors.blue.shade700;
    if (_overlayType == 'no_sale') bgColor = Colors.grey.shade700;

    final title = _overlayType == 'no_sale' ? '⏰ Nessuna offerta' : '🏆 AGGIUDICATO!';
    final subtitle = _overlaySubtitle ?? _lastAssignedMessage ?? '';

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _overlayFadeOut ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTurnBanner extends StatelessWidget {
  const _CategoryTurnBanner({
    required this.categoryLabel,
    required this.progressShort,
    required this.progressText,
    required this.turnName,
    required this.isMyTurn,
  });

  final String categoryLabel;
  final String progressShort;
  final String progressText;
  final String turnName;
  final bool isMyTurn;

  static String _categoryEmoji(String label) {
    if (label.toUpperCase().startsWith('PORTIERI')) return '🟡';
    if (label.toUpperCase().startsWith('DIFENSORI')) return '🟢';
    if (label.toUpperCase().startsWith('CENTROCAMPISTI')) return '🔵';
    if (label.toUpperCase().startsWith('ATTACCANTI')) return '🔴';
    return '⚪';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMyTurnColor = isMyTurn ? Colors.amber.shade700 : null;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(_categoryEmoji(categoryLabel), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('$categoryLabel', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (progressShort.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('($progressShort completati)', style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isMyTurn ? Colors.green.shade50 : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: isMyTurn ? Border.all(color: Colors.green.shade700, width: 2) : null,
              ),
              child: Row(
                children: [
                  Icon(isMyTurn ? Icons.person : Icons.schedule, size: 20, color: isMyTurn ? Colors.green.shade700 : theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMyTurn ? 'È il tuo turno!' : 'Attendi che $turnName scelga...',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isMyTurn ? FontWeight.bold : null,
                        color: isMyTurn ? Colors.green.shade800 : null,
                      ),
                    ),
                  ),
                  if (isMyTurn) const Text('🟢', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuctionTimer extends StatefulWidget {
  const _AuctionTimer({required this.seconds, required this.hasPlayer});

  final int seconds;
  final bool hasPlayer;

  @override
  State<_AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<_AuctionTimer> {
  Timer? _blinkTimer;
  bool _blinkOn = true;

  @override
  void initState() {
    super.initState();
    if (widget.seconds < 5 && widget.seconds > 0 && widget.hasPlayer) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _blinkOn = !_blinkOn);
      });
    }
  }

  @override
  void didUpdateWidget(_AuctionTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds >= 5 && _blinkTimer != null) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
    } else if (widget.seconds < 5 && widget.seconds > 0 && widget.hasPlayer && _blinkTimer == null) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _blinkOn = !_blinkOn);
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seconds;
    final hasPlayer = widget.hasPlayer;
    Color bgColor = Colors.blue;
    const textColor = Colors.white;
    if (s <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(12)),
        child: Text('TEMPO SCADUTO!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      );
    }
    if (s < 5) {
      bgColor = Colors.red;
    } else if (s <= 10) {
      bgColor = Colors.orange;
    }
    final display = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    Widget child = Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '⏱️ $display',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 48),
      ),
    );
    if (s < 5 && s > 0 && hasPlayer) {
      child = AnimatedOpacity(opacity: _blinkOn ? 1.0 : 0.3, duration: const Duration(milliseconds: 500), child: child);
    }
    return child;
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player});

  final AuctionStatusPlayer player;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PlayerAvatar(
              cutoutUrl: player.cutoutUrl,
              photoUrl: player.photoUrl,
              playerName: player.name,
              role: player.role,
              teamColor: getTeamColor(player.team),
              size: 120,
            ),
            const SizedBox(height: 12),
            Text(player.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${player.role} · ${player.team ?? "—"}'),
            const SizedBox(height: 4),
            Text('Base: ${player.basePrice.toStringAsFixed(0)} cr', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CurrentBidCard extends StatelessWidget {
  const _CurrentBidCard({this.bid, required this.isMyBid});

  final AuctionStatusBid? bid;
  final bool isMyBid;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade700, width: 2)),
      color: isMyBid ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💰 Offerta attuale: ${bid?.amount.toStringAsFixed(0) ?? "—"} cr', style: Theme.of(context).textTheme.titleMedium),
            if (bid != null) Text('di ${bid!.bidder}', style: Theme.of(context).textTheme.bodyMedium),
            if (isMyBid && bid != null) Text('La tua offerta!', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green.shade800)),
          ],
        ),
      ),
    );
  }
}

class _OnlyOneLeftBanner extends StatelessWidget {
  const _OnlyOneLeftBanner({required this.categoryLabel});

  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.amber.shade700, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sei l\'ultimo!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                  Text('Acquisto diretto a prezzo base (1 cr). Scegli un $categoryLabel dalla lista.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.amber.shade900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({
    required this.participants,
    this.currentBidderId,
    this.currentTurnUserId,
    this.currentCategory,
  });

  final List<AuctionStatusParticipant> participants;
  final String? currentBidderId;
  final String? currentTurnUserId;
  final String? currentCategory;

  @override
  Widget build(BuildContext context) {
    final cat = currentCategory ?? 'CEN';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Partecipanti', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...participants.map((p) {
          IconData icon = Icons.check_circle_outline;
          Color? iconColor = Colors.grey;
          if (!p.canBid) {
            icon = Icons.cancel_outlined;
            iconColor = Colors.red;
          } else {
            iconColor = Colors.green;
          }
          final isLastBidder = p.id == currentBidderId;
          final isCurrentTurn = p.id == currentTurnUserId;
          final roleProgress = p.roleProgressText(cat);
          final completed = p.currentRoleRequired > 0 && p.currentRoleCompleted >= p.currentRoleRequired;
          return ListTile(
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 22),
                if (isCurrentTurn) const Padding(padding: EdgeInsets.only(left: 4), child: Text('🟢', style: TextStyle(fontSize: 14))),
              ],
            ),
            title: Row(
              children: [
                Expanded(child: Text('${p.name}  ${p.budget.toStringAsFixed(0)} cr  ${p.rosterCount}/25')),
                if (isLastBidder) const Text(' 📌'),
              ],
            ),
            subtitle: roleProgress.isNotEmpty
                ? Text(roleProgress, style: TextStyle(fontSize: 12, color: completed ? Colors.green.shade700 : null))
                : null,
          );
        }),
      ],
    );
  }
}

class _BidControls extends StatefulWidget {
  const _BidControls({required this.minNextBid, required this.canBid, required this.onBid});

  final double minNextBid;
  final bool canBid;
  final void Function(double amount) onBid;

  @override
  State<_BidControls> createState() => _BidControlsState();
}

class _BidControlsState extends State<_BidControls> {
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.minNextBid;
  }

  @override
  void didUpdateWidget(_BidControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minNextBid != oldWidget.minNextBid) _amount = widget.minNextBid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(onPressed: () => setState(() => _amount = (_amount - 1).clamp(1, 999)), icon: const Icon(Icons.remove)),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: Text('${_amount.toStringAsFixed(0)} cr', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 16),
            IconButton.filled(onPressed: () => setState(() => _amount = _amount + 1), icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.canBid ? () => widget.onBid(_amount) : null,
          icon: const Icon(Icons.gavel),
          label: Text('OFFRI ${_amount.toStringAsFixed(0)} cr'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        Text('Offerte rapide:', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(onPressed: widget.canBid ? () => widget.onBid(widget.minNextBid + 1) : null, child: const Text('+1')),
            TextButton(onPressed: widget.canBid ? () => widget.onBid(widget.minNextBid + 2) : null, child: const Text('+2')),
            TextButton(onPressed: widget.canBid ? () => widget.onBid(widget.minNextBid + 5) : null, child: const Text('+5')),
            TextButton(onPressed: widget.canBid ? () => widget.onBid(widget.minNextBid + 10) : null, child: const Text('+10')),
          ],
        ),
      ],
    );
  }
}

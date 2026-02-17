import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../services/league_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/fantastar_button.dart';
import '../../widgets/fantastar_input.dart';

/// Colore selezione (stemma, numero partecipanti, pallini): celeste chiaro.
const Color _kSelectionCeleste = Color(0xFF81D4FA); // light blue / celeste

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController(text: '500');
  final _badgePageController = PageController();
  /// Indice stemma selezionato nella lista badges da backend, o null se nessuno.
  int? _selectedBadgeIndex;
  int _currentBadgePage = 0;
  /// Solo numeri pari: 4, 6, 8, ..., 20. Index 2 = 8.
  static const List<int> _participantOptions = [4, 6, 8, 10, 12, 14, 16, 18, 20];
  int _numParticipants = 8;
  final FixedExtentScrollController _participantsScrollController = FixedExtentScrollController(initialItem: 2);
  int _startMatchday = 1;
  /// Giornata corrente Serie A (default per il picker).
  int _currentMatchday = 1;
  bool _isLoadingMatchday = true;
  final FixedExtentScrollController _startMatchdayScrollController = FixedExtentScrollController(initialItem: 0);
  bool _auctionRandom = false; // false = Classica, true = Random
  bool _loading = false;
  String? _error;

  int get _maxStartMatchday => 38 - ((_numParticipants - 1) * 2) + 1;
  int get _totalRounds => (_numParticipants - 1) * 2;

  /// Lista path stemmi da GET $kBackendOrigin/api/league-badges (senza /v1/).
  List<String> _badges = [];
  bool _badgesLoading = true;
  String? _badgesError;

  @override
  void initState() {
    super.initState();
    _loadBadges();
    _fetchCurrentMatchday();
  }

  /// Carica la giornata corrente Serie A (endpoint dedicato o da classifica) e imposta default picker.
  Future<void> _fetchCurrentMatchday() async {
    try {
      final response = await Dio().get('$kApiBaseUrl/standings/current-matchday');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final matchday = (data['current_matchday'] as num?)?.toInt() ?? 1;
        if (mounted) _applyCurrentMatchday(matchday);
        return;
      }
    } catch (_) {}
    try {
      final response = await Dio().get('$kApiBaseUrl/standings/serie-a');
      if (response.statusCode == 200 && response.data is List) {
        int maxPlayed = 1;
        for (final e in response.data as List) {
          final map = e as Map<String, dynamic>;
          final p = (map['played'] as num?)?.toInt() ?? 0;
          if (p > maxPlayed) maxPlayed = p;
        }
        if (mounted) _applyCurrentMatchday(maxPlayed);
        return;
      }
    } catch (_) {}
    if (mounted) _applyCurrentMatchday(1);
  }

  void _applyCurrentMatchday(int current) {
    final maxStart = _maxStartMatchday;
    final start = current.clamp(1, maxStart);
    setState(() {
      _currentMatchday = current;
      _startMatchday = start;
      _isLoadingMatchday = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = (start - 1).clamp(0, maxStart - 1);
      _startMatchdayScrollController.jumpToItem(index);
    });
  }

  Future<void> _loadBadges() async {
    setState(() {
      _badgesLoading = true;
      _badgesError = null;
    });
    try {
      final list = await _fetchLeagueBadges();
      if (mounted) {
        setState(() {
          _badges = list;
          _badgesLoading = false;
          _badgesError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _badgesLoading = false;
          _badgesError = 'Stemmi non disponibili';
        });
      }
    }
  }

  static Future<List<String>> _fetchLeagueBadges() async {
    final response = await Dio().get('$kBackendOrigin/api/league-badges');
    if (response.statusCode == 200 && response.data is List) {
      return List<String>.from(response.data as List);
    }
    return [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _badgePageController.dispose();
    _participantsScrollController.dispose();
    _startMatchdayScrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBadgeIndex == null) {
      setState(() => _error = 'Scegli uno stemma per la lega');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final budget = double.tryParse(_budgetController.text.trim()) ?? 500;
      final logoPath = _badges[_selectedBadgeIndex!];
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.createLeague(
        name: _nameController.text.trim(),
        logo: logoPath,
        leagueType: 'private',
        maxMembers: _numParticipants,
        budget: budget,
        startMatchday: _startMatchday,
        auctionType: _auctionRandom ? 'random' : 'classic',
      );
      if (mounted) context.go('/league/${league.id}');
    } catch (e) {
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
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
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FantastarInput(
                              controller: _nameController,
                              label: 'Nome della lega',
                              hint: 'Es. Lega degli amici',
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Scegli lo stemma',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _badgesLoading
                                ? const SizedBox(
                                    height: 240,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : _badgesError != null
                                    ? _BadgesErrorSection(
                                        message: _badgesError!,
                                        onRetry: _loadBadges,
                                      )
                                    : _BadgeSelector(
                                        badges: _badges,
                                        pageController: _badgePageController,
                                        currentPage: _currentBadgePage,
                                        onPageChanged: (index) =>
                                            setState(() => _currentBadgePage = index),
                                        selectedIndex: _selectedBadgeIndex,
                                        onSelect: (index) =>
                                            setState(() => _selectedBadgeIndex = index),
                                      ),
                            const SizedBox(height: 24),
                            Text(
                              'Numero partecipanti',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: CupertinoPicker(
                                scrollController: _participantsScrollController,
                                itemExtent: 40,
                                magnification: 1.2,
                                squeeze: 1.0,
                                useMagnifier: true,
                                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                                  background: _kSelectionCeleste.withOpacity(0.25),
                                ),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    _numParticipants = _participantOptions[index];
                                    if (_startMatchday > _maxStartMatchday) {
                                      _startMatchday = _currentMatchday.clamp(1, _maxStartMatchday);
                                      _startMatchdayScrollController.jumpToItem((_startMatchday - 1).clamp(0, _maxStartMatchday - 1));
                                    }
                                  });
                                },
                                children: _participantOptions.map((value) => Center(
                                  child: Text(
                                    '$value partecipanti',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Giornata di inizio',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startMatchday == _currentMatchday
                                  ? 'Il calendario partirà dalla giornata corrente ($_startMatchday) di Serie A'
                                  : 'Il calendario partirà dalla giornata $_startMatchday di Serie A ($_totalRounds giornate, fino alla ${_startMatchday + _totalRounds - 1}ª)',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF5C6B7A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.inputBorder),
                              ),
                              child: _isLoadingMatchday
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                                      ),
                                    )
                                  : CupertinoPicker(
                                      scrollController: _startMatchdayScrollController,
                                      itemExtent: 40,
                                      magnification: 1.2,
                                      squeeze: 1.0,
                                      useMagnifier: true,
                                      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                                        background: _kSelectionCeleste.withOpacity(0.25),
                                      ),
                                      onSelectedItemChanged: (index) {
                                        setState(() => _startMatchday = index + 1);
                                      },
                                      children: List.generate(_maxStartMatchday, (i) {
                                        final day = i + 1;
                                        final isCurrent = day == _currentMatchday;
                                        return Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Giornata $day',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  color: const Color(0xFF1A1A2E),
                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0D47A1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'attuale',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E8F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📅 Inizio: Giornata $_startMatchday di Serie A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '🏁 Fine: Giornata ${_startMatchday + _totalRounds - 1} di Serie A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '⚽ Totale: $_totalRounds giornate (${_totalRounds ~/ 2} andata + ${_totalRounds ~/ 2} ritorno)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FantastarInput(
                              controller: _budgetController,
                              label: 'Budget iniziale (crediti)',
                              hint: '500',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Obbligatorio';
                                final n = double.tryParse(v.trim());
                                if (n == null || n < 1) return 'Inserisci un numero valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Tipo asta',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _AuctionTypeToggle(
                              isRandom: _auctionRandom,
                              onChanged: (v) => setState(() => _auctionRandom = v),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            FantastarButton(
                              label: 'Crea Lega',
                              onPressed: _submit,
                              loading: _loading,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primaryDark, size: 24),
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
                      errorBuilder: (_, __, ___) => Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.emoji_events_outlined,
                            color: AppColors.textGrey, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Crea Lega',
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
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Messaggio errore stemmi + bottone Riprova.
class _BadgesErrorSection extends StatelessWidget {
  const _BadgesErrorSection({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Riprova'),
              style: TextButton.styleFrom(foregroundColor: _kSelectionCeleste),
            ),
          ],
        ),
      ),
    );
  }
}

/// PageView orizzontale: 6 stemmi per pagina (2 righe x 3 colonne), caricati da rete.
/// Numero pagine dinamico: (badges.length / 6).ceil()
class _BadgeSelector extends StatelessWidget {
  const _BadgeSelector({
    required this.badges,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> badges;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  static const int _badgesPerPage = 6;
  static const double _sectionHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    final totalPages = (badges.length / _badgesPerPage).ceil();
    if (totalPages == 0) {
      return const SizedBox(height: _sectionHeight);
    }

    return SizedBox(
      height: _sectionHeight,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: totalPages,
              onPageChanged: onPageChanged,
              itemBuilder: (context, pageIndex) {
                final start = pageIndex * _badgesPerPage;
                final end = math.min(start + _badgesPerPage, badges.length);
                final pageBadges = badges.sublist(start, end);

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: pageBadges.length,
                  itemBuilder: (context, index) {
                    final badgeIndex = start + index;
                    final isSelected = selectedIndex == badgeIndex;
                    final path = pageBadges[index];
                    final badgeUrl = path.startsWith('http')
                        ? path
                        : '$kBackendOrigin${path.startsWith('/') ? path : '/$path'}';
                    return GestureDetector(
                      onTap: () => onSelect(badgeIndex),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: _kSelectionCeleste, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _kSelectionCeleste.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network(
                                badgeUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.background3,
                                  child: const Icon(Icons.image_not_supported,
                                      color: AppColors.textGrey, size: 28),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: _kSelectionCeleste,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 10 : 8,
                height: currentPage == index ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentPage == index
                      ? _kSelectionCeleste
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionTypeToggle extends StatelessWidget {
  const _AuctionTypeToggle({
    required this.isRandom,
    required this.onChanged,
  });

  final bool isRandom;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Classica',
            selected: !isRandom,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleChip(
            label: 'Random',
            selected: isRandom,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.15)
          : AppColors.inputBorder.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';
import '../../widgets/fantastar_background.dart';

/// Colore selezione stemma/avatar: celeste (come Crea Lega).
const Color _kSelectionCeleste = Color(0xFF81D4FA);

class CreateTeamScreen extends StatefulWidget {
  final String leagueId;

  const CreateTeamScreen({super.key, required this.leagueId});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _nameController = TextEditingController();
  final _coachNameController = TextEditingController();
  final _badgePageController = PageController();
  final _avatarPageController = PageController();

  /// Lista stemmi: ogni elemento ha 'url' e 'name' (nome leggibile dal backend).
  List<Map<String, String>> _teamBadges = [];
  String? _selectedBadge;
  int _currentBadgePage = 0;

  /// Lista avatar: ogni elemento ha 'url' (e opzionale 'name').
  List<Map<String, String>> _coachAvatars = [];
  String? _selectedAvatar;
  int _currentAvatarPage = 0;
  bool _isLoadingAvatars = true;

  bool _isCreating = false;

  /// Nome auto-compilato dall'ultimo stemma selezionato (per non sovrascrivere nomi personalizzati).
  String _nameFromPreviousBadge = '';

  @override
  void initState() {
    super.initState();
    _fetchTeamBadges();
    _fetchCoachAvatars();
    final username = context.read<AuthProvider>().user?.username;
    if (username != null && username.isNotEmpty) {
      _coachNameController.text = username;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coachNameController.dispose();
    _badgePageController.dispose();
    _avatarPageController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamBadges() async {
    try {
      final response = await Dio().get('$kBackendOrigin/api/team-badges');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final list = data['badges'];
        if (list is List) {
          setState(() {
            _teamBadges = (list as List<dynamic>)
                .map((b) => {
                      'url': (b as Map)['url'] as String,
                      'name': (b as Map)['name'] as String,
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Errore caricamento stemmi: $e');
    }
  }

  Future<void> _fetchCoachAvatars() async {
    try {
      final response = await Dio().get('$kBackendOrigin/api/coach-avatars');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final list = data['avatars'];
        if (list is List) {
          setState(() {
            _coachAvatars = (list as List<dynamic>)
                .map((a) => {
                      'url': (a as Map)['url'] as String,
                      'name': (a as Map)['name'] as String? ?? '',
                    })
                .toList();
            _isLoadingAvatars = false;
          });
        } else {
          setState(() => _isLoadingAvatars = false);
        }
      } else {
        setState(() => _isLoadingAvatars = false);
      }
    } catch (e) {
      debugPrint('Errore caricamento avatar allenatori: $e');
      setState(() => _isLoadingAvatars = false);
    }
  }

  Future<void> _createTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un nome per la squadra'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedBadge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scegli uno stemma'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await context.read<TeamService>().createTeam(
            widget.leagueId,
            name,
            logoUrl: _selectedBadge,
            coachName: _coachNameController.text.trim().isEmpty
                ? null
                : _coachNameController.text.trim(),
            coachAvatarUrl: _selectedAvatar,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Squadra creata!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Crea Squadra',
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

                  // Sezione 1: Nome Squadra
                  const SizedBox(height: 8),
                  const Text(
                    'Nome Squadra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Inserisci il nome della tua squadra',
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF5C6B7A),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D47A1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Sezione 2: Stemma Squadra
                  const SizedBox(height: 24),
                  const Text(
                    'Stemma Squadra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scegli lo stemma della tua squadra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C6B7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                        SizedBox(
                          height: 260,
                          child: _teamBadges.isEmpty
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                )
                              : PageView.builder(
                                  controller: _badgePageController,
                                  onPageChanged: (page) =>
                                      setState(() => _currentBadgePage = page),
                                  itemCount: (_teamBadges.length / 6).ceil(),
                                  itemBuilder: (context, pageIndex) {
                                    final start = pageIndex * 6;
                                    final end = (start + 6)
                                        .clamp(0, _teamBadges.length);
                                    final pageBadges =
                                        _teamBadges.sublist(start, end);
                                    return GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: pageBadges.length,
                                      itemBuilder: (context, index) {
                                        final badge = pageBadges[index];
                                        final badgeUrl = badge['url']!;
                                        final isSelected =
                                            _selectedBadge == badgeUrl;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedBadge = badgeUrl;
                                              final nameFromBadge = badge['name']!;
                                              if (_nameController.text.isEmpty ||
                                                  _nameFromPreviousBadge == _nameController.text.trim()) {
                                                _nameController.text = nameFromBadge;
                                              }
                                              _nameFromPreviousBadge = nameFromBadge;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? _kSelectionCeleste
                                                      .withOpacity(0.3)
                                                  : const Color(0xFFE0E8F2),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isSelected
                                                    ? _kSelectionCeleste
                                                    : const Color(0xFFB0BEC5)
                                                        .withOpacity(0.5),
                                                width: isSelected ? 2.5 : 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              child: Image.network(
                                                '$kBackendOrigin$badgeUrl',
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.shield,
                                                  size: 30,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        if (_teamBadges.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              (_teamBadges.length / 6).ceil(),
                              (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentBadgePage == index
                                    ? const Color(0xFF0D47A1)
                                    : const Color(0xFFB0BEC5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sezione 3: Nome Allenatore
                  const SizedBox(height: 24),
                  const Text(
                    'Nome Allenatore',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Di default il tuo username',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C6B7A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _coachNameController,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nome del tuo allenatore',
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF5C6B7A),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D47A1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Sezione 4: Avatar Allenatore
                  const SizedBox(height: 24),
                  const Text(
                    'Avatar Allenatore',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scegli il tuo avatar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5C6B7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                    child: _isLoadingAvatars
                        ? const Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          )
                        : _coachAvatars.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.face,
                                      size: 40,
                                      color: const Color(0xFF5C6B7A)
                                          .withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Avatar in arrivo...',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Color(0xFF5C6B7A),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: 260,
                                    child: PageView.builder(
                                      controller: _avatarPageController,
                                      onPageChanged: (page) => setState(
                                          () => _currentAvatarPage = page),
                                      itemCount:
                                          (_coachAvatars.length / 6).ceil(),
                                      itemBuilder: (context, pageIndex) {
                                        final start = pageIndex * 6;
                                        final end = (start + 6)
                                            .clamp(0, _coachAvatars.length);
                                        final pageAvatars =
                                            _coachAvatars.sublist(start, end);
                                        return GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1,
                                          ),
                                          itemCount: pageAvatars.length,
                                          itemBuilder: (context, index) {
                                            final avatar = pageAvatars[index];
                                            final avatarUrl = avatar['url']!;
                                            final isSelected =
                                                _selectedAvatar == avatarUrl;
                                            return GestureDetector(
                                              onTap: () => setState(
                                                  () => _selectedAvatar =
                                                      avatarUrl),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? _kSelectionCeleste
                                                          .withOpacity(0.3)
                                                      : const Color(0xFFE0E8F2),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? _kSelectionCeleste
                                                        : const Color(0xFFB0BEC5)
                                                            .withOpacity(0.5),
                                                    width:
                                                        isSelected ? 2.5 : 1,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    child: Image.network(
                                                      '$kBackendOrigin$avatarUrl',
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              const Icon(
                                                        Icons.face,
                                                        size: 30,
                                                        color:
                                                            Color(0xFF0D47A1),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  if ((_coachAvatars.length / 6).ceil() > 1) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        (_coachAvatars.length / 6).ceil(),
                                        (index) => Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _currentAvatarPage == index
                                                ? const Color(0xFF0D47A1)
                                                : const Color(0xFFB0BEC5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                  ),

                  // Sezione 5: Bottone Crea Squadra
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createTeam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        disabledBackgroundColor: const Color(0xFF0D47A1)
                            .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Crea Squadra',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../models/fantasy_league.dart';
import '../../models/league_member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/league_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_utils.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/league_logo.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  FantasyLeagueModel? _league;
  List<LeagueMemberModel> _members = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.getLeague(widget.leagueId);
      final members = await leagueService.getLeagueMembers(widget.leagueId);
      if (mounted) {
        setState(() {
          _league = league;
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFriendlyErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _removeMember(LeagueMemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi membro'),
        content: Text(
          'Sei sicuro di voler rimuovere ${member.name} dalla lega? I suoi giocatori torneranno disponibili.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<LeagueService>().removeLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente rimosso')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockMember(LeagueMemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blocca membro'),
        content: const Text(
          'Bloccare questo utente? Non potrà più rientrare nella lega.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Blocca')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<LeagueService>().blockLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente bloccato')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockMember(LeagueMemberModel member) async {
    try {
      await context.read<LeagueService>().unblockLeagueMember(widget.leagueId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente sbloccato')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteLeague() async {
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final name = _league?.name ?? 'questa lega';
        return AlertDialog(
          title: const Text('Elimina lega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai per eliminare la lega $name.\n\nQuesta azione è IRREVERSIBILE.\nScrivi ELIMINA per confermare.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Scrivi ELIMINA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (confirmController.text.trim().toUpperCase() == 'ELIMINA') {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<LeagueService>().deleteLeague(widget.leagueId);
      if (mounted) {
        context.read<HomeProvider>().load();
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lega eliminata')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.6)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF5C6B7A),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF5C6B7A)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _league == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.background1,
          body: FantastarBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null && _league == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.background1,
          body: FantastarBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
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

    final league = _league!;
    final currentUserId = context.watch<AuthProvider>().user?.id?.toString();
    final isCurrentUserAdmin = league.isAdminFor(currentUserId);
    const int rosterMax = 25;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FantastarBackground(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),

                    // 2) CARD INFO LEGA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: LeagueLogo(logoKey: league.logo, size: 80),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            league.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A3D7A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.lock_outline,
                            'Tipo',
                            '${league.isPrivate ? "Privata" : "Pubblica"} (${league.isPrivate ? (league.maxMembers ?? league.maxTeams) : "∞"} max)',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.group,
                            'Membri',
                            '${league.teamCount ?? 0}/${league.isPrivate ? (league.maxMembers ?? league.maxTeams) : "∞"}',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.vpn_key, size: 18, color: AppColors.primary.withOpacity(0.6)),
                              const SizedBox(width: 10),
                              const Text(
                                'Codice invito',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF5C6B7A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E8F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      league.inviteCode ?? '-',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0A3D7A),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: league.inviteCode ?? ''));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Codice copiato!'),
                                            backgroundColor: Color(0xFF0D47A1),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.copy, size: 16, color: Color(0xFF0D47A1)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3) SEZIONE MEMBRI
                    const SizedBox(height: 24),
                    const Text(
                      'Membri',
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
                      padding: const EdgeInsets.all(4),
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
                        children: _members.map((member) {
                          final isAdmin = member.isAdmin;
                          final isMe = member.userId == currentUserId;
                          final canAct = isCurrentUserAdmin && !isAdmin && !isMe;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E8F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    member.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                    size: 24,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              member.name,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (member.isBlocked) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Bloccato',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                            ),
                                          ] else if (member.isKicked) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Rimosso',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                          ] else if (isAdmin) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Admin',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (!member.isBlocked && !member.isKicked) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${member.budget.toInt()} cr  |  ${member.rosterCount}/$rosterMax rosa',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: Color(0xFF5C6B7A),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (canAct && member.status == 'active')
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF5C6B7A)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'kick', child: Text('Rimuovi')),
                                      const PopupMenuItem(value: 'block', child: Text('Blocca')),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'kick') _removeMember(member);
                                      if (value == 'block') _blockMember(member);
                                    },
                                  ),
                                if (canAct && member.isBlocked)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, size: 20, color: Color(0xFF2E7D32)),
                                    onPressed: () => _unblockMember(member),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 4) SEZIONE IMPOSTAZIONI LEGA
                    const SizedBox(height: 24),
                    const Text(
                      'Impostazioni',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          _buildSettingsTile(Icons.edit, 'Modifica nome lega', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prossimamente'),
                                backgroundColor: Color(0xFF0D47A1),
                              ),
                            );
                          }),
                          Divider(height: 1, color: const Color(0xFFB0BEC5).withOpacity(0.3)),
                          _buildSettingsTile(Icons.image, 'Cambia stemma', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prossimamente'),
                                backgroundColor: Color(0xFF0D47A1),
                              ),
                            );
                          }),
                          Divider(height: 1, color: const Color(0xFFB0BEC5).withOpacity(0.3)),
                          _buildSettingsTile(Icons.lock, 'Visibilità lega', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prossimamente'),
                                backgroundColor: Color(0xFF0D47A1),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // 5) ZONA PERICOLOSA
                    const SizedBox(height: 24),
                    const Text(
                      'Zona pericolosa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A3D7A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _deleteLeague,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.delete_forever, size: 24, color: Colors.red.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Elimina lega',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Questa azione è irreversibile',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 20, color: Colors.red.shade400),
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
      ),
    );
  }

  /// Header identico alla pagina La mia Lega: back container + titolo centrato + bilanciamento
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A2E)),
            ),
          ),
          const Spacer(),
          const Text(
            'Gestisci Lega',
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
}

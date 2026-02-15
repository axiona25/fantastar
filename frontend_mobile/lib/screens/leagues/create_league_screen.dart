import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/league_service.dart';
import '../../utils/error_utils.dart';
import '../../widgets/league_logo.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedLogo = 'trophy';
  String _leagueType = 'private'; // 'public' | 'private'
  int _maxMembers = 8;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.createLeague(
        name: _nameController.text.trim(),
        logo: _selectedLogo,
        leagueType: _leagueType,
        maxMembers: _leagueType == 'private' ? _maxMembers : null,
        budget: 500,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Crea lega')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Scegli un logo per la lega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: leagueLogoKeys.map((key) {
                final selected = _selectedLogo == key;
                final color = leagueLogoColors[key] ?? Colors.amber;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLogo = key),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(leagueLogos[key]!, color: color, size: 28),
                        if (selected)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Icon(Icons.check_circle, color: color, size: 18),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome lega',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 24),
            Text('Tipo di lega', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Pubblica',
                    icon: Icons.public,
                    selected: _leagueType == 'public',
                    onTap: () => setState(() => _leagueType = 'public'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChip(
                    label: 'Privata',
                    icon: Icons.lock,
                    selected: _leagueType == 'private',
                    onTap: () => setState(() => _leagueType = 'private'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _leagueType == 'public'
                    ? 'Pubblica: mercato libero, giocatori condivisi, nessun limite partecipanti.'
                    : 'Privata: asta tra amici, giocatori esclusivi, max partecipanti.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (_leagueType == 'private') ...[
              const SizedBox(height: 24),
              Text('Numero partecipanti: $_maxMembers', style: theme.textTheme.titleSmall),
              Slider(
                value: _maxMembers.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                label: '$_maxMembers',
                onChanged: (v) => setState(() => _maxMembers = v.round()),
              ),
              Text(
                'L\'asta partirà quando tutti saranno entrati.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Tutti possono unirsi e comprare dal mercato.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
            const SizedBox(height: 8),
            Text('Budget: 500 cr per tutti', style: theme.textTheme.bodyMedium),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crea lega'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/league_service.dart';
import '../../utils/error_utils.dart';

class JoinLeagueScreen extends StatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _error = 'Il codice deve essere di 8 caratteri');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leagueService = context.read<LeagueService>();
      final league = await leagueService.lookupByInviteCode(code);
      await leagueService.joinLeague(league.id, code);
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
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Unisciti a lega')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Codice invito (8 caratteri)',
              border: OutlineInputBorder(),
              hintText: 'XXXXXXXX',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Unisciti'),
          ),
        ],
      ),
    );
  }
}

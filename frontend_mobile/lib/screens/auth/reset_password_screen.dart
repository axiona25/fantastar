import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/error_utils.dart';

/// Imposta nuova password con reset_token (passato da forgot-password flow).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  final String? resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  String? get _token => widget.resetToken;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Link non valido. Riprova il recupero password.');
      return;
    }
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 6) {
      setState(() => _error = 'La password deve avere almeno 6 caratteri');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Le password non coincidono');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.authService.resetPassword(token, password);
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _token!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recupero password')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Link non valido. Torna al login e ripeti il recupero password.'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nuova password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Conferma password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salva password'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Torna al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

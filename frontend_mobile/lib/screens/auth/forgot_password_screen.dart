import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/error_utils.dart';

/// Recupero password: email -> backend restituisce phone -> Firebase Phone Auth SMS -> verify-phone-reset -> reset-password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _phone; // numero da backend (per invio SMS Firebase)
  String? _verificationId;
  bool _loading = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _smsCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestPhoneAndSendSms() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Inserisci l\'email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final out = await auth.authService.forgotPassword(email);
      final phone = out['phone'] as String?;
      if (phone == null || phone.isEmpty) {
        setState(() {
          _error = 'Nessun numero associato a questa email. Contatta l\'assistenza.';
          _loading = false;
        });
        return;
      }
      setState(() { _phone = phone; _loading = false; });
      await _firebaseVerifyPhone(phone);
    } catch (e) {
      setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _firebaseVerifyPhone(String phone) async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await userCred.user?.getIdToken();
          if (idToken != null && mounted) await _verifyPhoneReset(idToken);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() {
            _error = e.message != null && e.message!.isNotEmpty ? e.message! : 'Verifica fallita. Riprova.';
            _loading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _loading = false;
              _resendSeconds = 60;
            });
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds <= 0) {
          t.cancel();
          return;
        }
        _resendSeconds--;
      });
    });
  }

  Future<void> _submitSmsCode() async {
    final code = _smsCodeController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      setState(() => _error = 'Inserisci il codice ricevuto via SMS');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCred.user?.getIdToken();
      if (idToken != null && mounted) await _verifyPhoneReset(idToken);
      else if (mounted) setState(() { _error = 'Impossibile ottenere il token'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _verifyPhoneReset(String idToken) async {
    try {
      final auth = context.read<AuthProvider>();
      final resetToken = await auth.authService.verifyPhoneReset(idToken);
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/reset-password', extra: resetToken);
    } catch (e) {
      if (mounted) setState(() {
        _error = userFriendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = _phone != null;
    final hasVerificationId = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Recupero password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (!hasPhone) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _loading ? null : _requestPhoneAndSendSms,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Invia codice SMS'),
                ),
              ] else ...[
                Text(
                  'Codice inviato a ${_phone!.length > 4 ? '***${_phone!.substring(_phone!.length - 4)}' : _phone}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (hasVerificationId) ...[
                  TextField(
                    controller: _smsCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Codice SMS',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submitSmsCode,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verifica e continua'),
                  ),
                  if (_resendSeconds > 0) ...[
                    const SizedBox(height: 8),
                    Text('Reinvia codice tra $_resendSeconds s', style: Theme.of(context).textTheme.bodySmall),
                  ] else if (_phone != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => _firebaseVerifyPhone(_phone!),
                      child: const Text('Reinvia codice'),
                    ),
                  ],
                ] else if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Torna al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fantastar_background.dart';
import '../../widgets/fantastar_button.dart';
import '../../widgets/fantastar_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (email.isEmpty || username.isEmpty || password.isEmpty) return;
    if (!_acceptTerms) return;
    if (password != confirm) return;
    final ok = await context.read<AuthProvider>().register(email, username, password);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      body: FantastarBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 24),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logo centrato come login
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 168,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        height: 168,
                        width: 168,
                        child: Center(
                          child: Text(
                            'F',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Crea un account',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card form
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FantastarInput(
                          label: 'Nome utente',
                          controller: _usernameController,
                          hint: 'Il tuo username',
                          prefixIcon: const Icon(Icons.person_outline),
                          autocorrect: false,
                          compact: true,
                        ),
                        const SizedBox(height: 12),
                        FantastarInput(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'esempio@email.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          compact: true,
                        ),
                        const SizedBox(height: 12),
                        FantastarInput(
                          label: 'Password',
                          controller: _passwordController,
                          hint: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          obscureText: true,
                          compact: true,
                        ),
                        const SizedBox(height: 12),
                        FantastarInput(
                          label: 'Conferma Password',
                          controller: _confirmPasswordController,
                          hint: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          obscureText: true,
                          compact: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptTerms,
                                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                activeColor: AppColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                child: const Text(
                                  'Accetto Termini & Privacy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FantastarButton(
                          label: 'Crea Account',
                          loading: auth.loading,
                          onPressed: _acceptTerms ? _submit : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Hai già un account? ', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'Accedi',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

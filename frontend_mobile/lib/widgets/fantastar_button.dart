import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Bottone principale Fantastar: gradiente blu navy, bordi arrotondati 30, testo bianco bold.
/// Opzionale [accentColor] per bottone accent (es. magenta "Crea Lega").
class FantastarButton extends StatelessWidget {
  const FantastarButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.isExpanded = true,
    this.accentColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isExpanded;
  /// Se impostato, usa questo colore solido invece del gradiente blu (es. magenta).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );

    final color = accentColor ?? AppColors.primary;
    return Container(
      width: isExpanded ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: accentColor == null
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF0D47A1), // navy
                  Color(0xFF1565C0), // blu
                ],
              )
            : null,
        color: accentColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

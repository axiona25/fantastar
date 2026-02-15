import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottone social login: sfondo bianco, bordo grigio, icona + testo (Apple o Google).
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  /// Se true, altezza ~48px.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        side: const BorderSide(color: AppColors.inputBorder),
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
        minimumSize: compact ? const Size.fromHeight(48) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: compact ? 15 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(width: 24, height: 24, child: icon),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

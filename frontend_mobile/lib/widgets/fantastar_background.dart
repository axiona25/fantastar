import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sfondo riutilizzabile per le schermate auth: gradiente grigio-blu (palette fantacalcio).
class FantastarBackground extends StatelessWidget {
  const FantastarBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background1,
            AppColors.background4,
            AppColors.background2,
            AppColors.background3,
            AppColors.background4,
          ],
          stops: [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Effetto luce/glow (cerchi delicati ma più visibili sullo sfondo)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.2 - 80,
            top: MediaQuery.of(context).size.height * 0.15 - 80,
            child: _GlowCircle(
              radius: 120,
              color: Colors.white.withOpacity(0.28),
            ),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.15 - 60,
            bottom: MediaQuery.of(context).size.height * 0.2 - 60,
            child: _GlowCircle(
              radius: 100,
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5 - 60,
            top: MediaQuery.of(context).size.height * 0.4 - 60,
            child: _GlowCircle(
              radius: 80,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.radius,
    required this.color,
  });

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

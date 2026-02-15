import 'package:flutter/material.dart';

/// Placeholder per articoli senza immagine: gradient scuro + brand FANTASTAR + icona ⚽.
class NewsPlaceholderImage extends StatelessWidget {
  const NewsPlaceholderImage({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, size: 48, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            Text(
              'FANTASTAR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

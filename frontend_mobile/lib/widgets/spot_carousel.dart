import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carosello spot pubblicitari: immagini da assets (poi da API static/media/spot/).
/// Cambio ogni 20 secondi con transizione fade (diversa dallo slide orizzontale delle news).
class SpotCarousel extends StatefulWidget {
  const SpotCarousel({super.key});

  @override
  State<SpotCarousel> createState() => _SpotCarouselState();
}

class _SpotCarouselState extends State<SpotCarousel> {
  int _currentPage = 0;
  Timer? _timer;
  bool _hasError = false;

  static const List<String> _spotImages = [
    'assets/images/spot/spot1.png',
    'assets/images/spot/spot2.png',
    'assets/images/spot/spot3.png',
    'assets/images/spot/spot4.png',
  ];

  static const double _height = 260;
  static const Color _dotActive = Color(0xFFE91E63); // magenta

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNext());
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      setState(() {
        _currentPage = (_currentPage + 1) % _spotImages.length;
      });
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: ClipRRect(
                key: ValueKey<int>(_currentPage),
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _spotImages[_currentPage],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: _height,
                  errorBuilder: (_, __, ___) {
                    if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _hasError = true);
                    });
                    return Container(
                      color: AppColors.background3,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: AppColors.textGrey, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _spotImages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentPage
                          ? _dotActive
                          : AppColors.textGrey.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

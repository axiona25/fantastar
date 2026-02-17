import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/fantastar_background.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'home/placeholder_tab.dart';

/// Shell con bottom navigation a 5 tab e sfondo Fantastar.
/// Usa IndexedStack per tenere lo stato delle tab.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FantastarBackground(child: SizedBox.expand()),
          navigationShell,
        ],
      ),
      bottomNavigationBar: FantastarBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i),
      ),
    ),
    );
  }
}

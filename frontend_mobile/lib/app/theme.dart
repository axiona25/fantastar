import 'package:flutter/material.dart';

/// Tema placeholder: Material default. Il design verrà applicato in un secondo momento.
ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );

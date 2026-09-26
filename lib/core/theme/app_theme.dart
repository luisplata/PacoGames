import 'package:flutter/material.dart';

/// Base Material 3 theme for the app.
///
/// Tipografía: `Montserrat` global (fuente vendored M1, D7). Los títulos de
/// páginas de juego usan `Grobold` explícitamente en cada página (feature
/// local, reversible en M4).
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.indigo,
  fontFamily: 'Montserrat',
);
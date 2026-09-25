import 'package:flutter/material.dart';

/// Base Material 3 theme for the app.
///
/// Kept minimal on purpose: game features will add their own
/// theming requirements later, so the seed color is the only
/// visual decision made today.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.indigo,
);
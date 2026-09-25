import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder message shown on the home screen.
///
/// This is the minimal Riverpod wiring (provider → widget) that
/// proves the state container and DI path work end to end.
final homeMessageProvider = Provider<String>((ref) => 'PacoGame');
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(homeMessageProvider);

    return Scaffold(
      body: Center(
        child: Text(message, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
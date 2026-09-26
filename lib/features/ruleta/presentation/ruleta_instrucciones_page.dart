import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instrucciones de la Ruleta (RU9): fondo wallpaper, logo, 3 bullets
/// exactos del proposal (copy rioplatense, D1) + [Jugar] → /ruleta/juego.
class RuletaInstruccionesPage extends StatelessWidget {
  const RuletaInstruccionesPage({super.key});

  static const _bullets = [
    'Tocá [Girar] y esperá la animación: la ruleta elige por vos',
    'Leé el resultado en grande: no se repiten las últimas 5 finales',
    'Si sale «volvé a girar»: turno salvado, pasás el turno y gira el siguiente',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/wallpaper_1.jpg', fit: BoxFit.cover),
          ColoredBox(color: Colors.black.withValues(alpha: .35)),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(
                    color: Colors.white,
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_paco.png',
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ruleta',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontFamily: 'Grobold',
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 24),
                        for (final bullet in _bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      bullet,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Qué necesitás: nada, solo el teléfono',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.push('/ruleta/juego'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Jugar', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
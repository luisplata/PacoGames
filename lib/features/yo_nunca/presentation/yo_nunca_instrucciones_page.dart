import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instrucciones de Yo Nunca (YN7): fondo wallpaper, logo, 3 bullets
/// exactos del proposal (copy rioplatense, D1) + [Jugar] → /yo-nunca/juego.
class YoNuncaInstruccionesPage extends StatelessWidget {
  const YoNuncaInstruccionesPage({super.key});

  static const _bullets = [
    'Elegí el género: barajamos las cartas y no se repiten hasta agotar el mazo',
    'Pasá el teléfono y leé la frase en voz alta',
    'Si la hiciste, ¡traguito! Si no, pasá el teléfono',
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
                          'Yo nunca',
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
                          onPressed: () => context.push('/yo-nunca/juego'),
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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instrucciones de Pictionary (P8): fondo wallpaper, logo, 3 bullets
/// exactos del proposal (copy rioplatense, D1) + "Qué necesitás: un papel
/// y algo para dibujar" + [Jugar] → /pictionary/juego.
class PictionaryInstruccionesPage extends StatelessWidget {
  const PictionaryInstruccionesPage({super.key});

  static const _bullets = [
    'Pasá el teléfono: el dibujante elige una de 3 palabras en secreto',
    'Dibujá en un papel mientras corre el timer de 60 segundos',
    'Si adivinan: ¡punto para el equipo! Si no, el turno pasa sin sumar',
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
                          'Pictionary',
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
                          'Qué necesitás: un papel y algo para dibujar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.push('/pictionary/juego'),
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
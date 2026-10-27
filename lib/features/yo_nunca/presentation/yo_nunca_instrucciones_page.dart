import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../application/carta_yo_nunca.dart';
import '../application/yo_nunca_providers.dart';

/// Instrucciones de Yo Nunca (YN7): fondo wallpaper, logo, 3 bullets exactos
/// del proposal (copy rioplatense, D1) + bloque de Nivel (default Normal) +
/// [Jugar] → /yo-nunca/juego conservando el nivel elegido.
class YoNuncaInstruccionesPage extends ConsumerWidget {
  const YoNuncaInstruccionesPage({super.key});

  static const _bullets = [
    'Elegí el nivel: barajamos las cartas y no se repiten hasta agotar el mazo',
    'Pasá el teléfono y leé la frase en voz alta',
    'Si la hiciste, ¡traguito! Si no, pasá el teléfono',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Estos dos watches son los que mantienen vivo el nivel autoDispose
    // mientras la página está montada: sobrevive reglas → juego (YN3).
    final elegido = ref.watch(yoNuncaNivelProvider);
    final ajustes = ref.watch(ajustesProvider);
    // D8/A3: `true` = modo sin alcohol; fallback = default sobrio.
    final modoAlcohol =
        ajustes.value?.modoSinAlcohol ?? Ajustes.defaults.modoSinAlcohol;
    final efectivo = nivelEfectivo(elegido: elegido, modoAlcohol: modoAlcohol);

    final nota = modoAlcohol
        ? 'Modo sin alcohol activo: Picante no está disponible. '
            'Desactivalo en Ajustes.'
        : efectivo == NivelYoNunca.picante
            ? 'Picante suma las cartas picantes a las normales.'
            : 'Normal usa solo las cartas normales.';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/wallpaper_1.webp', fit: BoxFit.cover),
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
                          'assets/images/logo_paco.webp',
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
                        _bloqueNivel(
                          ref,
                          efectivo: efectivo,
                          modoAlcohol: modoAlcohol,
                          nota: nota,
                        ),
                        const SizedBox(height: 16),
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

  /// Bloque C4 + segmentos C5 + nota C6/C7/C8 (diseño §7).
  Widget _bloqueNivel(
    WidgetRef ref, {
    required NivelYoNunca efectivo,
    required bool modoAlcohol,
    required String nota,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nivel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Grobold',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<NivelYoNunca>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              foregroundColor: Colors.white,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            segments: [
              ButtonSegment(
                value: NivelYoNunca.normal,
                label: const Text('Normal', key: Key('nivel_normal')),
              ),
              ButtonSegment(
                value: NivelYoNunca.picante,
                // Picante no es seleccionable en modo sin alcohol (YN7).
                enabled: !modoAlcohol,
                label: const Text('Picante', key: Key('nivel_picante')),
              ),
            ],
            selected: {efectivo},
            onSelectionChanged: (seleccion) {
              final nuevo = seleccion.single;
              // Defensa extra al `enabled: false` (doble gate).
              if (nuevo == NivelYoNunca.picante && modoAlcohol) return;
              ref.read(yoNuncaNivelProvider.notifier).state = nuevo;
            },
          ),
          const SizedBox(height: 12),
          Text(
            nota,
            key: const Key('nota_nivel'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

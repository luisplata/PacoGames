import 'package:flutter/material.dart';

/// Banner genérico del modo sin alcohol (YN5-b, D8 — promovido a core en M2).
///
/// GENÉRICO a propósito: el contenido de las cartas nunca se reescribe.
/// [texto] permite a cada juego su propio literal; el default preserva el
/// texto EXACTO de M1 (los tests de yo_nunca no cambian).
class AvisoModoSinAlcohol extends StatelessWidget {
  const AvisoModoSinAlcohol({super.key, this.texto = textoPorDefecto});

  /// Literal M1 exacto: los tragos se leen como prendas.
  static const textoPorDefecto = 'Modo sin alcohol: los tragos se leen como prendas';

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_drinks_outlined, size: 18, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
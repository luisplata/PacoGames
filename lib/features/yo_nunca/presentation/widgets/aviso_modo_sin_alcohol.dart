import 'package:flutter/material.dart';

/// Banner genérico del modo sin alcohol (YN5-b, D8).
///
/// Feature-local en M1; promover a core/widgets en M2 si otro juego lo usa.
/// Es GENÉRICO a propósito: el contenido de las cartas nunca se reescribe.
class AvisoModoSinAlcohol extends StatelessWidget {
  const AvisoModoSinAlcohol({super.key});

  static const texto = 'Modo sin alcohol: los tragos se leen como prendas';

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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_drinks_outlined, size: 18, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
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
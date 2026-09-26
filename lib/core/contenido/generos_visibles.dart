import 'entidades.dart';

/// Géneros visibles según el modo sin alcohol (YN2, RU6 — promovido a core
/// en M2 para que yo_nunca y ruleta lo compartan).
///
/// Filtra SOLO el género cuyo nombre (case-insensitive) es `'picante'`
/// cuando [modoAlcohol] es `true`. Nunca reordena ni reescribe contenido.
List<Genero> generosVisibles(List<Genero> generos, {required bool modoAlcohol}) {
  if (!modoAlcohol) return generos;
  return generos.where((g) => g.nombre.toLowerCase() != 'picante').toList();
}
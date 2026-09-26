import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ajustes.dart';
import 'ajustes_repository.dart';

final ajustesRepositoryProvider = Provider<AjustesRepository>(
  (ref) => AjustesRepository(),
);

final ajustesProvider = AsyncNotifierProvider<AjustesNotifier, Ajustes>(
  AjustesNotifier.new,
);

class AjustesNotifier extends AsyncNotifier<Ajustes> {
  @override
  Future<Ajustes> build() {
    return ref.read(ajustesRepositoryProvider).cargarAjustes();
  }

  Future<void> _actualizar(Ajustes nuevo) async {
    state = AsyncData(nuevo);
    await ref.read(ajustesRepositoryProvider).guardarAjustes(nuevo);
  }

  Future<void> cambiarSonido(bool valor) =>
      _actualizar((state.value ?? Ajustes.defaults).copyWith(sonido: valor));

  Future<void> cambiarVibracion(bool valor) =>
      _actualizar((state.value ?? Ajustes.defaults).copyWith(vibracion: valor));

  Future<void> cambiarModoAlcohol(bool valor) =>
      _actualizar((state.value ?? Ajustes.defaults).copyWith(modoAlcohol: valor));

  Future<void> marcarSplashVisto() =>
      _actualizar((state.value ?? Ajustes.defaults).copyWith(splashVisto: true));
}
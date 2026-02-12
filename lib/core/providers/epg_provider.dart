import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/xtream_models.dart';
import '../services/epg_service.dart';

/// Provider del servicio EPG (singleton)
final epgServiceProvider = Provider<EPGService>((ref) {
  return EPGService();
});

/// StateNotifier para gestionar el estado de carga del EPG
class EpgLoadingNotifier extends StateNotifier<bool> {
  EpgLoadingNotifier() : super(false);
  
  void setLoading(bool loading) {
    state = loading;
  }
}

final epgLoadingProvider = StateNotifierProvider<EpgLoadingNotifier, bool>((ref) {
  return EpgLoadingNotifier();
});

/// Family Provider para obtener el programa actual de un canal específico
/// Uso: ref.watch(epgProvider(channelId))
/// NOTA: Este provider ahora refresca cada 60 segundos para actualizar programas
final epgProvider = StreamProvider.family<EPGProgram?, String>((ref, channelId) async* {
  final epgService = ref.watch(epgServiceProvider);
  
  // Emitir inmediatamente el programa actual si existe
  final currentProgram = epgService.getCurrentProgram(channelId);
  yield currentProgram;
  
  // Actualizar cada 60 segundos
  await for (var _ in Stream.periodic(const Duration(seconds: 60))) {
    final program = epgService.getCurrentProgram(channelId);
    yield program;
  }
});

/// Provider para inicializar el EPG con credenciales Xtream
final initializeEPGProvider = FutureProvider.family<void, EpgInitParams>((ref, params) async {
  final epgService = ref.watch(epgServiceProvider);
  final loadingNotifier = ref.read(epgLoadingProvider.notifier);
  
  loadingNotifier.setLoading(true);
  
  try {
    if (params.isXtream) {
      // Cargar EPG desde Xtream Codes API
      await epgService.fetchXtreamEPG(
        params.serverUrl!,
        params.username!,
        params.password!,
        params.streamId!,
      );
    } else if (params.xmltvUrl != null) {
      // Cargar EPG desde XMLTV URL
      await epgService.fetchXMLTVEPG(params.xmltvUrl!);
    }
  } finally {
    loadingNotifier.setLoading(false);
  }
});

/// Parámetros para inicializar el EPG
class EpgInitParams {
  final bool isXtream;
  final String? serverUrl;
  final String? username;
  final String? password;
  final int? streamId;
  final String? xmltvUrl;

  EpgInitParams({
    this.isXtream = true,
    this.serverUrl,
    this.username,
    this.password,
    this.streamId,
    this.xmltvUrl,
  });

  /// Constructor para Xtream Codes
  factory EpgInitParams.xtream({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
  }) {
    return EpgInitParams(
      isXtream: true,
      serverUrl: serverUrl,
      username: username,
      password: password,
      streamId: streamId,
    );
  }

  /// Constructor para XMLTV
  factory EpgInitParams.xmltv({
    required String xmltvUrl,
  }) {
    return EpgInitParams(
      isXtream: false,
      xmltvUrl: xmltvUrl,
    );
  }
}

/// Provider de estado para gestionar la carga masiva de EPG
/// Útil para mostrar un indicador de progreso
final epgLoadingStateProvider = StateProvider<bool>((ref) => false);

/// Provider para obtener el siguiente programa de un canal
final nextProgramProvider = Provider.family<EPGProgram?, String>((ref, channelId) {
  final epgService = ref.watch(epgServiceProvider);
  return epgService.getNextProgram(channelId);
});

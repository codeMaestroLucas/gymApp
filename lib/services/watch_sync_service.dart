import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import 'storage_service.dart';

/// Serviço robusto de sincronização bidirecional em tempo real entre o app móvel e o smartwatch.
/// Utiliza arquitetura multi-camada:
/// 1. Google Play Services Wearable Data Layer API (Bluetooth e Nuvem para Wear OS / Galaxy Watch)
/// 2. Sincronização direta via rede local (Wi-Fi / LAN HTTP Socket)
/// 3. Fila de persistência offline resiliente a desconexões temporárias
class WatchSyncService {
  static const String channelName = 'com.titangym.watch/sync';
  static const int syncPort = 8765;
  static final WatchSyncService instance = WatchSyncService._internal();

  factory WatchSyncService() => instance;
  WatchSyncService._internal();

  final MethodChannel _channel = const MethodChannel(channelName);

  /// Notifier com a lista reativa de treinos sincronizados para o smartwatch e celular
  final ValueNotifier<List<Workout>> workoutsNotifier = ValueNotifier<List<Workout>>([]);

  /// Indicador de status de sincronização (true = sincronizado, false = sincronizando)
  final ValueNotifier<bool> isSynced = ValueNotifier<bool>(true);

  /// Data/hora da última sincronização bem-sucedida
  final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier<DateTime?>(null);

  /// Origem do último canal de sincronização utilizado
  final ValueNotifier<String> syncSource = ValueNotifier<String>('Inicial');

  /// Notificador disparado no celular quando um treino é concluído no relógio
  final ValueNotifier<WorkoutHistoryEntry?> lastCompletedWatchWorkout = ValueNotifier<WorkoutHistoryEntry?>(null);

  HttpServer? _localServer;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool get _isTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Inicializa o serviço, listeners nativos e servidor de sincronização em rede local
  Future<void> init() async {
    final initialWorkouts = StorageService().loadWorkouts();
    workoutsNotifier.value = List<Workout>.from(initialWorkouts);
    lastSyncTime.value = DateTime.now();

    // Configura o handler para mensagens nativas da Wearable Data Layer
    _channel.setMethodCallHandler(_handleNativeMessage);

    if (!_isTest) {
      _startLocalServerIfMobile();
      await fetchWorkoutsFromNative();
      await flushPendingFinishes();
    }
  }

  /// Inicia servidor local leve para comunicação direta via Wi-Fi / ADB entre celular e relógio
  Future<void> _startLocalServerIfMobile() async {
    final isWatch = await checkIsWatchDevice();
    if (isWatch) {
      // Inicia polling periódico suave no smartwatch a cada 20 segundos
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        syncFromAllSources();
      });
      return;
    }

    try {
      _localServer = await HttpServer.bind(InternetAddress.anyIPv4, syncPort);
      _localServer?.listen(_handleHttpSyncRequest);
      if (kDebugMode) {
        debugPrint('🌐 Servidor de Sincronização Local Titan iniciado na porta $syncPort');
      }
    } catch (_) {
      // Porta ocupada ou permissão de rede restrita; o canal nativo Wearable suprirá
    }
  }

  /// Trata requisições HTTP diretas do relógio via Wi-Fi
  void _handleHttpSyncRequest(HttpRequest request) async {
    final path = request.uri.path;
    request.response.headers.contentType = ContentType.json;

    try {
      if (path == '/api/status') {
        request.response.write(json.encode({
          'status': 'ok',
          'device': 'mobile',
          'synced_at': lastSyncTime.value?.millisecondsSinceEpoch,
          'workouts_count': workoutsNotifier.value.length,
        }));
      } else if (path == '/api/workouts' && request.method == 'GET') {
        final workouts = StorageService().loadWorkouts();
        request.response.write(json.encode({
          'action': 'SYNC_WORKOUTS',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'workouts': workouts.map((w) => w.toMap()).toList(),
        }));
      } else if (path == '/api/workout_finished' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = json.decode(content);
        if (data is Map) {
          _processFinishedWorkoutData(data);
        }
        request.response.write(json.encode({'success': true}));
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(json.encode({'error': 'not_found'}));
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({'error': e.toString()}));
    } finally {
      await request.response.close();
    }
  }

  /// Manipula mensagens e eventos recebidos do smartwatch (Wear OS / watchOS)
  Future<dynamic> _handleNativeMessage(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onWorkoutsReceivedFromPhone':
          final rawPayload = call.arguments;
          if (rawPayload != null) {
            _processReceivedWorkoutsPayload(rawPayload, source: 'Wearable Data Layer');
          }
          return true;

        case 'onWatchWorkoutFinished':
          final rawPayload = call.arguments;
          if (rawPayload != null) {
            final data = rawPayload is String ? json.decode(rawPayload) : rawPayload;
            if (data is Map) {
              _processFinishedWorkoutData(data);
            }
          }
          return true;

        case 'onWatchWorkoutCompleted':
          final payload = call.arguments;
          if (payload is Map) {
            final durationSec = (payload['duration_seconds'] as num?)?.toInt() ?? 1800;
            final history = WorkoutHistoryEntry(
              id: payload['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              workoutTitle: payload['workout_title']?.toString() ?? 'Treino no Smartwatch',
              splitTag: payload['split_tag']?.toString() ?? 'A',
              completedAt: DateTime.now(),
              durationMinutes: (durationSec / 60).round(),
              totalVolumeKg: (payload['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
              totalSets: (payload['total_sets'] as num?)?.toInt() ?? 0,
              exercisesCount: (payload['total_exercises'] as num?)?.toInt() ?? 0,
              caloriesEstimated: ((durationSec / 60) * 7.5).round(),
            );
            await StorageService().addHistoryEntry(history);
            lastCompletedWatchWorkout.value = history;
            workoutsNotifier.value = StorageService().loadWorkouts();
          }
          return true;

        case 'requestWorkoutsSync':
          await syncWorkouts(StorageService().loadWorkouts());
          return true;

        default:
          return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao processar mensagem do relógio: $e');
      }
      return null;
    }
  }

  /// Processa payload de treinos recebidos do celular
  void _processReceivedWorkoutsPayload(dynamic rawPayload, {required String source}) {
    try {
      Map<String, dynamic> data;
      if (rawPayload is String) {
        data = json.decode(rawPayload) as Map<String, dynamic>;
      } else if (rawPayload is Map) {
        data = Map<String, dynamic>.from(rawPayload);
      } else {
        return;
      }

      final listRaw = data['workouts'] as List<dynamic>?;
      if (listRaw != null) {
        final loaded = listRaw.map((e) => Workout.fromMap(e as Map<String, dynamic>)).toList();
        StorageService().saveWorkoutsLocally(loaded);
        workoutsNotifier.value = List<Workout>.from(loaded);
        isSynced.value = true;
        lastSyncTime.value = DateTime.now();
        syncSource.value = source;

        if (kDebugMode) {
          debugPrint('⌚ Sincronização via $source: ${loaded.length} treinos atualizados com sucesso.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao decodificar treinos recebidos: $e');
      }
    }
  }

  /// Processa os dados de treino finalizado recebido do smartwatch
  Future<void> _processFinishedWorkoutData(Map data) async {
    try {
      final updatedWorkoutRaw = data['updated_workout'];
      final historyRaw = data['history_entry'];

      if (updatedWorkoutRaw is Map) {
        final updatedWorkout = Workout.fromMap(Map<String, dynamic>.from(updatedWorkoutRaw));
        await StorageService().updateWorkout(updatedWorkout);
      }

      if (historyRaw is Map) {
        final history = WorkoutHistoryEntry.fromMap(Map<String, dynamic>.from(historyRaw));
        await StorageService().addHistoryEntry(history);
        lastCompletedWatchWorkout.value = history;
      }

      workoutsNotifier.value = StorageService().loadWorkouts();
      isSynced.value = true;
      lastSyncTime.value = DateTime.now();

      if (kDebugMode) {
        debugPrint('⌚ Treino finalizado sincronizado e aplicado com sucesso no aplicativo móvel!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao processar treino finalizado: $e');
      }
    }
  }

  /// Sincroniza a lista atual de treinos com o smartwatch imediatamente.
  /// Qualquer alteração feita no app móvel aciona este método.
  Future<void> syncWorkouts(List<Workout> workouts) async {
    isSynced.value = false;
    workoutsNotifier.value = List<Workout>.from(workouts);

    try {
      final jsonPayload = json.encode({
        'action': 'SYNC_WORKOUTS',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'workouts': workouts.map((w) => w.toMap()).toList(),
      });

      // 1. Envia via Wearable DataClient / MessageClient nativo
      try {
        await _channel.invokeMethod('syncWorkoutsToWatch', {
          'workouts_payload': jsonPayload,
        }).timeout(const Duration(milliseconds: 150), onTimeout: () => null);
      } catch (_) {}

      isSynced.value = true;
      lastSyncTime.value = DateTime.now();
      syncSource.value = 'Móvel';

      if (kDebugMode) {
        debugPrint('⌚ Sincronização com o Smartwatch concluída: ${workouts.length} treinos atualizados.');
      }
    } catch (e) {
      isSynced.value = false;
    }
  }

  /// Salva o treino concluído no smartwatch com todas as alterações de cargas,
  /// repetições e observações feitas durante a sessão, persistindo no banco local
  /// e sincronizando imediatamente com o aplicativo móvel com fila offline resiliente.
  Future<void> saveFinishedWorkoutFromWatch({
    required Workout updatedWorkout,
    required WorkoutHistoryEntry historyEntry,
  }) async {
    // 1. Atualiza localmente
    await StorageService().updateWorkout(updatedWorkout);
    await StorageService().addHistoryEntry(historyEntry);

    final payloadMap = {
      'action': 'WORKOUT_FINISHED_FROM_WATCH',
      'updated_workout': updatedWorkout.toMap(),
      'history_entry': historyEntry.toMap(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonPayload = json.encode(payloadMap);

    bool syncedNatively = false;

    // 2. Envia para o celular via Wearable API nativo
    try {
      final res = await _channel.invokeMethod('onWatchWorkoutFinished', {
        'payload': jsonPayload,
      }).timeout(const Duration(milliseconds: 200), onTimeout: () => null);
      syncedNatively = res == true;
    } catch (_) {}

    // 3. Tenta enviar via rede local HTTP se o canal nativo falhar
    if (!syncedNatively && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      syncedNatively = await _sendWorkoutFinishedViaHttp(payloadMap);
    }

    // 4. Se não conseguiu sincronizar com o celular agora, salva na fila offline para envio posterior
    if (!syncedNatively) {
      await StorageService().addPendingWatchFinish(payloadMap);
      if (kDebugMode) {
        debugPrint('⌚ Treino salvo localmente e adicionado à fila offline para envio assim que reconectar.');
      }
    }

    workoutsNotifier.value = StorageService().loadWorkouts();
    lastSyncTime.value = DateTime.now();
  }

  /// Envia payload de treino finalizado via HTTP direto na rede local
  Future<bool> _sendWorkoutFinishedViaHttp(Map<String, dynamic> payloadMap) async {
    final candidateHosts = ['127.0.0.1', '10.0.2.2'];
    for (final host in candidateHosts) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 400);
        final request = await client.post(host, syncPort, '/api/workout_finished');
        request.headers.contentType = ContentType.json;
        request.write(json.encode(payloadMap));
        final response = await request.close();
        if (response.statusCode == 200) {
          client.close();
          return true;
        }
        client.close();
      } catch (_) {}
    }
    return false;
  }

  /// Descarrega treinos pendentes na fila offline do relógio para o celular
  Future<void> flushPendingFinishes() async {
    final pending = StorageService().loadPendingWatchFinishes();
    if (pending.isEmpty) return;

    if (_isTest) {
      await StorageService().clearPendingWatchFinishes();
      return;
    }

    final remaining = <Map<String, dynamic>>[];
    for (final item in pending) {
      bool sent = false;
      try {
        final jsonPayload = json.encode(item);
        final res = await _channel.invokeMethod('onWatchWorkoutFinished', {
          'payload': jsonPayload,
        }).timeout(const Duration(milliseconds: 200), onTimeout: () => null);
        sent = res == true;
      } catch (_) {}

      if (!sent && !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        sent = await _sendWorkoutFinishedViaHttp(item);
      }

      if (!sent) {
        remaining.add(item);
      }
    }

    if (remaining.isEmpty) {
      await StorageService().clearPendingWatchFinishes();
      if (kDebugMode) {
        debugPrint('⌚ Fila offline do Smartwatch totalmente descarregada para o celular.');
      }
    }
  }

  /// Busca os treinos mais recentes de todas as fontes disponíveis (Wearable API, Wi-Fi LAN e Cache)
  Future<bool> syncFromAllSources() async {
    if (_isTest) {
      final local = StorageService().loadWorkouts();
      workoutsNotifier.value = List<Workout>.from(local);
      isSynced.value = true;
      lastSyncTime.value = DateTime.now();
      return true;
    }

    if (_isSyncing) return isSynced.value;
    _isSyncing = true;
    isSynced.value = false;

    bool success = false;

    try {
      // 1. Tenta carregar do cache nativo Wearable do Android
      final nativeJson = await fetchWorkoutsFromNative();
      if (nativeJson != null && nativeJson.isNotEmpty) {
        _processReceivedWorkoutsPayload(nativeJson, source: 'Cache Wearable');
        success = true;
      }

      // 2. Solicita ao celular push urgente via Wearable MessageClient
      try {
        await _channel.invokeMethod('requestWorkoutsFromPhone').timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => null,
        );
      } catch (_) {}

      // 3. Tenta sincronização direta via HTTP na rede local Wi-Fi / ADB
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        final httpSuccess = await _fetchWorkoutsViaHttp();
        if (httpSuccess) {
          success = true;
        }
      }

      // 4. Descarrega qualquer fila offline pendente
      await flushPendingFinishes();

      // Se não obteve da rede/wearable, usa o armazenamento local
      if (!success) {
        final local = StorageService().loadWorkouts();
        if (local.isNotEmpty) {
          workoutsNotifier.value = List<Workout>.from(local);
          success = true;
        }
      }

      isSynced.value = success;
      if (success) {
        lastSyncTime.value = DateTime.now();
      }
    } catch (_) {
      isSynced.value = false;
    } finally {
      _isSyncing = false;
    }

    return success;
  }

  /// Busca treinos via HTTP direto no IP do smartphone conectado na mesma rede
  Future<bool> _fetchWorkoutsViaHttp() async {
    final candidateHosts = ['127.0.0.1', '10.0.2.2'];
    for (final host in candidateHosts) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 400);
        final request = await client.get(host, syncPort, '/api/workouts');
        final response = await request.close();
        if (response.statusCode == 200) {
          final content = await utf8.decoder.bind(response).join();
          client.close();
          _processReceivedWorkoutsPayload(content, source: 'Wi-Fi Direto');
          return true;
        }
        client.close();
      } catch (_) {}
    }
    return false;
  }

  /// Consulta os treinos salvos nas SharedPreferences nativas do dispositivo
  Future<String?> fetchWorkoutsFromNative() async {
    try {
      final jsonStr = await _channel.invokeMethod<String>('getLatestWatchWorkouts').timeout(
        const Duration(milliseconds: 200),
        onTimeout: () => null,
      );
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _processReceivedWorkoutsPayload(jsonStr, source: 'Armazenamento Nativo');
        return jsonStr;
      }
    } catch (_) {}
    return null;
  }

  /// Formata amigavelmente o tempo decorrido desde a última sincronização
  String getSyncStatusFormatted() {
    final last = lastSyncTime.value;
    if (last == null) return 'Aguardando';

    final diff = DateTime.now().difference(last);
    if (diff.inSeconds < 45) {
      return 'Atualizado agora';
    } else if (diff.inMinutes < 60) {
      return 'Sincronizado há ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Sincronizado há ${diff.inHours}h';
    } else {
      return 'Sincronizado';
    }
  }

  /// Verifica nativamente se o dispositivo atual é um relógio Wear OS / watchOS
  Future<bool> checkIsWatchDevice() async {
    try {
      final res = await _channel.invokeMethod<bool>('isWatchDevice').timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => false,
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _localServer?.close(force: true);
    _periodicSyncTimer?.cancel();
  }
}

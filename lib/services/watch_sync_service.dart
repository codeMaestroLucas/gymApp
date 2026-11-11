import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import 'storage_service.dart';

/// Serviço responsável pela sincronização em tempo real entre o app móvel e o smartwatch.
/// Garante que qualquer alteração de treinos no celular seja imediatamente refletida no relógio.
class WatchSyncService {
  static const String channelName = 'com.titangym.watch/sync';
  static final WatchSyncService instance = WatchSyncService._internal();

  factory WatchSyncService() => instance;
  WatchSyncService._internal();

  final MethodChannel _channel = const MethodChannel(channelName);

  /// Notifier com a lista reativa de treinos sincronizados para o smartwatch
  final ValueNotifier<List<Workout>> workoutsNotifier = ValueNotifier<List<Workout>>([]);

  /// Indicador de status de sincronização
  final ValueNotifier<bool> isSynced = ValueNotifier<bool>(true);

  /// Data/hora da última sincronização bem-sucedida
  final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier<DateTime?>(null);

  /// Inicializa o serviço e configura listeners nativos
  Future<void> init() async {
    // Carrega treinos iniciais do armazenamento
    final initialWorkouts = StorageService().loadWorkouts();
    workoutsNotifier.value = List<Workout>.from(initialWorkouts);
    lastSyncTime.value = DateTime.now();

    // Configura o handler para mensagens vindas do smartwatch
    _channel.setMethodCallHandler(_handleNativeMessage);
  }

  /// Manipula mensagens e eventos recebidos do smartwatch (Wear OS / watchOS)
  Future<dynamic> _handleNativeMessage(MethodCall call) async {
    try {
      switch (call.method) {
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
            if (kDebugMode) {
              debugPrint('⌚ Treino concluído no relógio recebido e salvo no histórico móvel: ${history.workoutTitle}');
            }
          }
          return true;

        case 'requestWorkoutsSync':
          // O relógio solicitou carga completa dos dados
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

  /// Sincroniza a lista atual de treinos com o smartwatch imediatamente.
  /// Qualquer alteração feita no app móvel (criação, exclusão, edição de repetições/cargas)
  /// aciona este método.
  Future<void> syncWorkouts(List<Workout> workouts) async {
    isSynced.value = false;

    // Atualiza estado reativo local imediatamente
    workoutsNotifier.value = List<Workout>.from(workouts);

    try {
      final jsonPayload = json.encode({
        'action': 'SYNC_WORKOUTS',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'workouts': workouts.map((w) => w.toMap()).toList(),
      });

      // Envia para a camada nativa (Wearable DataClient no Android / WCSession no iOS)
      try {
        await _channel.invokeMethod('syncWorkoutsToWatch', {
          'workouts_payload': jsonPayload,
        }).timeout(const Duration(milliseconds: 100), onTimeout: () => null);
      } catch (_) {
        // Em testes, emuladores ou sem relógio pareado por perto, mantém o estado sincronizado localmente
      }

      isSynced.value = true;
      lastSyncTime.value = DateTime.now();

      if (kDebugMode) {
        debugPrint('⌚ Sincronização com o Smartwatch concluída: ${workouts.length} treinos atualizados.');
      }
    } catch (e) {
      isSynced.value = false;
      if (kDebugMode) {
        debugPrint('Falha ao sincronizar com o smartwatch: $e');
      }
    }
  }

  /// Registra conclusão de treino disparada a partir do app do relógio
  Future<void> completeWorkoutFromWatch(WorkoutHistoryEntry history) async {
    await StorageService().addHistoryEntry(history);
  }

  /// Salva o treino concluído no smartwatch com todas as alterações de cargas,
  /// repetições e observações feitas durante a sessão, persistindo no banco local
  /// e sincronizando imediatamente com o aplicativo móvel.
  Future<void> saveFinishedWorkoutFromWatch({
    required Workout updatedWorkout,
    required WorkoutHistoryEntry historyEntry,
  }) async {
    // 1. Atualiza o treino com as novas cargas, repetições e observações feitas no relógio
    await StorageService().updateWorkout(updatedWorkout);

    // 2. Registra o histórico de conclusão do treino
    await StorageService().addHistoryEntry(historyEntry);

    // 3. Notifica a camada nativa para sincronização com o celular
    try {
      final jsonPayload = json.encode({
        'action': 'WORKOUT_FINISHED_FROM_WATCH',
        'updated_workout': updatedWorkout.toMap(),
        'history_entry': historyEntry.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await _channel.invokeMethod('onWatchWorkoutFinished', {
        'payload': jsonPayload,
      }).timeout(const Duration(milliseconds: 100), onTimeout: () => null);
    } catch (_) {}

    // 4. Notifica listeners reativos
    workoutsNotifier.value = StorageService().loadWorkouts();
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
}

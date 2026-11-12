import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/main.dart';
import 'package:gym_app/models/user_profile.dart';
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/models/workout_history.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/services/ai_workout_service.dart';
import 'package:gym_app/services/exercise_image_service.dart';
import 'package:gym_app/services/storage_service.dart';
import 'package:gym_app/services/watch_sync_service.dart';
import 'package:gym_app/widgets/custom_bottom_nav.dart';
import 'package:gym_app/widgets/workout_card.dart';
import 'package:gym_app/watch/watch_companion_screen.dart';
import 'package:gym_app/watch/screens/watch_home_screen.dart';
import 'package:gym_app/watch/screens/watch_active_workout_screen.dart';
import 'package:gym_app/screens/workout_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App initializes successfully and renders without overflow on 344px width',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(344, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();
    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Evolução'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    expect(find.byType(DumbbellNavIcon), findsOneWidget);
    expect(find.byType(EvolutionNavIcon), findsOneWidget);
    expect(find.byType(ProfileNavIcon), findsOneWidget);
    expect(find.byType(Dismissible), findsWidgets);

    await tester.tap(find.text('Evolução'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Evolução & Performance'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Índice de Massa Corporal'), findsOneWidget);
  });

  testWidgets('SM L310 Galaxy Watch (480x480) automatically launches WatchHomeScreen without extra tabs',
      (WidgetTester tester) async {
    // Simula a tela de 480x480 com densidade 2.5 (192x192 dp lógicos) do Samsung Galaxy Watch 7 / SM L310
    tester.view.physicalSize = const Size(480, 480);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();

    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Deve abrir APENAS a tela de início do Smartwatch com os treinos gerados
    expect(find.byType(WatchHomeScreen), findsOneWidget);
    expect(find.text('SEUS TREINOS'), findsOneWidget);
    // NÃO deve conter as 3 abas de celular (Início, Histórico/Evolução, Perfil)
    expect(find.byType(CustomBottomNav), findsNothing);
  });

  testWidgets('WorkoutCard renders without overflow on narrow width 155.7 dp',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(155.7, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final workout = StorageService().loadWorkouts().first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 155.7,
            child: WorkoutCard(
              workout: workout,
              onTap: () {},
              onStart: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('TREINO'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
  });

  testWidgets('WatchActiveWorkoutScreen allows modifying weight, reps and saving workout to mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();

    final originalWorkout = StorageService().loadWorkouts().first.clone();
    final firstEx = originalWorkout.exercises.first;
    final initialWeight = firstEx.weightKg;

    await tester.pumpWidget(
      MaterialApp(
        home: WatchActiveWorkoutScreen(
          workout: originalWorkout,
          isCircular: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verifica ausência de S1/S2/S3 (apenas repetições e botão Concluir Exercício)
    expect(find.text('S1'), findsNothing);
    expect(find.text('S2'), findsNothing);
    expect(find.text('CONCLUIR EXERCÍCIO'), findsOneWidget);

    // 1. Modifica o peso clicando no botão '+' (+2.5 kg)
    final addIcon = find.byIcon(Icons.add_rounded).first;
    await tester.tap(addIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final expectedWeight = (initialWeight + 2.5).toStringAsFixed(initialWeight % 1 == 0 ? 1 : 0);
    expect(find.textContaining(expectedWeight), findsWidgets);

    // 2. Modifica a observação (diálogo compacto sem chips de sugestão)
    await tester.tap(find.textContaining('Obs:'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('OBSERVAÇÃO'), findsOneWidget);

    // Digita observação no campo e salva
    await tester.enterText(find.byType(TextField), 'Foco total na carga');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Foco total'), findsOneWidget);

    // 3. Finaliza a sessão e acessa tela de Salvar Treino
    await tester.tap(find.text('Fim'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TREINO FINALIZADO!'), findsOneWidget);
    expect(find.text('SALVAR TREINO'), findsOneWidget);

    // 4. Clica em 'SALVAR TREINO'
    await tester.tap(find.text('SALVAR TREINO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 5. Verifica se o treino foi atualizado no StorageService e refletido no app
    final savedWorkouts = StorageService().loadWorkouts();
    final updatedW = savedWorkouts.firstWhere((w) => w.id == originalWorkout.id);
    expect(updatedW.exercises.first.weightKg, equals(initialWeight + 2.5));
    expect(updatedW.exercises.first.observations, contains('Foco total'));

    // Verifica se a sessão foi registrada no histórico
    final history = StorageService().loadHistory();
    expect(history.any((h) => h.workoutTitle == originalWorkout.title), isTrue);
  });

  test('AiWorkoutService enforces max 3 reps, 6-8 exercises, and prioritizes images', () async {
    final profile = UserProfile.defaultProfile();
    final workouts = await AiWorkoutService.generateWorkouts(
      prompt: 'Treino de força pesada com alta variedade de exercícios',
      daysAvailable: 3,
      durationMinutes: 60,
      profile: profile,
      maxReps: 3,
      exerciseVariety: 7,
    );

    expect(workouts.length, equals(3));
    for (final workout in workouts) {
      expect(workout.exercises.length, inInclusiveRange(6, 8));
      for (final ex in workout.exercises) {
        expect(ex.reps, lessThanOrEqualTo(3));
        expect(ex.reps, greaterThanOrEqualTo(1));
        expect(ex.weightKg, greaterThan(0));
        expect(ex.imageUrl, isNotNull);
        expect(ex.imageUrl, startsWith('source/exercices/images/'));
      }
    }
  });

  test('ExerciseImageService resolves images and videos from source/exercices', () {
    final benchImg = ExerciseImageService.getImageForExercise(
      exerciseName: 'Supino Reto com Barra',
      primaryMuscleGroup: 'chest',
      diagramType: 'bench_press',
    );
    expect(benchImg, equals('source/exercices/images/chest/Bench Press.png'));

    final benchVid = ExerciseImageService.getVideoForExercise(
      exerciseName: 'Supino Reto com Barra',
      primaryMuscleGroup: 'chest',
      diagramType: 'bench_press',
    );
    expect(benchVid, equals('source/exercices/videos/chest/Bench Press.mp4'));

    final squatImg = ExerciseImageService.getImageForExercise(
      exerciseName: 'Agachamento Livre',
      primaryMuscleGroup: 'quadriceps',
      diagramType: 'squat',
    );
    expect(squatImg, equals('source/exercices/images/chest/Full Squat.png'));

    final squatVid = ExerciseImageService.getVideoForExercise(
      exerciseName: 'Agachamento Livre',
      primaryMuscleGroup: 'quadriceps',
      diagramType: 'squat',
    );
    expect(squatVid, equals('source/exercices/videos/quadriceps/Full Squat.mp4'));

    final deadliftImg = ExerciseImageService.getImageForExercise(
      exerciseName: 'Levantamento Terra',
      primaryMuscleGroup: 'back',
      diagramType: 'deadlift',
    );
    expect(deadliftImg, equals('source/exercices/images/back/Barbell Deadlift front view.png'));

    final deadliftVid = ExerciseImageService.getVideoForExercise(
      exerciseName: 'Levantamento Terra',
      primaryMuscleGroup: 'back',
      diagramType: 'deadlift',
    );
    expect(deadliftVid, equals('source/exercices/videos/hips/Barbell Deadlift.mp4'));
  });

  test('WatchSyncService updates reactively when workouts are modified in StorageService', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();

    final testWorkout = Workout(
      id: 'watch_test_1',
      title: 'Treino Teste Smartwatch',
      splitTag: 'Z',
      targetMusclesSummary: 'Peito e Braços',
      durationMinutes: 45,
      daysOfWeek: ['Segunda'],
      exercises: [
        Exercise(
          id: 'ex_watch_1',
          name: 'Supino Reto',
          targetMuscles: ['Peitoral'],
          primaryMuscleGroup: 'chest',
          weightKg: 90.0,
          reps: 3,
          sets: 3,
          restSeconds: 90,
          diagramType: 'bench_press',
          observations: 'Manter escápulas aduzidas',
        ),
      ],
    );

    await StorageService().saveWorkouts([testWorkout]);

    expect(WatchSyncService.instance.workoutsNotifier.value.length, equals(1));
    expect(WatchSyncService.instance.workoutsNotifier.value.first.id, equals('watch_test_1'));
    expect(WatchSyncService.instance.workoutsNotifier.value.first.exercises.first.reps, equals(3));
  });

  test('WatchSyncService handles incoming Wearable Data Layer messages and offline queue', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();

    final service = WatchSyncService.instance;
    await service.syncWorkouts([
      Workout(
        id: 'phone_synced_w1',
        title: 'Treino Sincronizado Wear OS',
        splitTag: 'B',
        targetMusclesSummary: 'Costas e Bíceps',
        durationMinutes: 50,
        daysOfWeek: ['Terça'],
        exercises: [
          Exercise(
            id: 'ex_synced_1',
            name: 'Puxada Alta',
            targetMuscles: ['Dorsal'],
            primaryMuscleGroup: 'back',
            weightKg: 75.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            diagramType: 'lat_pulldown',
          ),
        ],
      ),
    ]);

    expect(service.workoutsNotifier.value.length, equals(1));
    expect(service.workoutsNotifier.value.first.title, equals('Treino Sincronizado Wear OS'));

    // 2. Testa persistência de fila offline
    await StorageService().clearPendingWatchFinishes();
    final pendingItem = {
      'action': 'WORKOUT_FINISHED_FROM_WATCH',
      'updated_workout': service.workoutsNotifier.value.first.toMap(),
      'history_entry': WorkoutHistoryEntry(
        id: 'offline_h1',
        workoutTitle: 'Treino Sincronizado Wear OS',
        splitTag: 'B',
        completedAt: DateTime.now(),
        durationMinutes: 40,
        totalVolumeKg: 1200.0,
        totalSets: 3,
        exercisesCount: 1,
      ).toMap(),
    };

    await StorageService().addPendingWatchFinish(pendingItem);
    expect(StorageService().loadPendingWatchFinishes().length, equals(1));

    await service.flushPendingFinishes();
    expect(StorageService().loadPendingWatchFinishes().length, equals(0));
  });

  testWidgets('WatchHomeScreen and WatchCompanionScreen render without overflow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await WatchSyncService.instance.init();

    tester.view.physicalSize = const Size(390, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: WatchHomeScreen(isCircular: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SEUS TREINOS'), findsOneWidget);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(
      const MaterialApp(
        home: WatchCompanionScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Port Smartwatch (Wearable)'), findsOneWidget);
    expect(find.text('Sincronização Ativa em Tempo Real'), findsOneWidget);
  });

  testWidgets('WatchActiveWorkoutScreen carousel navigation and list view toggle',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final multiExWorkout = Workout(
      id: 'multi_test_1',
      title: 'Treino A',
      splitTag: 'A',
      targetMusclesSummary: 'Peito e Tríceps',
      durationMinutes: 45,
      daysOfWeek: ['Segunda'],
      exercises: [
        Exercise(
          id: 'ex_1',
          name: 'Supino Reto com Barra',
          targetMuscles: ['Peitoral'],
          primaryMuscleGroup: 'chest',
          weightKg: 80.0,
          reps: 3,
          sets: 3,
          restSeconds: 30,
          diagramType: 'bench_press',
        ),
        Exercise(
          id: 'ex_2',
          name: 'Crucifixo Inclinado',
          targetMuscles: ['Peitoral Superior'],
          primaryMuscleGroup: 'chest',
          weightKg: 24.0,
          reps: 3,
          sets: 3,
          restSeconds: 30,
          diagramType: 'dumbbell_flyes',
        ),
        Exercise(
          id: 'ex_3',
          name: 'Tríceps Corda',
          targetMuscles: ['Tríceps'],
          primaryMuscleGroup: 'arms',
          weightKg: 35.0,
          reps: 3,
          sets: 3,
          restSeconds: 30,
          diagramType: 'triceps_rope',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WatchActiveWorkoutScreen(
          workout: multiExWorkout,
          isCircular: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verifica exibição do primeiro exercício no card e indicador EX 1/3
    expect(find.text('EX 1/3'), findsOneWidget);
    expect(find.text('Supino Reto com Barra'), findsOneWidget);

    // 1. Abre a visão geral em lista clicando no botão de lista no topo
    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('EXERCÍCIOS'), findsOneWidget);
    expect(find.text('Tríceps Corda'), findsOneWidget);

    // 2. Clica no 3º exercício para pular diretamente para ele no carrossel
    await tester.tap(find.text('Tríceps Corda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('EX 3/3'), findsOneWidget);
    expect(find.text('Tríceps Corda'), findsOneWidget);

    // 3. Conclui o 3º exercício
    await tester.tap(find.text('CONCLUIR EXERCÍCIO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Deve entrar na tela de descanso circular com botão pular descanso
    expect(find.text('PULAR'), findsOneWidget);
    await tester.tap(find.text('PULAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Deve avançar automaticamente para o próximo exercício pendente (ex_1)
    expect(find.text('EX 1/3'), findsOneWidget);
  });

  testWidgets('Tapping on exercise image in WorkoutDetailScreen opens ExerciseDetailModal with video and details',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testExercise = Exercise(
      id: 'ex_detail_1',
      name: 'Supino Reto com Barra',
      targetMuscles: ['Peitoral Maior', 'Tríceps'],
      primaryMuscleGroup: 'chest',
      weightKg: 95.0,
      reps: 3,
      sets: 3,
      restSeconds: 120,
      diagramType: 'bench_press',
      imageUrl: 'source/exercices/images/chest/Bench Press.png',
      videoUrl: 'source/exercices/videos/chest/Bench Press.mp4',
      observations: 'Manter escápulas aduzidas',
    );

    final testWorkout = Workout(
      id: 'w_detail_test',
      title: 'Treino Teste Detalhe',
      splitTag: 'A',
      targetMusclesSummary: 'Peito e Braços',
      durationMinutes: 45,
      daysOfWeek: ['Segunda'],
      exercises: [testExercise],
    );

    Exercise? updatedExerciseResult;

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailScreen(
          workout: testWorkout,
          onWorkoutUpdated: (updatedW) {
            updatedExerciseResult = updatedW.exercises.first;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verifica ausência de labels removidas na lista (VÍDEO DE EXECUÇÃO, Vetor, Músculos, DIAGRAMA OFICIAL)
    expect(find.text('VÍDEO DE EXECUÇÃO'), findsNothing);
    expect(find.text('Vetor'), findsNothing);
    expect(find.text('DIAGRAMA OFICIAL'), findsNothing);
    expect(find.text('Supino Reto com Barra'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // 2. Clica na imagem do exercício específico para abrir o modal de detalhes
    final imageWidget = find.byType(Image).first;
    await tester.tap(imageWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Verifica que abas e botões desnecessários foram removidos (Vídeo da Execução, Foto Anatômica, Testar cronometro)
    expect(find.text('Vídeo da Execução'), findsNothing);
    expect(find.text('Foto Anatômica'), findsNothing);
    expect(find.textContaining('Testar Cronômetro'), findsNothing);
    expect(find.textContaining('Vídeo de execução não disponível'), findsNothing);
    expect(find.text('MÚSCULOS ALVO'), findsOneWidget);
    expect(find.text('OBSERVAÇÕES E NOTAS TÉCNICAS'), findsOneWidget);
    expect(find.textContaining('Manter escápulas aduzidas'), findsWidgets);

    // 4. Edita o exercício diretamente pelo modal detalhado e permite reps > 3
    final editButton = find.byTooltip('Editar exercício');
    await tester.tap(editButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Editar Supino Reto com Barra'), findsOneWidget);
    // Verifica que o campo de repetições inicia exatamente com o valor do exercício (3)
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));

    // Altera repetições para 8 reps (anteriormente era clamped a 3)
    await tester.enterText(textFields.at(1), '8');
    await tester.pump();

    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica que o modal e a tela pai receberam 8 reps sem ser travado em 3
    expect(find.text('8 reps'), findsWidgets);
    expect(updatedExerciseResult?.reps, equals(8));
  });
}

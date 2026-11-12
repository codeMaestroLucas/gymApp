import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/workout.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'screens/evolution_screen.dart';
import 'screens/profile_screen.dart';
import 'services/storage_service.dart';
import 'services/watch_sync_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_bottom_nav.dart';
import 'watch/screens/watch_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storage = StorageService();
  await storage.init();

  final watchSync = WatchSyncService();
  await watchSync.init();

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titan Gym AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AdaptiveRoot(),
    );
  }
}

/// Ponto de entrada adaptativo que identifica automaticamente se o dispositivo
/// é um Smartwatch (Wear OS / watchOS) ou um Smartphone tradicional.
class AdaptiveRoot extends StatefulWidget {
  const AdaptiveRoot({super.key});

  @override
  State<AdaptiveRoot> createState() => _AdaptiveRootState();
}

class _AdaptiveRootState extends State<AdaptiveRoot> {
  bool? _isNativeWatch;

  @override
  void initState() {
    super.initState();
    _checkNativeDevice();
  }

  Future<void> _checkNativeDevice() async {
    final isNative = await WatchSyncService.instance.checkIsWatchDevice();
    if (mounted && isNative) {
      setState(() {
        _isNativeWatch = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;

    // Detecta se está executando em um Smartwatch (Wear OS / watchOS)
    // 1. Checagem nativa de hardware do relógio (PackageManager.FEATURE_WATCH)
    // 2. Dimensões lógicas compactas (< 320dp de menor lado ou < 480dp de maior lado)
    final bool isWatch = (_isNativeWatch == true) ||
        (size.shortestSide < 320) ||
        (size.longestSide < 480);

    if (isWatch) {
      // No smartwatch, carrega APENAS a tela de início com os treinos já criados,
      // sem abas inferiores, sem histórico e sem perfil.
      return const WatchHomeScreen(isCircular: true);
    }

    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // 0: Início, 1: Evolução, 2: Perfil
  late UserProfile _userProfile;
  late List<Workout> _workouts;

  @override
  void initState() {
    super.initState();
    _userProfile = StorageService().loadProfile();
    _workouts = StorageService().loadWorkouts();
    WatchSyncService.instance.workoutsNotifier.addListener(_onWatchWorkoutsSync);
    WatchSyncService.instance.lastCompletedWatchWorkout.addListener(_onWatchWorkoutCompletedAlert);
  }

  @override
  void dispose() {
    WatchSyncService.instance.workoutsNotifier.removeListener(_onWatchWorkoutsSync);
    WatchSyncService.instance.lastCompletedWatchWorkout.removeListener(_onWatchWorkoutCompletedAlert);
    super.dispose();
  }

  void _onWatchWorkoutCompletedAlert() {
    final entry = WatchSyncService.instance.lastCompletedWatchWorkout.value;
    if (entry != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.watch_rounded, color: AppColors.primaryOrange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '⌚ Treino "${entry.workoutTitle}" finalizado no relógio e sincronizado!',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onWatchWorkoutsSync() {
    if (mounted) {
      setState(() {
        _workouts = List<Workout>.from(WatchSyncService.instance.workoutsNotifier.value);
      });
    }
  }

  void _onWorkoutsCreated(List<Workout> newWorkouts) {
    setState(() {
      _workouts = newWorkouts;
    });
    StorageService().saveWorkouts(_workouts);
  }

  void _onWorkoutUpdated(Workout updated) {
    setState(() {
      final index = _workouts.indexWhere((w) => w.id == updated.id);
      if (index != -1) {
        _workouts[index] = updated;
      }
    });
    StorageService().saveWorkouts(_workouts);
  }

  void _onWorkoutDeleted(String id) {
    setState(() {
      _workouts.removeWhere((w) => w.id == id);
    });
    StorageService().saveWorkouts(_workouts);
  }

  void _onProfileUpdated(UserProfile updated) {
    setState(() {
      _userProfile = updated;
    });
    StorageService().saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Telas mantidas com IndexedStack para preservar estado de scroll
          IndexedStack(
            index: _currentIndex,
            children: [
              // Aba 0: Início (Dumbbell)
              HomeScreen(
                workouts: _workouts,
                userProfile: _userProfile,
                onWorkoutsCreated: _onWorkoutsCreated,
                onWorkoutUpdated: _onWorkoutUpdated,
                onWorkoutDeleted: _onWorkoutDeleted,
              ),

              // Aba 1: Evolução (Gráfico)
              EvolutionScreen(
                userProfile: _userProfile,
                onProfileUpdated: _onProfileUpdated,
              ),

              // Aba 2: Perfil (Pessoa)
              ProfileScreen(
                userProfile: _userProfile,
                onProfileUpdated: _onProfileUpdated,
              ),
            ],
          ),

          // Menu Inferior Flutuante exatamente igual à imagem enviada
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onIndexChanged: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

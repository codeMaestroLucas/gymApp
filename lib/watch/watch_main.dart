import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/watch_sync_service.dart';
import 'watch_app.dart';

/// Ponto de entrada nativo standalone para Smartwatch Wear OS
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final watchSync = WatchSyncService();
  await watchSync.init();

  runApp(const WatchApp(isCircular: true));
}

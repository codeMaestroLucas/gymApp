package com.example.gym_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WATCH_CHANNEL = "com.titangym.watch/sync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWorkoutsToWatch" -> {
                    val payload = call.argument<String>("workouts_payload")
                    val prefs = getSharedPreferences("watch_sync_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putString("latest_workouts_json", payload)
                        .putLong("synced_at", System.currentTimeMillis())
                        .apply()
                    result.success(true)
                }
                "getLatestWatchWorkouts" -> {
                    val prefs = getSharedPreferences("watch_sync_prefs", MODE_PRIVATE)
                    val json = prefs.getString("latest_workouts_json", null)
                    result.success(json)
                }
                "isWatchDevice" -> {
                    val isWatch = packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_WATCH)
                    result.success(isWatch)
                }
                "onWatchWorkoutFinished" -> {
                    val payload = call.argument<String>("payload")
                    val prefs = getSharedPreferences("watch_sync_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putString("last_finished_workout", payload)
                        .putLong("finished_at", System.currentTimeMillis())
                        .apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

package com.example.gym_app

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Serviço de segundo plano do Google Play Services Wearable Data Layer.
 * Permite receber eventos de sincronização mesmo com o app em segundo plano
 * ou tela apagada no smartwatch (Wear OS / Galaxy Watch) ou celular.
 */
class WatchDataLayerListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "WatchDataLayerService"
        const val PREFS_NAME = "watch_sync_prefs"
        const val KEY_LATEST_WORKOUTS = "latest_workouts_json"
        const val KEY_SYNCED_AT = "synced_at"
        const val KEY_LAST_FINISHED = "last_finished_workout"
        const val KEY_FINISHED_AT = "finished_at"
        const val PATH_WORKOUTS = "/workouts"
        const val PATH_WORKOUT_FINISHED = "/workout_finished"
        const val PATH_REQUEST_SYNC = "/request_sync"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED) {
                val uri = event.dataItem.uri
                val path = uri.path ?: continue

                if (path.startsWith(PATH_WORKOUTS)) {
                    try {
                        val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                        val workoutsJson = dataMap.getString("workouts_payload")
                        if (!workoutsJson.isNullOrEmpty()) {
                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit()
                                .putString(KEY_LATEST_WORKOUTS, workoutsJson)
                                .putLong(KEY_SYNCED_AT, System.currentTimeMillis())
                                .apply()

                            Log.d(TAG, "⌚ Treinos sincronizados via Wearable Data Layer recebidos no service")

                            MainActivity.notifyFlutterWorkoutsReceived(workoutsJson)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Erro ao processar DataItem /workouts: ${e.message}")
                    }
                }
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        val payload = String(messageEvent.data, Charsets.UTF_8)

        when {
            path.startsWith(PATH_WORKOUT_FINISHED) -> {
                try {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString(KEY_LAST_FINISHED, payload)
                        .putLong(KEY_FINISHED_AT, System.currentTimeMillis())
                        .apply()

                    Log.d(TAG, "⌚ Treino finalizado no relógio recebido via MessageClient")
                    MainActivity.notifyFlutterWorkoutFinished(payload)
                } catch (e: Exception) {
                    Log.e(TAG, "Erro ao processar mensagem /workout_finished: ${e.message}")
                }
            }
            path.startsWith(PATH_REQUEST_SYNC) -> {
                Log.d(TAG, "⌚ Solicitação de sincronização recebida do relógio")
                MainActivity.notifyFlutterRequestSync()
            }
        }
    }
}

package com.example.gym_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity : FlutterActivity(), DataClient.OnDataChangedListener, MessageClient.OnMessageReceivedListener {

    companion object {
        private const val TAG = "TitanMainActivity"
        private const val WATCH_CHANNEL = "com.titangym.watch/sync"
        private const val PREFS_NAME = "watch_sync_prefs"
        private const val KEY_LATEST_WORKOUTS = "latest_workouts_json"
        private const val KEY_SYNCED_AT = "synced_at"
        private const val KEY_LAST_FINISHED = "last_finished_workout"
        private const val KEY_FINISHED_AT = "finished_at"

        const val PATH_WORKOUTS = "/workouts"
        const val PATH_WORKOUT_FINISHED = "/workout_finished"
        const val PATH_REQUEST_SYNC = "/request_sync"

        private var activeChannel: MethodChannel? = null

        fun notifyFlutterWorkoutsReceived(jsonPayload: String) {
            Handler(Looper.getMainLooper()).post {
                activeChannel?.invokeMethod("onWorkoutsReceivedFromPhone", jsonPayload)
            }
        }

        fun notifyFlutterWorkoutFinished(payload: String) {
            Handler(Looper.getMainLooper()).post {
                activeChannel?.invokeMethod("onWatchWorkoutFinished", payload)
            }
        }

        fun notifyFlutterRequestSync() {
            Handler(Looper.getMainLooper()).post {
                activeChannel?.invokeMethod("requestWorkoutsSync", null)
            }
        }
    }

    private var dataClient: DataClient? = null
    private var messageClient: MessageClient? = null
    private var nodeClient: NodeClient? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCH_CHANNEL)
        activeChannel = channel

        // Inicializa clientes Wearable se Google Play Services estiver presente
        try {
            dataClient = Wearable.getDataClient(this)
            messageClient = Wearable.getMessageClient(this)
            nodeClient = Wearable.getNodeClient(this)

            dataClient?.addListener(this)
            messageClient?.addListener(this)
        } catch (e: Exception) {
            Log.w(TAG, "Wearable API não disponível neste ambiente: ${e.message}")
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWorkoutsToWatch" -> {
                    val payload = call.argument<String>("workouts_payload")
                    if (payload != null) {
                        saveWorkoutsToLocalPrefs(payload)
                        pushWorkoutsViaWearableDataLayer(payload)
                    }
                    result.success(true)
                }

                "getLatestWatchWorkouts" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val json = prefs.getString(KEY_LATEST_WORKOUTS, null)
                    result.success(json)
                }

                "isWatchDevice" -> {
                    val isWatch = packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_WATCH)
                    result.success(isWatch)
                }

                "onWatchWorkoutFinished" -> {
                    val payload = call.argument<String>("payload")
                    if (payload != null) {
                        saveFinishedWorkoutToLocalPrefs(payload)
                        broadcastFinishedWorkoutToPhone(payload)
                    }
                    result.success(true)
                }

                "requestWorkoutsFromPhone" -> {
                    sendRequestSyncToPhone()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            dataClient?.removeListener(this)
            messageClient?.removeListener(this)
        } catch (_: Exception) {}
        activeChannel = null
        super.onDestroy()
    }

    private fun saveWorkoutsToLocalPrefs(payload: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LATEST_WORKOUTS, payload)
            .putLong(KEY_SYNCED_AT, System.currentTimeMillis())
            .apply()
    }

    private fun saveFinishedWorkoutToLocalPrefs(payload: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LAST_FINISHED, payload)
            .putLong(KEY_FINISHED_AT, System.currentTimeMillis())
            .apply()
    }

    /**
     * Envia os treinos atualizados para o smartwatch conectado via Wearable DataClient e MessageClient.
     */
    private fun pushWorkoutsViaWearableDataLayer(payload: String) {
        val client = dataClient ?: return
        val msgClient = messageClient ?: return
        val nClient = nodeClient ?: return

        scope.launch {
            try {
                // 1. DataClient: cria DataItem com sincronização garantida via Bluetooth/Nuvem
                val putDataMapReq = PutDataMapRequest.create(PATH_WORKOUTS).apply {
                    dataMap.putString("workouts_payload", payload)
                    dataMap.putLong("timestamp", System.currentTimeMillis())
                }
                val putDataReq = putDataMapReq.asPutDataRequest().setUrgent()
                client.putDataItem(putDataReq).await()
                Log.d(TAG, "⌚ DataItem /workouts enviado com sucesso via Wearable DataClient")

                // 2. MessageClient: envia notificação de push imediata para os nós conectados
                val nodes = nClient.connectedNodes.await()
                val data = payload.toByteArray(Charsets.UTF_8)
                for (node in nodes) {
                    msgClient.sendMessage(node.id, PATH_WORKOUTS, data).await()
                    Log.d(TAG, "⌚ Mensagem direta de treinos enviada para o nó: ${node.displayName} (${node.id})")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Aviso ao sincronizar via Wearable Data Layer: ${e.message}")
            }
        }
    }

    /**
     * Envia o treino finalizado e atualizado do relógio de volta para o smartphone.
     */
    private fun broadcastFinishedWorkoutToPhone(payload: String) {
        val msgClient = messageClient ?: return
        val nClient = nodeClient ?: return
        val client = dataClient ?: return

        scope.launch {
            try {
                // 1. DataClient
                val putDataMapReq = PutDataMapRequest.create(PATH_WORKOUT_FINISHED).apply {
                    dataMap.putString("payload", payload)
                    dataMap.putLong("timestamp", System.currentTimeMillis())
                }
                val putDataReq = putDataMapReq.asPutDataRequest().setUrgent()
                client.putDataItem(putDataReq).await()

                // 2. MessageClient
                val nodes = nClient.connectedNodes.await()
                val data = payload.toByteArray(Charsets.UTF_8)
                for (node in nodes) {
                    msgClient.sendMessage(node.id, PATH_WORKOUT_FINISHED, data).await()
                    Log.d(TAG, "⌚ Treino finalizado enviado para o nó celular: ${node.displayName}")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Aviso ao notificar celular sobre treino finalizado: ${e.message}")
            }
        }
    }

    /**
     * Solicita ao smartphone a lista mais recente de treinos.
     */
    private fun sendRequestSyncToPhone() {
        val msgClient = messageClient ?: return
        val nClient = nodeClient ?: return

        scope.launch {
            try {
                val nodes = nClient.connectedNodes.await()
                for (node in nodes) {
                    msgClient.sendMessage(node.id, PATH_REQUEST_SYNC, ByteArray(0)).await()
                    Log.d(TAG, "⌚ Solicitação de sincronização enviada para o nó celular: ${node.displayName}")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Aviso ao solicitar sincronização do celular: ${e.message}")
            }
        }
    }

    // --- DataClient.OnDataChangedListener ---
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED) {
                val path = event.dataItem.uri.path ?: continue
                if (path.startsWith(PATH_WORKOUTS)) {
                    val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                    val workoutsJson = dataMap.getString("workouts_payload")
                    if (!workoutsJson.isNullOrEmpty()) {
                        saveWorkoutsToLocalPrefs(workoutsJson)
                        notifyFlutterWorkoutsReceived(workoutsJson)
                    }
                }
            }
        }
    }

    // --- MessageClient.OnMessageReceivedListener ---
    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        val payload = String(messageEvent.data, Charsets.UTF_8)

        when {
            path.startsWith(PATH_WORKOUTS) -> {
                if (payload.isNotEmpty()) {
                    saveWorkoutsToLocalPrefs(payload)
                    notifyFlutterWorkoutsReceived(payload)
                }
            }
            path.startsWith(PATH_WORKOUT_FINISHED) -> {
                saveFinishedWorkoutToLocalPrefs(payload)
                notifyFlutterWorkoutFinished(payload)
            }
            path.startsWith(PATH_REQUEST_SYNC) -> {
                notifyFlutterRequestSync()
            }
        }
    }
}

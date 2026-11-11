# ⌚ Documentação de Integração Smart Watch (Apple Watch & Wear OS)

Esta documentação detalha a arquitetura, protocolos de comunicação, modelos de dados e o guia de implementação técnica passo a passo para a integração do **Titan Gym AI** com relógios inteligentes (**Apple Watch / watchOS** e **Samsung Galaxy Watch / Pixel Watch / Wear OS**).

---

## 1. Visão Geral da Arquitetura

O ecossistema utiliza o padrão **Companion Execution**:

```
 ┌──────────────────────────────────────────────────────────────┐
 │                      SMARTPHONE (Flutter)                    │
 │  • Criação e periodização de treinos via IA                  │
 │  • Edição minuciosa de cargas, reps e observações            │
 │  • Visualização detalhada de mapas anatômicos e gráficos     │
 │  • Armazenamento persistente e histórico geral               │
 └──────────────────────────────┬───────────────────────────────┘
                                │
                    Sincronização Bidirecional
              (WatchConnectivity / Wearable Data Layer)
                                │
 ┌──────────────────────────────▼───────────────────────────────┐
 │                   SMART WATCH (watchOS / Wear OS)            │
 │  • Visualização rápida dos treinos do dia                    │
 │  • Início e pausa do treino com 1 toque                      │
 │  • Check de séries concluídas e ajuste rápido de carga       │
 │  • Cronômetro de descanso háptico no pulso (Vibração Taptic) │
 │  • Monitoramento cardíaco contínuo (BPM) e calorias ativas   │
 └──────────────────────────────────────────────────────────────┘
```

---

## 2. Apple Watch (watchOS)

### 2.1 Tecnologias Utilizadas
* **watchOS SDK:** SwiftUI + Combine.
* **WatchConnectivity Framework:** `WCSession` para troca de dados entre iPhone (iOS) e Apple Watch (watchOS).
* **HealthKit:** `HKWorkoutSession` e `HKLiveWorkoutBuilder` para manter a sessão ativa em segundo plano no relógio com tela apagada e leitura contínua de batimentos cardíacos.

### 2.2 Estrutura do Target no Xcode
No diretório `ios/`:
1. Adicionar um novo Target no Xcode: **Watch App (SwiftUI)**.
2. Configurar o bundle identifier: `com.example.gymApp.watchkitapp`.
3. Adicionar a capacidade **HealthKit** e **Background Modes (Workout Processing)** no Watch App.

### 2.3 Bridge no iOS (`AppDelegate.swift` / `FlutterMethodChannel`)
No lado do iOS hospedeiro, configuramos o listener `WCSessionDelegate`:

```swift
import Flutter
import UIKit
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  private var session: WCSession?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if WCSession.isSupported() {
      session = WCSession.default
      session?.delegate = self
      session?.activate()
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let watchChannel = FlutterMethodChannel(name: "com.titangym.watch/sync",
                                              binaryMessenger: controller.binaryMessenger)

    watchChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "syncWorkoutsToWatch" {
        if let jsonString = call.arguments as? String {
          self?.sendWorkoutsToWatch(jsonString: jsonString)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "JSON esperado", details: nil))
        }
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func sendWorkoutsToWatch(jsonString: String) {
    guard let session = session, session.isReachable else {
      // Se o relógio não estiver em alcance imediato, atualiza o ApplicationContext para entrega em background
      try? session?.updateApplicationContext(["workouts_payload": jsonString])
      return
    }
    session.sendMessage(["workouts_payload": jsonString], replyHandler: nil, errorHandler: nil)
  }

  // WCSessionDelegate métodos obrigatórios
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  // Recebe conclusão de séries ou treinos vindos do relógio
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    if let action = message["action"] as? String, action == "workout_completed" {
      // Dispara evento de volta para o Flutter via EventChannel
    }
  }
}
```

---

## 3. Wear OS (Android)

### 3.1 Tecnologias Utilizadas
* **Wear OS Jetpack:** Jetpack Compose for Wear OS + Tiles API.
* **Google Play Services Wearable:** `DataClient` para cache persistente de treinos e `MessageClient` para comandos em tempo real.
* **Health Services API:** `ExerciseClient` para registro de batimentos cardíacos e calorias com baixo consumo energético.

### 3.2 Bridge no Android (`MainActivity.kt`)
No diretório `android/app/src/main/kotlin/...`:

```kotlin
import android.os.Bundle
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.titangym.watch/sync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "syncWorkoutsToWatch") {
                val payload = call.argument<String>("workouts_payload")
                if (payload != null) {
                    syncToWearable(payload)
                    result.success(true)
                } else {
                    result.error("ERROR", "Payload nulo", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun syncToWearable(jsonPayload: String) {
        val putDataMapReq = PutDataMapRequest.create("/active_workouts").apply {
            dataMap.putString("workouts_json", jsonPayload)
            dataMap.putLong("timestamp", System.currentTimeMillis())
        }
        val putDataReq = putDataMapReq.asPutDataRequest().setUrgent()
        Wearable.getDataClient(this).putDataItem(putDataReq)
    }
}
```

---

## 4. Contratos de Dados (JSON Sync Protocols)

Para manter a interoperabilidade universal entre o Flutter (mobile) e ambos os sistemas de relógios, todo o intercâmbio de mensagens segue os esquemas abaixo:

### 4.1 Smartphone ➡️ Smartwatch: `SYNC_WORKOUTS`
Enviado sempre que um novo treino é gerado por IA ou modificado pelo atleta:

```json
{
  "action": "SYNC_WORKOUTS",
  "generated_at": 1794160000,
  "user_name": "Lucas Rajão",
  "workouts": [
    {
      "id": "w1",
      "split_tag": "A",
      "title": "Treino A - Peito, Ombros e Tríceps",
      "duration_minutes": 50,
      "exercises": [
        {
          "id": "e1",
          "name": "Supino Reto com Barra",
          "weight_kg": 80.0,
          "sets": 4,
          "reps": 10,
          "rest_seconds": 90,
          "observations": "Cadência 3s na descida."
        },
        {
          "id": "e2",
          "name": "Desenvolvimento Militar",
          "weight_kg": 45.0,
          "sets": 3,
          "reps": 8,
          "rest_seconds": 75,
          "observations": "Travar abdômen."
        }
      ]
    }
  ]
}
```

### 4.2 Smartwatch ➡️ Smartphone: `SET_COMPLETED`
Enviado quando o usuário toca no botão de concluir a série no relógio (aciona o timer de descanso com feedback vibratório háptico):

```json
{
  "action": "SET_COMPLETED",
  "workout_id": "w1",
  "exercise_id": "e1",
  "set_index": 2,
  "weight_used_kg": 80.0,
  "reps_executed": 10,
  "heart_rate_bpm": 138,
  "timestamp": 1794160450
}
```

### 4.3 Smartwatch ➡️ Smartphone: `WORKOUT_FINISHED`
Enviado ao concluir o treino pelo relógio, alimentando automaticamente a tela de Evolução e Estatísticas do celular:

```json
{
  "action": "WORKOUT_FINISHED",
  "workout_id": "w1",
  "duration_seconds": 2880,
  "total_volume_kg": 7420.0,
  "avg_heart_rate": 132,
  "max_heart_rate": 164,
  "active_calories_kcal": 412,
  "completed_sets_count": 14,
  "completed_at": 1794162880
}
```

---

## 5. Próximos Passos para o Desenvolvimento da Fase 2 (Smartwatch)

1. **Target watchOS (SwiftUI):**
   * Criar a tela principal em SwiftUI com `List` contendo os cards dos Treinos (A, B, C...).
   * Criar a tela ativa de treino com botão grande circular para check de série e animação de descanso com `WKInterfaceDevice.current().play(.success)`.
2. **Target Wear OS (Compose for Wear OS):**
   * Utilizar componentes do `androidx.wear.compose:compose-material` (`ScalingLazyColumn`, `CompactChip`).
3. **Flutter Integration Service:**
   * Ativar o canal nativo `MethodChannel("com.titangym.watch/sync")` para disparar sempre que o método `StorageService().saveWorkouts()` for executado.

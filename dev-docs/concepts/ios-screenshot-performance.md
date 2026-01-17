# Konzept: iOS Screenshot-Performance optimieren

## Ausgangssituation

| Plattform | Screenshot-Dauer | Faktor |
|-----------|------------------|--------|
| Android   | ~5 Sekunden      | 1x     |
| iOS       | ~5 Minuten       | 60x    |

**Frage**: Woher kommt dieser Unterschied und kann iOS schneller werden?

---

## Analyse der Implementierungen

### Android-Ansatz (schnell)

**Dateien**:
- `android/app/src/androidTest/kotlin/com/stillmoment/screenshots/ScreengrabScreenshotTests.kt`
- `android/fastlane/Screengrabfile`

**Architektur**:
```
┌─────────────────────────────────────────────────────────┐
│ Emulator (einmal gestartet, bleibt warm)                │
├─────────────────────────────────────────────────────────┤
│ Test startet                                            │
│   ├── LocaleTestRule setzt Locale auf "de-DE"           │
│   ├── 5 Screenshots werden gemacht                      │
│   ├── LocaleTestRule wechselt zu "en-US" (im Speicher!) │
│   └── 5 Screenshots werden gemacht                      │
│ Test endet                                              │
└─────────────────────────────────────────────────────────┘
Gesamtdauer: ~5 Sekunden
```

**Schlüssel-Mechanismen**:
1. `LocaleTestRule` - Locale-Wechsel **ohne App-Neustart**
2. `composeRule.waitForIdle()` - Wartet nur auf echte UI-Stabilität
3. `composeRule.waitUntil { condition }` - Polling, beendet sofort wenn erfüllt
4. Kein hardcoded sleep/delay vor Screenshots

### iOS-Ansatz (langsam)

**Dateien**:
- `ios/StillMomentUITests/ScreenshotTests.swift`
- `ios/StillMomentUITests/SnapshotHelper.swift`
- `ios/fastlane/Snapfile`

**Architektur**:
```
┌─────────────────────────────────────────────────────────┐
│ Sprache: de-DE                                          │
├─────────────────────────────────────────────────────────┤
│ Simulator starten (~30s)                                │
│ App launchen (~10s)                                     │
│ Test 1: sleep(1) + Screenshot                           │
│ Test 2: sleep(1) + Screenshot                           │
│ Test 3: sleep(1) + Screenshot                           │
│ Test 4: sleep(1) + Screenshot                           │
│ Test 5: sleep(1) + Screenshot                           │
│ Simulator beenden                                       │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Sprache: en-US (kompletter Neustart!)                   │
├─────────────────────────────────────────────────────────┤
│ Simulator starten (~30s)                                │
│ App launchen (~10s)                                     │
│ ... gleiche 5 Tests ...                                 │
│ Simulator beenden                                       │
└─────────────────────────────────────────────────────────┘
Gesamtdauer: ~5 Minuten
```

**Bottlenecks identifiziert**:

| Bottleneck | Ort | Auswirkung |
|------------|-----|------------|
| Simulator-Neustart pro Sprache | Fastlane Snapshot Design | +60s pro Sprache |
| Hardcoded `sleep(1)` | SnapshotHelper.swift:159 | +10s total |
| Sequenzielle Sprachen | Snapfile:38 `concurrent_simulators(false)` | 2x statt parallel |
| Großzügige Timeouts | ScreenshotTests.swift | +10-20s gesamt |

---

## Ursachen im Detail

### 1. Sprach-Wechsel (Hauptursache, ~80% der Zeit)

**Android LocaleTestRule**:
```kotlin
// Wechselt Locale im laufenden Prozess
@get:Rule val localeTestRule = LocaleTestRule()
// → Resources werden neu geladen, App läuft weiter
```

**iOS Fastlane Snapshot**:
- Liest `languages` aus Snapfile
- Startet für **jede Sprache** einen komplett neuen Simulator-Prozess
- Setzt System-Locale vor App-Start
- Keine Möglichkeit, Sprache während Test zu wechseln

**Warum?** iOS `NSLocalizedString` und SwiftUI `Text("key")` cachen Lokalisierungen beim App-Start. Ein Runtime-Wechsel erfordert entweder:
- App-Neustart (aktueller Ansatz)
- Bundle-Swizzling (fragil, Apple undokumentiert)
- Eigenes Lokalisierungs-System (hoher Aufwand)

### 2. Animation Delay

**iOS SnapshotHelper.swift:159**:
```swift
if Snapshot.waitForAnimations {
    sleep(1) // Waiting for the animation to be finished (kind of)
}
```
- Wird vor **jedem** `snapshot()` Aufruf ausgeführt
- 5 Screenshots × 2 Sprachen × 1s = 10 Sekunden

**Android**: Kein Äquivalent - `waitForIdle()` wartet nur auf echte UI-Stabilität

### 3. Keine Parallelisierung

**iOS Snapfile:38**:
```ruby
concurrent_simulators(false)  # Explizit deaktiviert
```

Ursprünglicher Grund war Stabilität, aber moderne Macs mit Apple Silicon könnten parallele Simulatoren problemlos handhaben.

---

## Optimierungsoptionen

### Option A: Quick Wins (Empfohlen)

**Aufwand**: Gering (1-2 Stunden)
**Ergebnis**: ~2-3 Minuten statt 5 Minuten

| Änderung | Datei | Zeile |
|----------|-------|-------|
| Animation Delay: `sleep(1)` → `usleep(300_000)` | SnapshotHelper.swift | 159 |
| Parallel: `concurrent_simulators(true)` | Snapfile | 38 |
| Timeouts reduzieren wo sinnvoll | ScreenshotTests.swift | diverse |

**Risiken**:
- Concurrent Simulators könnte auf älteren Macs instabil sein
- Zu kurzer Animation Delay könnte zu Screenshot-Glitches führen

### Option B: In-App Language Switching

**Aufwand**: Hoch (1-2 Tage)
**Ergebnis**: ~30-60 Sekunden (Android-Niveau)

**Ansatz**:
1. Eigenes `LocalizationManager` implementieren
2. Strings nicht via `NSLocalizedString`, sondern via Manager laden
3. SwiftUI Views subscriben auf Sprach-Änderungen
4. Screenshots-Test wechselt Sprache ohne App-Neustart

**Implementierung**:
```swift
// Neuer LocalizationManager
class LocalizationManager: ObservableObject {
    @Published var currentLocale: Locale = .current

    private var bundle: Bundle = .main

    func setLocale(_ locale: Locale) {
        guard let path = Bundle.main.path(forResource: locale.identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return }
        self.bundle = bundle
        self.currentLocale = locale
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// In Views
@EnvironmentObject var localization: LocalizationManager
Text(localization.string("timer.start"))
```

**Probleme**:
- Alle `Text("key")` müssten umgeschrieben werden
- Verlust von SwiftUI Localization-Previews
- Maintenance-Overhead für zwei Lokalisierungs-Systeme

### Option C: Preview Screenshot Testing (Xcode 16+)

**Aufwand**: Mittel (2-4 Stunden Setup + Migration)
**Ergebnis**: Potenziell <10 Sekunden

**Konzept**:
- Swift Testing Framework mit `#Preview` Macro
- Screenshots direkt von Preview-Renderern
- Kein Simulator nötig

**Status**: Experimentell, keine direkte Fastlane-Integration

---

## Empfehlung

**Für Still Moment empfehle ich Option A (Quick Wins)**:

1. **ROI stimmt**: 50-60% Zeitersparnis bei minimalem Aufwand
2. **Kein Breaking Change**: Bestehende Architektur bleibt intakt
3. **Reversibel**: Bei Problemen einfach zurückrollbar

Option B wäre nur sinnvoll wenn:
- Screenshots sehr häufig generiert werden (täglich)
- CI/CD-Kosten ein signifikanter Faktor sind
- Ohnehin eine Lokalisierungs-Überarbeitung geplant ist

---

## Implementierungsplan für Quick Wins

### Schritt 1: Animation Delay reduzieren

**Datei**: `ios/StillMomentUITests/SnapshotHelper.swift:159`

```swift
// Vorher
sleep(1) // Waiting for the animation to be finished (kind of)

// Nachher
usleep(300_000) // 0.3s - Modern animations complete faster
```

### Schritt 2: Concurrent Simulators aktivieren

**Datei**: `ios/fastlane/Snapfile:38`

```ruby
# Vorher
concurrent_simulators(false)

# Nachher
concurrent_simulators(true)
```

### Schritt 3: Timeouts prüfen

**Datei**: `ios/StillMomentUITests/ScreenshotTests.swift`

Alle `waitForExistence(timeout: 10.0)` prüfen und wo sicher auf 5.0 reduzieren.

### Verifikation

```bash
cd ios
time make screenshots  # Vorher: ~5 Minuten
# Nach Änderungen erneut messen
time make screenshots  # Erwartet: ~2-3 Minuten
```

---

## Fazit

Der Hauptgrund für den Geschwindigkeitsunterschied ist **architektonisch bedingt**: Android's `LocaleTestRule` ermöglicht In-Memory Locale-Switching, während iOS Fastlane Snapshot für jede Sprache einen kompletten Simulator-Neustart erfordert.

Mit Quick Wins kann iOS von ~5 Minuten auf ~2-3 Minuten optimiert werden. Android-Niveau (~5 Sekunden) würde eine grundlegende Änderung des Lokalisierungs-Systems erfordern, was für Still Moment wahrscheinlich nicht den Aufwand wert ist.

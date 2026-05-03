# Implementierungsplan: shared-082 (Android)

Ticket: [shared-082](../shared/shared-082-download-konstellations-animation.md)
Plattform: **Android**
Erstellt: 2026-05-03

---

## Scope

Android-Teil von shared-082: Konstellations-Animation als Download-Modal + neue Cancel-API in `UrlAudioDownloaderProtocol`. Ersetzt den `AlertDialog` mit `CircularProgressIndicator` in `DownloadProgressDialog`.

Der iOS-Teil läuft separat (`shared-082-ios.md` — falls noch nicht vorhanden, kommt später).

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `domain/services/UrlAudioDownloaderProtocol.kt` | Domain | Erweitern | `fun cancel()` ergänzen |
| `infrastructure/network/UrlAudioDownloaderImpl.kt` | Infrastructure | Erweitern | Aktiven Coroutine-Job halten + cancel(); Tests anpassen |
| `infrastructure/network/UrlAudioDownloaderTest.kt` | Test | Erweitern | Cancel-Tests (laufender Download, kein Download aktiv) |
| `presentation/ui/theme/Type.kt` | Presentation | Erweitern | `TypographyRole.DialogTitle` (18sp Light), `TypographyRole.DialogBody` (12sp Normal); colorRole-Mapping |
| `presentation/ui/common/ConstellationLoader.kt` | Presentation | **NEU** | Konstellations-Animation als Composable (Canvas, Phasenversatz, Lifecycle-aware) |
| `presentation/ui/common/DownloadProgressModal.kt` | Presentation | **NEU** | Modal-Card mit Backdrop, Animation, Title, Body, Cancel-Button |
| `presentation/navigation/NavGraph.kt` | Presentation | Refactoring | `DownloadUrlEffect` so umstrukturieren, dass das Overlay als Child der äusseren Box rendert (über NavHostScaffold). Cancel ruft `urlAudioDownloader.cancel()`. Alten `DownloadProgressDialog` entfernen |
| `res/values/strings.xml` + `values-de/strings.xml` | Resources | Ergänzen | Neue Keys: `download_modal_body`, `download_modal_cancel_a11y` (`download_loading` + `download_error_cancel` werden weiterverwendet) |
| `app/src/androidTest/.../DownloadProgressModalTest.kt` | Instrumented Test | **NEU** | Compose-UI-Test: Cancel-Button ruft Callback; Backdrop-Tap macht nichts |
| `presentation/ui/common/DownloadProgressModalPreviews.kt` | Presentation | **NEU** | 6 `@Preview`-Funktionen: 3 Themes × Light/Dark, für IDE-Sidepanel-Review |
| `CHANGELOG.md` | Docs | Ergänzen | Polish-Eintrag |

---

## API-Recherche

### Compose Animation
- **`rememberInfiniteTransition` + `animateFloat`** — Standard für Endlos-Animationen. Pro-Punkt einen Winkel animieren, mit Phasenversatz über `initialStartOffset = StartOffset(-phaseMs.toInt(), StartOffsetType.FastForward)` (Phasenversatz wie CSS `animation-delay: -1.3s`).
- **Alternative `withInfiniteAnimationFrameMillis`** (in `androidx.compose.ui:ui` ab Compose UI 1.1) — gibt Frame-Millis als Long. Damit lässt sich die Animation manuell treiben (Loop in `LaunchedEffect`), Phase pro Punkt aus dem Offset berechnen. **Bevorzugt**, weil das die Lifecycle-Pause sauber ermöglicht (Loop bricht bei `isActive=false` ab).
- **`Canvas`** mit `drawCircle()` für Kern + Punkte. Glow via zweitem, grösserem semitransparenten Kreis (Compose hat keinen Box-Shadow auf Canvas-Operationen — siehe Hinweis in Handoff-Skizze).

### Lifecycle
- **`androidx.lifecycle:lifecycle-runtime-compose:2.8.7`** ist in `app/build.gradle.kts` bereits eingebunden.
- **`LocalLifecycleOwner.current`** + **`DisposableEffect` mit `LifecycleEventObserver`** ist das stabile Pattern, um auf `Lifecycle.Event.ON_PAUSE`/`ON_RESUME` zu reagieren. (Lifecycle 2.8 hat zusätzlich `lifecycle.eventFlow`, aber `DisposableEffect` ist im Projekt anschlussfähiger.)

### Coroutines / Cancel
- `kotlinx.coroutines.Job.cancel()` cancelt einen laufenden Job. Innerhalb von `withContext(Dispatchers.IO) { … }` cancelt sich der Block deterministisch — `IOException`/`CancellationException` propagiert hoch, der `try`-Block wirft, der `finally`-Block schliesst die `HttpURLConnection`.
- `coroutineContext[Job]` innerhalb der `suspend fun` liefert den aktuellen Job — wir merken ihn uns in `currentJob: Job?` und `cancel()` ruft `currentJob?.cancel()`.
- Standard-Pattern: **Bei Cancel wirft `connection.inputStream.read()` (in `copyTo`) eine `IOException`** (Stream wird closed). Wir fangen das schon im existierenden `catch (e: IOException)` — der zurückgegebene `Result.failure(e)` enthält die Exception. AKs verlangen `Result.failure mit CancellationException` — daher müssen wir explizit prüfen, ob der Job cancelled ist und stattdessen eine `CancellationException` zurückgeben (oder den Job mit `coroutineContext.ensureActive()` werfen lassen).

### Compose-Tests
- `createComposeRule()` für isolierte Composable-Tests (existierendes Pattern: `TimerScreenTest`).
- Compose-Tests laufen in `app/src/androidTest/` (instrumentiert, langsamer als Unit-Tests, aber notwendig für UI-Verifikation).

---

## Design-Entscheidungen

### 1. Modal-Rendering: Custom Box, nicht Dialog

**Trade-off:** `Dialog`-Composable wäre einfacher (nutzt System-Window, immer obenauf), aber liegt ausserhalb der Theme-Composition und macht Backdrop-Steuerung umständlich. Custom Box bleibt im Theme, aber muss in der Komposition korrekt platziert werden.

**Entscheidung:** Wie im Ticket vorgegeben: Custom `Box(Modifier.fillMaxSize())` als zweites Child der äusseren Box in `StillMomentNavHost` (nach `NavHostScaffold`). Das deckt die ganze Activity ab inkl. BottomBar.

**Konsequenz:** `DownloadUrlEffect` muss umstrukturiert werden — der `isDownloading` State wird nach oben gehoben (in `StillMomentNavHost`), und das Modal wird parallel zu NavHostScaffold gerendert.

### 2. Animation: `withInfiniteAnimationFrameMillis` statt `rememberInfiniteTransition`

**Trade-off:** `rememberInfiniteTransition` ist deklarativer, aber Pause/Resume ist fummelig (Animation-Targets re-keyen funktioniert, ist aber unschön). `withInfiniteAnimationFrameMillis` ist imperativer, dafür sauber pausierbar (Loop in `LaunchedEffect(isActive) { … }` startet/stoppt mit dem Flag).

**Entscheidung:** `withInfiniteAnimationFrameMillis` in einem `LaunchedEffect(isActive)`, das einen `var elapsedMs: Long` State akkumuliert. Aus dem `elapsedMs` werden Kern-Scale und Punkt-Winkel rein deterministisch berechnet (Phasenversatz = additive Konstante).

### 3. Glow-Rendering im Canvas

**Trade-off:** Compose `Modifier.shadow()` arbeitet nur auf Composable-Bounds, nicht auf einzelnen Canvas-Drawings. Echte BlurMaskFilter ist platform-API, nicht Canvas-nativ.

**Entscheidung:** Glow als zweiter, grösserer Kreis mit Alpha (z.B. Punkt-Radius × 2.5, alpha 0.6). Visuell ausreichend — passt zur "atmosphärischen" Anmutung. Das ist auch die Skizze im Handoff (`drawCircle` mit grösserem semitransparentem Hintergrund-Circle).

### 4. Cancel-Semantik: Result.failure(CancellationException)

**Trade-off:** Ein abgebrochener Download könnte still gar kein Result liefern (`download` returns nicht), oder ein `Result.failure(CancellationException)`. Letzteres ist explizit und vom AK gefordert.

**Entscheidung:** Im `try`-Block prüfen wir nach jedem I/O-Step `coroutineContext.ensureActive()`. Wenn cancelled, propagiert `CancellationException` — den fangen wir mit eigenem `catch (e: CancellationException)` und returnen `Result.failure(e)`. Vorsicht: `CancellationException` muss innerhalb von Kotlin-Coroutines normalerweise re-thrown werden — wir testen explizit, dass der Caller (LaunchedEffect) korrekt cancelt und nicht in einem hängengebliebenen State landet.

**Alternative geprüft & verworfen:** Den Job einfach cancellen und auf `result.getOrNull() == null` prüfen. Verworfen, weil das AK explizit `Result.failure mit CancellationException` fordert (Cancel-Pfad muss klar von Fehler-Pfad unterscheidbar sein, damit der Caller das Error-Modal NICHT zeigt).

### 5. Lifecycle-Pause: `isActive`-Flag im ConstellationLoader

**Entscheidung:** `ConstellationLoader(isActive: Boolean)` nimmt einen Boolean. Im Caller: `var isAppActive by remember { mutableStateOf(true) }` + `DisposableEffect(lifecycleOwner) { val obs = LifecycleEventObserver { _, event -> when(event) { ON_PAUSE -> isAppActive=false; ON_RESUME -> isAppActive=true; else -> {} } }; lifecycleOwner.lifecycle.addObserver(obs); onDispose { lifecycleOwner.lifecycle.removeObserver(obs) } }`. Wenn `isActive=false`: Loop läuft nicht, statisches Bild bleibt stehen (Punkte halten letzte Winkel).

### 6. Typography: DialogTitle/DialogBody an iOS-Spec angepasst

**Entscheidung:** Auf Android nutzen wir Nunito (kein Newsreader/Geist verfügbar — App nutzt durchgängig Nunito statt iOS-Fontstack). Sizes wie iOS-Pendant: 18sp/12sp.
- `TypographyRole.DialogTitle` → `FontSpec(18.sp, FontWeight.Light)`, `colorRole = TextPrimary`
- `TypographyRole.DialogBody` → `FontSpec(12.sp, FontWeight.Normal)`, `colorRole = TextSecondary`

Dark-Mode-Halation-Kompensation greift automatisch (Light → Normal).

---

## Refactorings

### 1. `DownloadUrlEffect` aufteilen — State + Modal trennen

**Warum:** Aktuell ist `DownloadUrlEffect` eine "Effect"-Composable, die zwei `AlertDialog`s rendert. Für das Custom-Overlay muss das Modal in der äusseren `Box` liegen (siehe Entscheidung 1).

**Plan:**
- `DownloadUrlEffect` behält die LaunchedEffect-Logik (Download starten, State setzen).
- Neuer Parameter: `onCancelRequest: () -> Unit`, der im Modal-Overlay genutzt wird.
- Der `isDownloading`-State und `failedUrl`-State werden ins `StillMomentNavHost` gehoben (oder in einen kleinen State-Holder gekapselt: `rememberDownloadState()`).
- `DownloadProgressOverlay` (neue Composable) wird im `StillMomentNavHost` innerhalb der äusseren Box als Sibling von `NavHostScaffold` gerendert.
- `DownloadErrorDialog` bleibt unverändert (System-`AlertDialog`, nicht im Scope).

**Risiko:** Mittel. `DownloadUrlEffect` hat aktuell eine subtile Cancel-Race (LaunchedEffect-key auf `downloadUrl`, klärt Kommentar in 657–659). Beim Refactor diese Garantie nicht brechen — der State, der die LaunchedEffect triggert, bleibt der `pendingDownloadUrl`-Flow vom Caller.

### 2. `UrlAudioDownloaderImpl` — Job-Hold ergänzen

**Warum:** Cancel braucht einen Handle auf den laufenden Job.

**Plan:**
- `@Volatile private var currentJob: Job? = null` (Visibility-Garantie über Threads; AtomicReference wäre Overengineering bei single-download-Assumption)
- In `download()`: `currentJob = coroutineContext[Job]`
- `cancel()`: `currentJob?.cancel(CancellationException("User cancelled download"))`
- Im `try`-Block nach grösseren Schritten `coroutineContext.ensureActive()` — schnellere Reaktion auf Cancel.
- `catch (e: CancellationException)` ergänzen, returnt `Result.failure(e)`.
- **Threadsicherheit:** In der App läuft nur ein Download zur Zeit (DownloadUrlEffect ist Singleton-State, LaunchedEffect-Lifecycle garantiert Sequenzialität). `@Volatile` deckt Visibility ab, kein paralleler Multi-Download-Schutz nötig. Kommentar im Code dokumentiert diese single-download-Annahme.

**Risiko:** Niedrig. Existierende 12 Tests im `UrlAudioDownloaderTest` decken den glücklichen Pfad — die müssen nicht angefasst werden, weil `cancel()` ein additives API ist.

---

## Fachliche Szenarien

### AK: Cancel-API in UrlAudioDownloaderProtocol

- **Gegeben:** Ein Download läuft (HTTP-Connection liest Bytes).
  **Wenn:** Caller ruft `urlAudioDownloader.cancel()`.
  **Dann:** Der `download()`-Aufruf returnt `Result.failure(CancellationException)`. HTTP-Connection ist disconnected (kein Leak).

- **Gegeben:** Kein Download läuft.
  **Wenn:** Caller ruft `urlAudioDownloader.cancel()`.
  **Dann:** Kein Crash, kein Effekt. Folge-`download()`-Aufrufe funktionieren normal.

- **Gegeben:** Ein Download wurde abgebrochen.
  **Wenn:** Erneut `download(url)` mit derselben URL aufgerufen wird.
  **Dann:** Download läuft sauber neu, returnt `Result.success(uri)`.

### AK: Modal-Layout

- **Gegeben:** Eine MP3-URL wird geteilt, Download startet.
  **Wenn:** Das Modal erscheint.
  **Dann:** Sichtbar sind: Backdrop (dunkel, 55% Opacity), zentrierte Card (max 320dp breit), darin Animation → Title → Body → Cancel-Button.

- **Gegeben:** Modal ist sichtbar.
  **Wenn:** User tippt auf den Backdrop ausserhalb der Card.
  **Dann:** Nichts passiert. Modal bleibt offen.

- **Gegeben:** Modal ist sichtbar, Card hat Kupfer-Theme aktiv.
  **Wenn:** User wechselt zu Salbei-Theme.
  **Dann:** Konstellation und Cancel-Button-Text wechseln auf grün-glow (`theme.interactive`).

### AK: Konstellations-Animation

- **Gegeben:** Modal erscheint frisch.
  **Wenn:** Animation startet.
  **Dann:** Atmender Kern pulsiert (8dp Durchmesser, scale 0.9↔1.15, 4.2s easeInOut). 5 Punkte rotieren auf 2 Orbitalbahnen (30dp und 42dp) mit Umlaufzeiten 6.5s/9.0s. Phasenversatz wie in der Tabelle.

- **Gegeben:** Modal ist sichtbar, Animation läuft.
  **Wenn:** App wechselt in den Hintergrund (ON_PAUSE).
  **Dann:** Die Frame-Loop pausiert (`isActive=false`). Punkte halten ihre letzte Position.

- **Gegeben:** Animation ist pausiert (App im Hintergrund).
  **Wenn:** App kehrt in den Vordergrund (ON_RESUME).
  **Dann:** Loop läuft sofort weiter. Animation springt nicht (Punkte bewegen sich aus letzter Position).

### AK: Cancel-Verhalten Android

- **Gegeben:** Modal ist sichtbar, Download läuft.
  **Wenn:** User tippt auf "Abbrechen".
  **Dann:** `urlAudioDownloader.cancel()` wird sofort aufgerufen (Cancel ist 0ms), Modal verblasst mit 200ms Fade-out (konsistent zum Erfolgsfall), kein Type-Selection-Sheet erscheint, kein Eintrag in der Library.

- **Gegeben:** Download wurde abgebrochen.
  **Wenn:** Der Download wirft `CancellationException`.
  **Dann:** `DownloadUrlEffect.LaunchedEffect`-Loop fängt das im `result.fold(...)`-Pfad **nicht** als Fehler — `failedUrl` bleibt `null`, der Error-Dialog erscheint nicht.

### AK: Texte (DE + EN)

- **Gegeben:** Geräte-Locale ist Deutsch.
  **Wenn:** Modal erscheint.
  **Dann:** Title = "Meditation wird geladen…", Body = "Einen Moment, wir holen die Aufnahme zu dir.", Cancel = "Abbrechen".

- **Gegeben:** Geräte-Locale ist Englisch.
  **Wenn:** Modal erscheint.
  **Dann:** Title = "Loading meditation…", Body = "One moment, we're fetching the recording for you.", Cancel = "Cancel".

### AK: Accessibility

- **Gegeben:** TalkBack ist aktiv, Modal erscheint.
  **Wenn:** Fokus landet automatisch im Modal (durch `Modifier.semantics { role = Role.Alert; isTraversalGroup = true }`).
  **Dann:** Title und Body werden vorgelesen.

- **Gegeben:** TalkBack ist aktiv, Cancel-Button hat Fokus.
  **Wenn:** TalkBack liest das Element vor.
  **Dann:** "Download abbrechen" (DE) oder "Cancel download" (EN) wird gelesen, nicht nur "Abbrechen"/"Cancel".

- **Gegeben:** TalkBack ist aktiv.
  **Wenn:** User navigiert durch die Konstellation.
  **Dann:** Animation wird übersprungen (kein `accessibilityElement`, dekorativ).

---

## Reihenfolge der Akzeptanzkriterien (TDD-Reihenfolge)

1. **Cancel-API in UrlAudioDownloaderProtocol** — Pure Domain/Infrastructure, mit Unit-Tests (kein UI). Erste Stufe, weil sie die Foundation bildet.
2. **Typography-Rollen `DialogTitle` / `DialogBody`** — Reine Datei-Erweiterung in `Type.kt`, kein Test nötig (Pattern existiert bereits).
3. **`ConstellationLoader`-Composable** — Isoliertes UI-Element. Kein Compose-Test (Animation = visuell), aber manuelle Verifikation in Preview-Screen.
4. **`DownloadProgressModal`-Composable** — Card + Backdrop + Cancel. Compose-UI-Test: Cancel-Click ruft Callback. Backdrop-Tap macht nichts.
5. **NavGraph-Integration** — `DownloadUrlEffect` umstrukturieren, Modal in StillMomentNavHost rendern, Cancel-Pfad zum `urlAudioDownloader.cancel()` durchverdrahten.
6. **Strings + Accessibility** — Neue String-Keys, semantics-Modifier setzen.
7. **Manuelle Verifikation** der Theme-Matrix (3 Themes × Light/Dark) und Lifecycle-Pause.

---

## Vorbereitung

Keine externen Vorbereitungen nötig. Alle benötigten Libraries (Compose, Lifecycle-Compose, Coroutines) sind bereits eingebunden.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `withInfiniteAnimationFrameMillis` läuft zu schnell auf 120Hz-Geräten und CPU steigt | Loop berechnet Werte deterministisch aus `elapsedMs` — kein Timing-bedingter Drift. CPU-Last ist linear zur Refresh-Rate, das ist OK auf modernen Geräten. |
| Cancel-Race: `cancel()` wird gerufen während `connection.connect()` noch nicht aktiv ist | `currentJob?.cancel()` cancelt den `withContext`-Job. Beim nächsten `ensureActive()` wirft die Coroutine. Connection wird im `finally` disconnectet. |
| `CancellationException` darf in Coroutines nicht schluckt werden | Wir fangen sie explizit zurueck nur in `download()` und returnen `Result.failure(e)`. Der Caller (LaunchedEffect) erkennt anhand des Exception-Typs, dass es Cancel war (kein Error-Dialog). Test verifiziert das. |
| Modal überlappt mit `DownloadErrorDialog` (beide wollen sichtbar sein) | Logik: `failedUrl != null` schliesst aus, dass Download läuft. Reihenfolge: `cancel` → `isDownloading=false` → kein Error → kein Dialog. Bei echten Fehlern: `isDownloading=false` zuerst, dann Error-Dialog. **Modal nur wenn `isDownloading=true`**. |
| Compose-UI-Test ist instrumentiert (langsam) | OK — nur 1-2 Smoke-Tests, kein Snapshot. Existierender Pattern in `TimerScreenTest`. |
| Bei Theme-Wechsel während Animation: Phase könnte springen | `withInfiniteAnimationFrameMillis`-Loop läuft in einem `LaunchedEffect` mit `isActive`-Key. Theme-Wechsel triggert keinen `isActive`-Change, der Loop läuft durch. Phase bleibt stabil. |

---

## Entschiedene Punkte

- ✅ **Compose-Previews:** Eigene Datei `DownloadProgressModalPreviews.kt` mit 6 `@Preview`-Funktionen (3 Themes × Light/Dark). Erleichtert Review der Theme-Matrix ohne App-Build.
- ✅ **Cancel-Animation:** 200ms Fade-Out konsistent zum Erfolgsfall (eine Schliess-Animation für das Modal). Cancel-Logik wird sofort ausgelöst, nur die visuelle Hülle verblasst noch.
- ✅ **`UrlAudioDownloaderImpl.cancel()` Thread-Safety:** `@Volatile private var currentJob: Job? = null` — Visibility-Garantie über Threads, kein AtomicReference nötig (single-download-Assumption durch LaunchedEffect-Lifecycle).

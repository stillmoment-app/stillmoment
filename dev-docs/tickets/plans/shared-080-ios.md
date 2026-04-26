# Implementierungsplan: shared-080 (iOS)

Ticket: [shared-080](../shared/shared-080-completion-screen-survive-termination.md)
Erstellt: 2026-04-26

## Ziel

Der Danke-Screen ueberlebt App-Termination. Wenn die gefuehrte Meditation natuerlich endet, wird ein persistenter Marker via `@SceneStorage` geschrieben. Beim naechsten Scene-Activate (Cold Launch nach OS-Termination) zeigt die App auf Top-Level den `MeditationCompletionView`-Overlay.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/CompletionMarker.swift` | Domain | Neu | Pure Wert-Logik: `isExpired(completedAt:now:ttl:)`. Frei von SwiftUI/UIKit. |
| `Presentation/Views/Shared/RootContainerView.swift` | Presentation | Neu | Halter fuer `@SceneStorage`. Liefert `TabView` als Inhalt und legt das Top-Level-Overlay darueber. Snapshot-Logik (siehe Design-Entscheidung 1). |
| `Presentation/Views/Shared/MeditationCompletionView.swift` | Presentation | Wiederverwenden | Bereits lokalisiert. Im Top-Level-Overlay mit Theme-Hintergrund einbetten. |
| `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | Erweitern | Neue `@Published var completionEvent: CompletionEvent?` (oder PassthroughSubject). Wird gefeuert, wenn `state==.finished`. |
| `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` | Presentation | Erweitern | Liest dasselbe `@SceneStorage`-Key-Set. `.onChange(of: viewModel.playbackState)` schreibt Marker bei `.finished`. `onAppear` (= neue Meditation laed) loescht alte Marker. |
| `StillMomentApp.swift` | Composition Root | Erweitern | `WindowGroup`-Body wechselt von direkter `TabView` zu `RootContainerView { TabView { … } }`. |
| `StillMomentTests/Domain/CompletionMarkerTests.swift` | Tests | Neu | Expiry-Logik (pure function). |
| `StillMomentTests/GuidedMeditationPlayerViewModelTests.swift` | Tests | Erweitern | `completionEvent` wird bei `.finished` gefeuert, NICHT bei manuellem Stop / Audio-Konflikt / Cleanup. |
| `StillMomentUITests/MeditationCompletionOverlayUITests.swift` (optional) | UI Tests | Neu | Launch-Argumente, die SceneStorage-Werte vorbelegen, und prueft, ob das Overlay nach Cold Launch erscheint bzw. nach Tap auf "Zurueck" verschwindet. |

## API-Recherche

- **`@SceneStorage`** — Apple-Standardweg fuer State, der Scene-Discard und OS-Termination ueberlebt. Verfuegbar ab iOS 14. Werte muessen `RawRepresentable` mit `Bool/Int/Double/String/URL/Data`-Raw-Type sein — fuer einen Codable-Marker daher: zwei Werte (`completedAtTimestamp: Double`, `meditationId: String`) statt JSON-Blob. **Gewaehlt.**
- **Force-Quit-Verhalten:** `@SceneStorage` wird beim Force-Quit (App-Switcher hochwischen) geloescht. Das ist hier ein Feature, keine Schwachstelle: ein bewusster Force-Quit ist ein "ich bin durch"-Signal — der Danke-Screen darf dann unterdrueckt werden.
- **`UserDefaults`/`@AppStorage`** — wuerde auch Force-Quits ueberleben und jeden Marker aggressiv mitschleppen. Mehr Boilerplate (Repository, Codable-Roundtrip), keine Vorteile fuer den Use Case. **Verworfen.**
- **`AVPlayerItem.AVPlayerItemDidPlayToEndTime`** — bereits in `AudioPlayerService` abonniert; loest `handlePlaybackFinished` aus, das `state.send(.finished)` triggert. Damit ist der "natuerliches Ende"-Pfad eindeutig markierbar.
- **iOS Deployment Target 16+** — `@Observable` nicht verfuegbar; weiterhin `ObservableObject`-Pattern.

## Design-Entscheidungen

### 1. Snapshot-Pattern verhindert Doppel-Anzeige (Kernpunkt!)

**Problem:** `@SceneStorage` ist reaktiv — wenn der Player-View zur Laufzeit den Marker schreibt, wuerde die App-Root-View neu rendern und das Overlay zusaetzlich zum bereits in-place sichtbaren Danke-Screen einblenden. Das verletzt explizit AK-Test "Danke-Screen wird nicht doppelt angezeigt".

**Trade-off:** Drei Varianten:
- (a) Cross-cutting State "is Player active" — fragil, koppelt App-Root an Player.
- (b) `@SceneStorage` direkt zur Render-Steuerung — bricht Doppel-Anzeige-Test.
- (c) Snapshot in `@State` beim ersten `onAppear` — der App-Root liest den `@SceneStorage`-Wert genau einmal pro Scene-Lifecycle, schreibt ihn in `@State`, und treibt das Overlay nur ueber das `@State`. Spaetere Schreibvorgaenge (waehrend Player aktiv ist) aendern den Snapshot nicht mehr.

**Entscheidung:** (c). `RootContainerView` haelt:
```swift
@SceneStorage("completion.completedAt") private var completedAtRaw: Double = 0
@SceneStorage("completion.meditationId") private var meditationIdRaw: String = ""
@State private var initialMarker: InitialMarker?

enum InitialMarker { case present, absent }
```
In `onAppear` (genau einmal pro Container-Lifecycle, geguarded mit `initialMarker == nil`) wird `CompletionMarker.isExpired(completedAt: completedAtRaw, …)` ausgewertet und entweder `.present` oder `.absent` gesetzt. Tap auf "Zurueck": `completedAtRaw = 0`, `meditationIdRaw = ""`, `initialMarker = .absent`.

Bei Cold Launch nach OS-Termination: `@SceneStorage` ist gefuellt, `initialMarker = .present`, Overlay erscheint. Bei warmem Resume waehrend laufender Meditation: Container hatte schon mal `onAppear`, `initialMarker` ist seit dem Start `.absent` (Marker war beim Launch leer), bleibt `.absent` auch wenn `@SceneStorage` jetzt geschrieben wird → kein Overlay, der Player-View zeigt in-place.

### 2. Marker schreiben im View, ViewModel emittiert nur das Event

**Trade-off:** ViewModel koennte direkt in `@SceneStorage` schreiben — geht nicht, `@SceneStorage` ist View-gebunden. Alternativen: View beobachtet `viewModel.playbackState` direkt via `.onChange` und schreibt SceneStorage; oder ViewModel emittiert ein `completionEvent`, View beobachtet das.

**Entscheidung:** ViewModel emittiert ein `@Published var completionEvent: CompletionEvent?` (Wert-Objekt mit `meditationId` und Zeitstempel via `clock.now()`). Damit:
- ViewModel-Tests pruefen das Event direkt (testbar ohne SwiftUI).
- View hat einen `.onChange(of: viewModel.completionEvent)`-Handler, der die zwei `@SceneStorage`-Werte schreibt — minimaler View-Code, ein Test reicht.

Der `clock`-Parameter ist bereits Dependency des ViewModels (siehe `setupBindings`).

`completionEvent` wird in `loadAudio()` auf `nil` zurueckgesetzt (Beginn einer neuen Session). Das ist der einzige Ort im ViewModel — kein Reset in `cleanup()` oder `stop()`-Pfaden, die einen Abbruch signalisieren.

### 3. Marker NICHT im AudioPlayerService schreiben

**Trade-off:** AudioPlayerService weiss am eindeutigsten Bescheid (`handlePlaybackFinished`), aber er ist Infrastructure und kennt nur die aktuelle `meditation`. Persistenz/Restoration ist eine Application-Concern.

**Entscheidung:** Service bleibt unveraendert. Das ViewModel beobachtet `state == .finished` ueber das vorhandene Subject. Tests koennen `mockPlayerService.state.send(.finished)` triggern.

### 4. Marker-Clear bei neuer Meditation: `onAppear` des Player-Views

**Trade-off:** Clear in `loadAudio()` waere semantisch sauber, aber das ist ViewModel-Code und kann nicht direkt SceneStorage schreiben. Clear in `.onAppear` der `GuidedMeditationPlayerView` ist View-Code mit Zugriff auf `@SceneStorage`.

**Entscheidung:** `GuidedMeditationPlayerView.onAppear` setzt beide SceneStorage-Werte auf "leer". Der Player-View erscheint genau dann neu, wenn der User in der Bibliothek auf eine Meditation tippt — also ist das der korrekte Zeitpunkt fuer "neue Session beginnt".

Edge Case: Wenn der Player-View NICHT neu erscheint (warmer Resume waehrend gleicher Session), ist der Snapshot ohnehin schon aus dem vorherigen Cold Launch ermittelt — kein Konflikt.

### 5. Kein TTL

**Entscheidung:** `@SceneStorage` hat einen eigenen Lifecycle (iOS löscht es bei Memory-Druck, Scene-Discard, Force Quit). Ein explizites TTL wäre redundant — das OS regelt den Lifecycle. Kein `CompletionMarker`-Typ, kein Expiry-Check. `RootContainerView` zeigt den Overlay wenn `completedAtRaw > 0`.

### 6. Marker-Inhalt: Boolean via Timestamp-Trick + optional ID

**Entscheidung:** `completedAtRaw: Double` dient als Boolean (`> 0` = Marker gesetzt). `meditationId: String` bleibt fuer Debug-Zwecke. Der Timestamp-Wert selbst wird nicht mehr fuer Expiry ausgewertet.

## Refactorings

- `setupBindings()` ersetzt `playerService.state.assign(to: &self.$playbackState)` durch eine `.sink`-Variante, die zusaetzlich `completionEvent` setzt, wenn der State `.finished` erreicht. Mit Guard `completionEvent == nil`, damit doppelte `.finished`-Emissions nicht das Event neu setzen. Risiko: niedrig.
- `WindowGroup`-Body in `StillMomentApp` wird in `RootContainerView { … }` eingewickelt. Bestehende Modifikatoren (`.onOpenURL`, `.onChange(scenePhase)`, Sheets, Alerts) werden nach `RootContainerView` verschoben — keine semantische Aenderung, aber expliziter Migrationsschritt.

## Fachliche Szenarien

### AK-1: Danke-Screen erscheint nach App-Termination

- Gegeben: Eine gefuehrte Meditation laeuft natuerlich bis zum Ende. Anschliessend terminiert iOS die App.
  Wenn: Der User die App neu oeffnet.
  Dann: Der Top-Level-Danke-Screen ueberlagert die App und zeigt Herz-Icon, "Vielen Dank", "Zurueck"-Button.

- Gegeben: Eine gefuehrte Meditation ist natuerlich beendet, App ist suspendiert (nicht terminiert).
  Wenn: Der User die App in den Vordergrund holt und der Player-View ist noch im Stack mit `isCompleted == true`.
  Dann: Der Player-View zeigt den in-place Danke-Screen. Kein zweiter Top-Level-Overlay erscheint.

### AK-2: "Zurueck"-Button schliesst Overlay endgueltig

- Gegeben: Der Top-Level-Danke-Screen ist sichtbar.
  Wenn: Der User auf "Zurueck" tippt.
  Dann: Das Overlay verschwindet, der Marker wird geloescht, und der User sieht den Tab, den er vor der Meditation aktiv hatte.

- Gegeben: Der User hat den Top-Level-Danke-Screen mit "Zurueck" geschlossen.
  Wenn: Der User die App schliesst und neu oeffnet.
  Dann: Kein Danke-Screen erscheint.

### AK-3: Neue Meditation loescht alten Marker

- Gegeben: Der Marker ist gesetzt (z.B. weil eine Meditation eben endete und der App-Start noch aussteht).
  Wenn: Der User in derselben App-Session in der Bibliothek eine neue Meditation startet (`loadAudio()`).
  Dann: Der Marker wird geloescht. Selbst wenn die neue Meditation nicht zu Ende gespielt wird, taucht der alte Danke-Screen nicht mehr auf.

### AK-4: Marker laeuft nach 8 Stunden ab

- Gegeben: Eine Meditation endete vor 9 Stunden, die App wurde seitdem nicht geoeffnet.
  Wenn: Der User die App jetzt oeffnet.
  Dann: Kein Danke-Screen. Der abgelaufene Marker wird beim Lesen geloescht.

- Gegeben: Eine Meditation endete vor 7 Stunden 50 Minuten.
  Wenn: Der User die App oeffnet.
  Dann: Der Danke-Screen erscheint.

### AK-5: Aktiver Abbruch hinterlaesst keinen Marker

- Gegeben: Eine gefuehrte Meditation laeuft.
  Wenn: Der User auf den Schliessen-Button tippt (Player-View dismissed).
  Dann: Kein Marker wird geschrieben (Audio-State erreicht nie `.finished`).

- Gegeben: Eine gefuehrte Meditation laeuft, eine andere App startet eigenes Audio (Audio-Session-Konflikt).
  Wenn: `stopForAudioSessionConflict` greift.
  Dann: Kein Marker wird geschrieben (Audio-State pausiert, kein `.finished`).

- Gegeben: Eine gefuehrte Meditation laeuft, der User oeffnet eine MP3 via "Open with" (`fileOpenHandler.shouldStopMeditation`).
  Wenn: Der Stop-Pfad greift.
  Dann: Kein Marker wird geschrieben.

### AK-6: Doppelte Anzeige im Player-Stack-aktiv-Fall

- Gegeben: Player-View ist im Vordergrund. Audio endet natuerlich → in-place Danke-Screen sichtbar, gleichzeitig wird `@SceneStorage` befuellt.
  Wenn: Die `RootContainerView` re-rendert (z.B. Theme-Wechsel).
  Dann: Es ist nur EIN Danke-Screen sichtbar (der in-place). Das Top-Level-Overlay erscheint nicht, weil `initialMarker` schon zu Scene-Start als `.absent` festgelegt wurde und sich nicht mehr durch nachgelagerte SceneStorage-Aenderungen veraendert.

- Gegeben: Cold Launch nach OS-Termination. SceneStorage enthaelt einen gueltigen Marker. NavigationPath ist leer (nicht restored).
  Wenn: Die `RootContainerView` zum ersten Mal `onAppear` triggert.
  Dann: `initialMarker = .present`, Overlay erscheint. Der Player-View ist nicht aktiv → keine Doppel-Anzeige moeglich.

### AK-7: Top-Level-Overlay kommt nicht beim normalen Resume

- Gegeben: Der User legt das Phone fuer 5 Minuten weg, ohne dass eine Meditation laeuft, und die App wechselt in den Hintergrund.
  Wenn: Der User die App wieder aktiv macht.
  Dann: Kein Danke-Screen erscheint (kein Marker gesetzt).

## Reihenfolge der Akzeptanzkriterien

Optimal fuer TDD (Domain → Application → Presentation):

1. **CompletionMarker (Domain)** — Pure Funktion `isExpired(completedAt:now:ttl:)` + Default-TTL. Reine Pure-Swift-Tests. Grundlage fuer alle anderen Schritte.
2. **AK-5 + AK-3 (ViewModel)** — `completionEvent` wird bei `.finished` einmal gesetzt, NICHT bei manuellem Stop / Audio-Konflikt / Cleanup. Wird beim Laden einer neuen Meditation (`loadAudio()` mit anderer ID) zurueckgesetzt. Sicherheits-Netz vor der UI-Arbeit.
3. **RootContainerView mit Snapshot-Pattern (Presentation)** — `@SceneStorage` + `@State initialMarker` + `onAppear`-Snapshot. AK-1, AK-7.
4. **AK-2 (Presentation)** — "Zurueck"-Button: SceneStorage clearen + `initialMarker = .absent`.
5. **AK-4 (Presentation)** — Expiry-Check in `onAppear` durch `CompletionMarker.isExpired`.
6. **AK-6 (Architektur + Test)** — Doppelte Anzeige verhindert. Pruefbar durch ViewModel-Test (`completionEvent` wird gefeuert) plus expliziten View-Test, dass `RootContainerView` nach Aktivierung nicht auf SceneStorage-Aenderungen reagiert (idealerweise via `ViewInspector` oder im UI-Test mit Launch-Args, die SceneStorage simulieren).
7. **GuidedMeditationPlayerView**: `.onChange(of: viewModel.completionEvent)` schreibt SceneStorage. `.onAppear` clear-t alte Marker.

## Vorbereitung

Nichts. Keine neuen Targets, Provisioning Profiles oder externen Accounts.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `completionEvent` wird unter Race-Condition mehrfach gesetzt (z.B. mehrfaches `state.send(.finished)`). | Sink prueft `completionEvent == nil` bevor er setzt. Wird beim Laden einer neuen Meditation auf `nil` zurueckgesetzt. |
| `Date()`-Verwendung im ViewModel macht Tests nicht-deterministisch. | `ClockProtocol` ist bereits Dependency des ViewModels. `clock.now()` nutzen. |
| Snapshot-Pattern bricht, wenn `RootContainerView` mehrfach `onAppear` triggert (z.B. bei Sheet-Dismiss). | Guard mit `initialMarker == nil` — nur erster `onAppear` pro Container-Lifecycle wertet aus. Spaetere `onAppear` sind No-Op. |
| `@SceneStorage` Force-Quit-Verhalten ueberrascht User: "Ich hab die App geschlossen und der Screen kommt nicht" — aber das ist gewuenscht. | Im manuellen Testplan dokumentieren. Falls UX-Wunsch anders ist, koennen wir nachtraeglich auf UserDefaults wechseln. |
| iOS koennte `@SceneStorage` bei sehr langer Inaktivitaet (Tage) verwerfen, der 8h-TTL liefe also ggf. ins Leere. | Genau das ist der Sinn der "best-effort"-Garantie und voellig akzeptabel — nach Tagen ist der Danke-Screen ohnehin nicht mehr relevant. |
| Top-Level-Overlay verdeckt System-UI (Status Bar, Home Indicator) inkonsistent zu in-place. | `MeditationCompletionView` wird im Overlay mit denselben Background-/Padding-Settings wie der Player gerendert. `.statusBarHidden`-Konsistenz manuell pruefen. |

## Entschiedene Designfragen

- **TTL 8h**: bestaetigt.
- **Overlay-Hintergrund**: `MeditationCompletionView` wird 1:1 eingebettet — kein neues Styling, keine UI-Anpassung.
- **`cleanup()`/`onDisappear` loescht den Marker nicht**: bestaetigt. Marker wird nur bei explizitem Dismiss-Tap, neuer Meditation-Session (`loadAudio()`) oder TTL-Ablauf entfernt.

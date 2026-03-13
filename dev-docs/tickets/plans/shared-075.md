# Implementierungsplan: shared-075 (iOS)

Ticket: [shared-075](../shared/shared-075-library-long-press-preview.md)
Erstellt: 2026-03-13

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Services/AudioServiceProtocol.swift` | Domain | Erweitern | `playMeditationPreview(fileURL:)` + `stopMeditationPreview()` hinzufuegen |
| `Infrastructure/Services/AudioService.swift` | Infrastructure | Erweitern | Neue Preview-Methoden implementieren (analog `playIntroductionPreview`) |
| `Application/ViewModels/GuidedMeditationsListViewModel.swift` | Application | Erweitern | AudioService-Dependency + Preview-Methoden + Published State |
| `Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Presentation | Erweitern | Long-Press-Gesture auf Play-Icon, Scale-Animation |
| `StillMomentTests/Mocks/MockTimerService.swift` (MockAudioService) | Test | Erweitern | Neue Mock-Methoden fuer Meditation-Preview |
| `StillMomentTests/GuidedMeditationsListViewModelTests.swift` | Test | Erweitern | Preview-Tests |

## Design-Entscheidungen

### 1. fileURL statt filePath als Parameter

**Trade-off:** Das Ticket schlaegt `playMeditationPreview(filePath:)` vor, aber `GuidedMeditationServiceProtocol` hat bereits `fileURL(for:) -> URL?` — die URL-Aufloesung (relative Pfade → absolute URLs) ist dort gekapselt.

**Entscheidung:** `playMeditationPreview(fileURL: URL)` — die View/ViewModel ruft `meditationService.fileURL(for:)` auf und uebergibt die fertige URL. Das vermeidet duplizierte Pfad-Aufloesung im AudioService.

### 2. Gesture: DragGesture(minimumDistance: 0) auf dem Play-Icon

**Trade-off:** `.onLongPressGesture(minimumDuration:pressing:)` hat einen Delay bevor `pressing` true wird. `DragGesture(minimumDistance: 0)` reagiert sofort auf Touch-Down/Touch-Up. Da wir "solange Finger gedrueckt" wollen (nicht "nach X Sekunden"), ist DragGesture passender.

**Entscheidung:** `DragGesture(minimumDistance: 0)` auf dem Play-Icon. `onChanged` = Start Preview + Haptic + Scale. `onEnded` = Stop Preview + Reset Scale. Der umgebende NavigationLink (opacity 0) faengt Taps auf der restlichen Row ab.

**Risiko:** DragGesture auf einem kleinen Icon (20pt) koennte fummelig sein. Mitigation: `.frame(minWidth: 44, minHeight: 44)` als Hit-Area (Apple HIG Minimum). Zusaetzlich: DragGesture innerhalb einer List kollidiert mit dem Scroll-Gesture — wenn der Finger leicht verrutscht, scrollt die Liste statt die Preview weiterzulaufen. Mitigation: `.simultaneousGesture()` statt `.gesture()` und/oder Toleranzbereich fuer Translation pruefen.

### 3. Fade-out im AudioService (nicht im ViewModel)

**Entscheidung:** `stopMeditationPreview()` macht intern den 0.3s Fade-out (analog `fadeOutBackgroundPreview()`). Der ViewModel ruft nur `stop` auf — kein Timer-Management in der Presentation/Application Layer. Wichtig: `releaseAudioSession(for: .preview)` erst **nach** dem Fade-out aufrufen (analog Background-Preview-Pattern, nicht Introduction-Preview-Pattern das sofort released).

### 5. Mutual Exclusion mit anderen Previews

**Entscheidung:** `playMeditationPreview` muss beim Start alle anderen Previews stoppen (Gong, Background, Introduction) — analog zum bestehenden Pattern in `playIntroductionPreview`. Umgekehrt muessen die bestehenden Preview-Methoden den neuen `meditationPreviewPlayer` ebenfalls stoppen. Sonst koennen zwei Previews gleichzeitig laufen.

### 6. Kein Icon-Wechsel waehrend Preview

**Entscheidung:** Das Play-Icon bleibt unveraendert waehrend die Preview laeuft. Der Scale-Effekt (AK-6) ist ausreichend visuelles Feedback. Ein wechselndes Icon (z.B. Lautsprecher) wuerde suggerieren, dass es ein Toggle ist — die Press-and-Hold-Geste ist selbsterklaerend.

### 7. fileURL-Aufloesung im ViewModel (keine neue Dependency)

**Entscheidung:** Der ViewModel hat bereits `meditationService` (GuidedMeditationServiceProtocol) als Dependency. `fileURL(for:)` wird dort aufgerufen — keine neue Dependency noetig, nur die AudioService-Dependency kommt hinzu.

### 4. Preview stoppt bei Navigation zum Player

**Entscheidung:** Kein expliziter Code noetig. Wenn der Player `requestAudioSession(for: .guidedMeditation)` aufruft, loest der AudioSessionCoordinator den Conflict-Handler aus, der alle Preview-Player stoppt. Das bestehende Pattern deckt das ab.

## Fachliche Szenarien

### AK-1: Long-Press auf Play-Icon startet Preview

- Gegeben: Bibliothek mit mindestens einer Meditation
  Wenn: User drueckt lang auf das Play-Icon
  Dann: Meditation startet ab Anfang als Audio-Preview

### AK-2: Loslassen stoppt Preview mit Fade-out

- Gegeben: Preview laeuft
  Wenn: User laesst Finger los
  Dann: Audio stoppt mit ~0.3s Fade-out

### AK-3: Tap auf Row navigiert zum Player

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User tippt auf den Namen oder die Dauer (nicht das Play-Icon)
  Dann: Navigation zum Full Player wie bisher

### AK-4: Nur eine Preview gleichzeitig

- Gegeben: Preview fuer Meditation A laeuft
  Wenn: User drueckt lang auf Play-Icon von Meditation B
  Dann: Preview A stoppt, Preview B startet

- Gegeben: Gong-Preview oder Background-Preview laeuft (z.B. aus Settings)
  Wenn: User drueckt lang auf Play-Icon einer Meditation
  Dann: Vorherige Preview stoppt, Meditation-Preview startet

### AK-5: Haptisches Feedback beim Start

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User drueckt lang auf das Play-Icon
  Dann: Haptisches Feedback (impact, medium) beim Start

### AK-6: Scale-Effekt auf Icon waehrend Druecken

- Gegeben: User drueckt auf Play-Icon
  Wenn: Finger ist gedrueckt
  Dann: Icon skaliert leicht hoch (z.B. 1.3x) mit Animation
  Wenn: Finger losgelassen
  Dann: Icon skaliert zurueck auf 1.0x

### AK-7: Preview nutzt .preview Audio-Session-Source

- Gegeben: Preview wird gestartet
  Wenn: AudioService spielt Meditation-Preview
  Dann: Audio-Session wird mit Source `.preview` angefordert (nicht `.guidedMeditation`)

### AK-8: Navigation zum Player stoppt Preview

- Gegeben: Preview laeuft
  Wenn: User navigiert zum Full Player (Tap auf Row)
  Dann: Preview stoppt automatisch (via AudioSessionCoordinator Conflict-Handler)

## Reihenfolge der Akzeptanzkriterien

1. **AK-7: AudioServiceProtocol + AudioService** — Neue Methoden `playMeditationPreview`/`stopMeditationPreview` + Mock erweitern. Grundlage fuer alles.
2. **AK-1 + AK-2 + AK-4: ViewModel Preview-Logik** — `GuidedMeditationsListViewModel` um AudioService-Dependency und Preview-Methoden erweitern.
3. **AK-5 + AK-6 + AK-3: View Gesture + Animation** — DragGesture auf Play-Icon, Scale-Animation, Haptic Feedback.
4. **AK-8: Navigation stoppt Preview** — Verifizieren dass der bestehende Conflict-Handler das abdeckt (ggf. Test).

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| DragGesture auf kleinem Icon konkurriert mit NavigationLink | Hit-Area auf 44x44 vergroessern, NavigationLink bleibt auf gesamter Row |
| DragGesture in List kollidiert mit Scroll-Gesture | `.simultaneousGesture()` und/oder Translation-Toleranz pruefen |
| cleanupPreviewPlayers() stoppt nicht den neuen meditationPreviewPlayer | meditationPreviewPlayer in cleanupPreviewPlayers() ergaenzen |
| Bestehende Preview-Methoden stoppen meditationPreviewPlayer nicht | Mutual-Stop in playGongPreview, playBackgroundPreview, playIntroductionPreview ergaenzen |
| ViewModel braucht jetzt AudioService UND MeditationService | Convenience init mit Defaults — bestehendes Pattern bei TimerViewModel |

# Implementierungsplan: shared-075 (iOS Rework)

Ticket: [shared-075](../shared/shared-075-library-long-press-preview.md)
Erstellt: 2026-03-13
Aktualisiert: 2026-03-14 (UI-Konzept-Aenderung)

## Hintergrund: Warum Rework

Die urspruengliche Implementierung nutzte `DragGesture(minimumDistance: 0)` auf der gesamten Row um "solange Finger drauf = Preview" umzusetzen. Problem: `DragGesture.onEnded` feuert nicht zuverlaessig in einer `List` (Scroll-Konflikt), was zu unkontrolliert weiterlaufenden Previews fuehrte. SwiftUI bietet keine robuste "press-and-hold-then-release"-Geste.

Neues Konzept: Play-Button mit zwei Interaktionen (Tap = Start Meditation, Long-Press = Preview). Preview laeuft bis expliziter Stop-Tap. Kein Gesture-Tracking waehrend der Wiedergabe noetig.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Services/AudioServiceProtocol.swift` | Domain | Keine Aenderung | `playMeditationPreview` / `stopMeditationPreview` bereits vorhanden |
| `Infrastructure/Services/AudioService+MeditationPreview.swift` | Infrastructure | Keine Aenderung | Implementierung bereits vorhanden und stabil |
| `Application/ViewModels/GuidedMeditationsListViewModel.swift` | Application | Anpassen | `startPreview`/`stopPreview` bleiben, ggf. Toggle-Methode ergaenzen |
| `Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Presentation | Umbauen | DragGesture entfernen, Play-Button mit Tap/Long-Press + Icon-Wechsel, Row-Tap entfernen |
| `StillMomentTests/GuidedMeditationsListViewModelTests.swift` | Test | Anpassen | Tests an neues Verhalten anpassen |

## Design-Entscheidungen

### 1. fileURL statt filePath als Parameter (unveraendert)

**Entscheidung:** `playMeditationPreview(fileURL: URL)` — ViewModel ruft `meditationService.fileURL(for:)` auf. Bereits implementiert.

### 2. Play-Button: Tap + Long-Press (NEU — ersetzt DragGesture)

**Problem:** `DragGesture(minimumDistance: 0)` in einer List ist instabil — `.onEnded` feuert nicht zuverlaessig bei Scroll-Konflikten. Das fuehrte zu Previews die unkontrolliert weiterliefen.

**Entscheidung:** Play-Button als normaler SwiftUI `Button` mit `.onLongPressGesture(minimumDuration: 0.5, perform:)` fuer Preview-Start. Tap auf den Button wird ueber den Button-Action-Handler abgefangen.

**Zustandsmaschine des Play-Buttons:**

| Zustand | Icon | Tap | Long-Press |
|---------|------|-----|------------|
| Idle | ▶ (play.circle.fill) | Meditation starten | Preview starten |
| Preview aktiv (diese Meditation) | ■ (stop.circle.fill) | Preview stoppen | — |
| Preview aktiv (andere Meditation) | ▶ (play.circle.fill) | Meditation starten | Preview wechseln |

**Technisch:** `.onLongPressGesture` wird VOR dem Button-Tap ausgewertet (Gesture-Prioritaet). Wenn Long-Press erkannt → Preview. Wenn Finger vorher losgelassen → Button-Tap → Navigation oder Stop.

### 3. Row-Text ist nicht mehr tappbar (NEU)

**Problem:** Bisher navigierte Tap auf die Row zum Player. Mit dem neuen Konzept ist nur der Play-Button interaktiv (plus Overflow-Menu).

**Entscheidung:** NavigationLink / Tap-Handler von der Row entfernen. Der Play-Button uebernimmt die Navigation (Tap im Idle-Zustand). Das vermeidet Gesture-Konflikte und macht die Interaktionsbereiche eindeutig.

### 4. Fade-out im AudioService (unveraendert)

**Entscheidung:** `stopMeditationPreview()` macht intern den 0.3s Fade-out. Bereits implementiert und stabil (Race Condition in Commit 42212c2 gefixt).

### 5. Mutual Exclusion mit anderen Previews (unveraendert)

**Entscheidung:** `playMeditationPreview` stoppt beim Start alle anderen Previews. Bereits implementiert.

### 6. Icon-Wechsel statt Scale-Effekt (NEU — ersetzt "kein Icon-Wechsel")

**Problem:** Der Scale-Effekt war an die DragGesture gebunden ("solange Finger drauf"). Mit dem neuen Konzept brauchen wir dauerhaftes visuelles Feedback waehrend die Preview laeuft.

**Entscheidung:** Icon wechselt von ▶ (play.circle.fill) zu ■ (stop.circle.fill) waehrend Preview aktiv ist. Das ist universell verstaendlich und zeigt klar "hier laeuft etwas, Tap zum Stoppen".

### 7. Kein DispatchWorkItem / kein Timing-State (NEU)

**Entscheidung:** Alle `@State`-Properties fuer Gesture-Tracking entfallen (`isPressing`, `longPressActive`, `longPressWork`). Der Preview-Zustand wird ausschliesslich ueber `viewModel.previewingMeditationId` getrackt — eine einzige Source of Truth.

### 8. Preview stoppt bei Meditation-Start (unveraendert)

**Entscheidung:** Kein expliziter Code noetig. Wenn der Player `requestAudioSession(for: .guidedMeditation)` aufruft, loest der AudioSessionCoordinator den Conflict-Handler aus, der alle Preview-Player stoppt.

## Fachliche Szenarien

### AK-1: Tap auf Play-Button startet Meditation

- Gegeben: Bibliothek mit einer Meditation, keine Preview aktiv
  Wenn: User tippt kurz auf den Play-Button
  Dann: Navigation zum Full Player, Meditation startet

### AK-2: Long-Press auf Play-Button startet Preview

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User drueckt lang auf den Play-Button (~0.5s)
  Dann: Haptisches Feedback, Icon wechselt zu ■, Audio startet ab Anfang als Preview

### AK-3: Tap auf Stop-Button stoppt Preview

- Gegeben: Preview laeuft fuer diese Meditation
  Wenn: User tippt auf den Stop-Button (■)
  Dann: Audio stoppt mit ~0.3s Fade-out, Icon wechselt zurueck zu ▶

### AK-4: Nur eine Preview gleichzeitig

- Gegeben: Preview fuer Meditation A laeuft
  Wenn: User drueckt lang auf Play-Button von Meditation B
  Dann: Preview A stoppt, Preview B startet, Icon A → ▶, Icon B → ■

### AK-5: Haptisches Feedback beim Start

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User drueckt lang auf den Play-Button
  Dann: Haptisches Feedback (impact, medium) beim Preview-Start

### AK-6: Row-Text ist nicht tappbar

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User tippt auf den Meditations-Titel oder die Dauer
  Dann: Nichts passiert (kein Tap-Handler, nur Scroll)

### AK-7: Preview nutzt .preview Audio-Session-Source

- Gegeben: Preview wird gestartet
  Wenn: AudioService spielt Meditation-Preview
  Dann: Audio-Session wird mit Source `.preview` angefordert (nicht `.guidedMeditation`)

### AK-8: Meditation starten stoppt Preview

- Gegeben: Preview laeuft
  Wenn: User startet eine Meditation (Tap auf Play-Button einer beliebigen Meditation)
  Dann: Preview stoppt automatisch (via AudioSessionCoordinator Conflict-Handler)

## Reihenfolge der Implementierung

1. **View umbauen:** DragGesture + State-Properties entfernen, Play-Button mit Tap/Long-Press + Icon-Wechsel
2. **Row-Navigation entfernen:** Tap auf Row-Text deaktivieren, Navigation nur noch ueber Play-Button
3. **Tests anpassen:** Bestehende Tests an neues Verhalten anpassen
4. **AudioService/ViewModel:** Keine Aenderungen noetig — bereits stabil

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `.onLongPressGesture` und Button-Tap kollidieren | Gesture-Prioritaet testen: Long-Press sollte vor Tap ausgewertet werden |
| User entdeckt Long-Press nicht | Play-Icon ist sichtbar und einladend; ggf. Tooltip beim ersten Mal |
| Row ohne Tap fuehlt sich "tot" an | Overflow-Menu und Play-Button sind weiterhin interaktiv; Scroll funktioniert |

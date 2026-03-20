# Ticket ios-040: AudioService als einzelne geteilte Instanz

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-040.md)
**Prioritaet**: HOCH
**Aufwand**: M
**Abhaengigkeiten**: -
**Phase**: 2-Architektur

---

## Was

Die App soll genau eine AudioService-Instanz verwenden, die von allen ViewModels geteilt wird — statt dass jedes ViewModel seine eigene Instanz erstellt.

## Warum

Mehrere unabhängige AudioService-Instanzen greifen auf dieselbe systemweite Audio-Session zu. Das führt zu zwei konkreten Bugs:

**Bug 1 — Session-Release durch falsche Instanz:** Wenn eine Instanz freigegeben wird, kann sie die Session deaktivieren, die eine andere Instanz gerade aktiv nutzt. Fix in shared-076 war ein Guard (`timerSessionActive`), nicht die strukturelle Ursache.

**Bug 2 — Conflict-Handler-Überschreibung (latent):** `AudioSessionCoordinator` speichert pro Source genau einen Conflict-Handler (`conflictHandlers[source] = handler`). Jede neue `AudioService`-Instanz überschreibt in ihrem `init()` den Handler der vorigen. Mit zwei Instanzen, die beide `registerConflictHandler(for: .timer)` aufrufen, gewinnt die zuletzt erstellte — bei Source-Konflikt (z.B. Preview übernimmt Timer) feuert `cleanupTimerPlayers()` auf der falschen Instanz, der echte Timer wird nicht aufgeräumt.

Bug-Precedent: shared-075 führte eine zweite AudioService-Instanz im GuidedMeditationsListViewModel ein. Bug 1 trat beim App-Hintergrunden auf. Bug 2 ist bisher nicht reproduziert, aber strukturell vorhanden.

**Android ist nicht betroffen** — Hilt DI mit `@Singleton` stellt dort strukturell sicher, dass nur eine Instanz existiert.

---

## Akzeptanzkriterien

### Verhalten
- [x] Timer-Audio läuft durch wenn der Benutzer in der App navigiert (Tabs wechselt)
- [x] Timer-Audio läuft durch wenn die App in den Hintergrund geht (Lock Screen)
- [x] Guided Meditation Preview funktioniert weiterhin in der Bibliothek
- [x] Preview-Audio und Timer-Audio schließen sich gegenseitig aus (nur eines gleichzeitig)
- [x] Settings-Preview (Gong, Hintergrund) funktioniert weiterhin

### Tests
- [x] `TimerViewModelTests`: AudioService-Mock wird korrekt per Constructor-Injection gesetzt (Regression — bestehende Tests müssen weiter bestehen)
- [x] `GuidedMeditationsListViewModelTests`: AudioService-Mock wird korrekt injiziert (Regression)
- [x] `PraxisEditorViewModelTests`: AudioService-Mock wird korrekt injiziert (Regression)

### Dokumentation
- [x] CHANGELOG.md (interne Refactoring-Notiz)

---

## Manueller Test

1. Timer starten
2. Zur Bibliothek navigieren — Vorschau eines Tracks antippen
3. Erwartung: Preview übernimmt, Timer-Gong am Ende spielt danach wieder korrekt
4. Timer starten, Bildschirm sperren — warten bis Gong fällig
5. Erwartung: Gong spielt auf dem Lock Screen

---

## Hinweise

**Technischer Kontext:**

Aktuell erstellen drei ViewModels je eine eigene `AudioService`-Instanz über den Default-Parameter:
- `TimerViewModel` — Timer-Session, Keep-Alive, Gongs
- `GuidedMeditationsListViewModel` — Meditation-Preview (Long-Press)
- `PraxisEditorViewModel` — Settings-Preview (Gong, Hintergrund, Attunement)

Alle drei teilen `AudioSessionCoordinator.shared`, der die eine `AVAudioSession` des Systems verwaltet.

**Ziel:** Eine Instanz in `StillMomentApp` erstellen, per Constructor-Injection an alle ViewModels weitergeben. `AudioSessionCoordinator` selbst ist ein gut gebauter Singleton und braucht keine Änderungen.

**Konkrete Änderungen:**

1. **`StillMomentApp`**: Shared Instanz als `@StateObject` (oder `let`) halten und an ViewModels weitergeben. Gleichzeitig `createTimerViewModel()` in einen `@StateObject private var timerViewModel` umwandeln — die Methode wird bei jedem `body`-Rebuild aufgerufen und erzeugt heute bei jedem Re-Render ein neues ViewModel.

2. **`TimerViewModel`**: Erhält `AudioService` per Constructor-Injection (Default-Parameter bleibt für Tests). `TimerView` erstellt `PraxisEditorViewModel` on-demand mit `viewModel.audioService` (Zeile 131/262 in `TimerView.swift`). Achtung: `audioService` muss dafür auf `internal` sichtbar sein.

3. **`GuidedMeditationsListView`**: Unterstützt bereits einen optionalen `viewModel`-Parameter (Zeile 24). `StillMomentApp` übergibt ein vorbereitetes `GuidedMeditationsListViewModel(audioService: sharedAudioService)`. Den toten `meditationService`-Parameter im `init()` bereinigen (er wird ignoriert wenn `viewModel` gesetzt ist).

4. **`PraxisEditorViewModel`**: Erhält `AudioService` per Constructor-Injection. `TimerView` erstellt es on-demand mit `viewModel.audioService` statt `AudioService()`.

5. **`convenience init()`** in `AudioService`: Bleibt unverändert — wird von Tests genutzt. Kein Produktionscode darf sie aufrufen.

---

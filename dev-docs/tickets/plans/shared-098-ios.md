# Implementierungsplan: shared-098 (iOS)

Ticket: [shared-098](../shared/shared-098-library-preview-scrub-slider.md)
Erstellt: 2026-05-17

---

## Annahmen

Bewusst getroffene Annahmen, die in den Plan einfliessen:

- **Update-Frequenz 10 Hz** (alle 100 ms). Bei 1-stuendigen Meditationen ist Sekunden-Aufloesung mehr als ausreichend. Hoeher rentiert sich nicht und kostet CPU.
- **Slider liegt unterhalb der bestehenden Row** im selben `List`-Eintrag, getrennt durch einen feinen `Divider`. Die Row waechst beim Vorhoeren in der Hoehe. Alternativ-Lokationen (separater List-Eintrag, BottomSheet) sind komplizierter und brechen die visuelle Kopplung zur Meditation.
- **Slider ist standard `SwiftUI Slider`**, kein Custom-Control. VoiceOver-Adjustable kommt damit out-of-the-box (Default-Schritte ~5 %, was bei 12-Min-Meditation ca. 36 s sind — vertretbar).
- **Stop bei Audio-Ende** via `AVAudioPlayerDelegate.audioPlayerDidFinishPlaying` — fuegt sich logisch in den bestehenden Stop-Flow ein (Fade-Out + Session-Release).
- **Lokaler `@State` waehrend Drag**, sync via Publisher beim Loslassen. Standard-SwiftUI-Pattern via `Slider(onEditingChanged:)`.
- **Zeit-Format mm:ss** ohne Stunden — Meditationen sind praktisch nie > 1 h und das ist im Player schon so. Glossar-Konsistenz.
- **Slider-Komponente neu** als `MeditationPreviewProgressRow` in Presentation/Shared — beide Listen (Library + Suchergebnisse) nutzen sie identisch.
- **Keine neue Domain-Logik** — Vorhoeren ist Infrastructure-Lifecycle, kein Domain-Konzept.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Services/AudioServiceProtocol.swift` | Domain | Erweitern | Drei neue Schnittstellen: `meditationPreviewPosition` (Publisher), `meditationPreviewDuration` (Publisher), `seekMeditationPreview(to:)`. |
| `Infrastructure/Services/AudioService.swift` | Infrastructure | Erweitern | Zwei `CurrentValueSubject<TimeInterval, Never>` als Backing fuer Position + Duration. Property fuer Update-Timer + Delegate. |
| `Infrastructure/Services/AudioService+MeditationPreview.swift` | Infrastructure | Erweitern | Start-Funktion: Duration setzen, Update-Timer starten, Delegate registrieren. Stop-Funktion: Timer invalidaten, Subjects auf 0 setzen. Neue `seekMeditationPreview(to:)` implementieren. Neuer Delegate-Hook fuer `didFinishPlaying`. |
| `Application/ViewModels/GuidedMeditationsListViewModel.swift` | Application | Erweitern | Neue `@Published var previewCurrentTime: TimeInterval = 0` und `previewDuration: TimeInterval = 0`, an die Service-Publisher gebunden. Neue Methode `seekPreview(to: TimeInterval)`. |
| `Presentation/Views/GuidedMeditations/MeditationPreviewProgressRow.swift` | Presentation | **Neu** | Slider + Zeit-Labels-Komponente. Eingaben: aktuelle Zeit (Binding `Double`), Gesamtdauer, `onSeek: (TimeInterval) -> Void`. |
| `Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Presentation | Erweitern | `meditationRow(for:)` umstellen von `HStack` auf `VStack`: oben unveraenderte HStack, darunter optional die Progress-Row mit `.transition`-Animation. |
| `Presentation/Views/GuidedMeditations/SearchResultsListView.swift` | Presentation | Erweitern | `row(for:)` analog. Plus zwei neue Eingaben (`previewCurrentTime`, `previewDuration`, `onSeekPreview`) im Init und in `LibrarySearchContentView`. |
| `Presentation/Views/GuidedMeditations/LibrarySearchContentView.swift` | Presentation | Erweitern | Reicht die neuen Werte/Closures durch zu `SearchResultsListView`. |
| `StillMomentTests/Mocks/MockTimerService.swift` | Tests | Erweitern | `MockAudioService` bekommt `meditationPreviewPositionSubject`, `meditationPreviewDurationSubject`, `seekMeditationPreviewCalled`, `lastSeekMeditationPreviewTime`. |
| `StillMomentTests/GuidedMeditationsListViewModelTests.swift` (oder neue Datei) | Tests | Erweitern | Tests fuer das Durchleiten von currentTime/duration + `seekPreview(to:)`. |
| `StillMomentUITests/LibraryFlowUITests.swift` | UITests | Erweitern | UI-Test: Long-Press → Slider erscheint → Drag → Wert aktualisiert. |
| `Localizable.strings` (de/en) | Resources | Erweitern | Mindestens ein Key fuer Slider-Accessibility-Label (z.B. `accessibility.library.preview.position`). |
| `CHANGELOG.md` | Docs | Erweitern | User-sichtbarer Eintrag. |

---

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AVAudioPlayer.currentTime` (set/get) | iOS 2.2+ | Apple Docs | Direktes Setzen bewirkt sofortiges Seek; AVAudioPlayer haengt nicht. Fuer lokale Files (MP3 hier) ohne erkennbare Latenz. |
| `AVAudioPlayer.duration` | iOS 2.2+ | Apple Docs | Statisch, nach erfolgreichem `prepareToPlay()` korrekt. |
| `AVAudioPlayerDelegate.audioPlayerDidFinishPlaying(_:successfully:)` | iOS 2.2+ | Apple Docs | Wird bei natuerlichem File-Ende aufgerufen. Bei explizitem `stop()` NICHT. Genau das gewuenschte Verhalten. |
| `Timer.scheduledTimer(withTimeInterval:repeats:block:)` | iOS 10+ | Apple Docs | Fuer den 100-ms-Update-Loop. RunLoop.main. Pattern wie `backgroundPreviewTimer` in `AudioService.playBackgroundPreview`. |
| `Combine.CurrentValueSubject` | iOS 13+ | Apple Docs | Bekannt, im Projekt schon im Einsatz (`AudioPlayerService`). |
| `SwiftUI.Slider(value:in:onEditingChanged:)` | iOS 13+ | Apple Docs | Standard. `onEditingChanged: (Bool) -> Void` signalisiert Drag-Begin (true) und -End (false). |

Keine API-Ueberraschungen, keine Deprecation-Risiken, alles weit ueber dem Deployment-Target (iOS 16).

---

## Design-Entscheidungen

### 1. Position-Update im AudioService, nicht im ViewModel

**Trade-off:** Service hat dann eine Timer-Verantwortung; alternativ wuerde der ViewModel selbst pollen.
**Entscheidung:** Service. Der Timer-Lifecycle ist exakt an die Existenz des `meditationPreviewPlayer` gekoppelt — der Service weiss als einziger, wann er starten/stoppen muss. Im ViewModel wuerde der Lifecycle indirekt rekonstruiert (per Subscriber auf Start/Stop). Mehr Indirektion ohne Nutzen.

### 2. Lokaler `@State` im Slider waehrend Drag

**Trade-off:** Live-Scrubbing waere "noch direkter" (Audio springt mit jedem Frame). Aber bei 60-Hz-Drag ≈ 60 `currentTime = X`-Calls pro Sekunde — moegliches Knacken, definitiv unnoetig.
**Entscheidung:** Standard-Pattern via `onEditingChanged`. Slider verfolgt waehrend Drag den Finger via lokalem State; bei `false` (Loslassen) wird einmal seek aufgerufen und der lokale State wieder mit dem Publisher synchronisiert. So bleibt das Apple-Music-Feeling erhalten (Audio springt zur Drag-End-Position, kein Pause, sofortiges Weiterspielen), ohne Live-Konflikte zwischen Update-Loop und Drag.

### 3. `MeditationPreviewProgressRow` als eigene View-Komponente

**Trade-off:** Inline-Code in Library- und Such-Row waere knapper.
**Entscheidung:** Eigene View. Wird in zwei Listen identisch gebraucht; eigenes Test-Target via Preview moeglich; Slider+Labels sind ein semantisch zusammenhaengendes Element.

---

## Refactorings

Keine geplant. Alle Aenderungen sind additiv:

- Protokoll-Erweiterung: ja, aber additive Default-Implementations sind nicht noetig — es gibt genau zwei Conformances (`AudioService`, `MockAudioService`), beide werden im selben Patch aktualisiert.
- Existing Preview-Start/Stop-Flow bleibt rueckwaerts kompatibel; nur die Position-Subjects + Timer + Delegate kommen dazu.

---

## Fachliche Szenarien

### AK-1: Long-Press → Slider erscheint mit Animation

- Gegeben: Library ist offen, keine Preview laeuft.
  Wenn: User macht Long-Press auf den Play-Button einer Meditation.
  Dann: Preview startet, der Play-Button wechselt zu Stop, unter der Zeile blendet (~0.25 s) ein Slider mit zwei Zeit-Labels ein. Slider-Punkt startet links bei 00:00.

### AK-2: Position laeuft mit der Wiedergabe

- Gegeben: Preview spielt seit 5 s an Position 0:05.
  Wenn: 3 weitere Sekunden vergehen.
  Dann: Linkes Zeit-Label zeigt 0:08, Slider-Punkt ist proportional weiter rechts (8/duration). Updates erscheinen fluessig (mindestens alle 100 ms).

### AK-3: Drag springt + Audio spielt sofort weiter

- Gegeben: Preview spielt bei 0:10 in einer 11:30-Meditation.
  Wenn: User zieht den Slider-Punkt auf die Mitte und laesst los.
  Dann: Audio spielt sofort von ~5:45 weiter. Kein Knacken, kein Pause. Zeit-Label rastet bei 5:45 ein, Slider-Punkt steht in der Mitte.

### AK-4: Drag rueckwaerts funktioniert genauso

- Gegeben: Preview spielt bei 5:00.
  Wenn: User zieht den Punkt zurueck auf 1:00.
  Dann: Audio spielt von 1:00 weiter; alles andere wie AK-3.

### AK-5: Stop-Tap beendet Preview und blendet Slider aus

- Gegeben: Preview laeuft bei 2:30, Slider sichtbar.
  Wenn: User tippt den Stop-Button.
  Dann: Audio stoppt mit dem bestehenden Fade-Out, Slider blendet animiert wieder aus (~0.25 s), Play-Button wechselt zurueck zu ▶.

### AK-6: Preview einer anderen Zeile ersetzt die aktuelle

- Gegeben: Preview von Meditation A laeuft, Slider unter A sichtbar.
  Wenn: User macht Long-Press auf Meditation B.
  Dann: Preview von A stoppt, Slider unter A verschwindet. Preview von B startet, Slider unter B erscheint mit 00:00.

### AK-7: Audio-Ende beendet Preview automatisch

- Gegeben: Preview ist auf die letzten 2 s vor Ende geseekt und spielt.
  Wenn: Das Audio-File erreicht das Ende.
  Dann: Preview stoppt automatisch, Slider blendet aus, Play-Button geht zurueck zu ▶.

### AK-8: Tab-Wechsel beendet Preview wie bisher

- Gegeben: Preview laeuft mit sichtbarem Slider.
  Wenn: User wechselt zu einem anderen Tab.
  Dann: Preview stoppt; bei Rueckkehr in die Library ist kein Slider sichtbar, Play-Button steht auf ▶. (Verhalten unveraendert; das Ticket bestaetigt nur, dass die UI mitzieht.)

### AK-9: Slider erscheint genauso in den Suchergebnissen

- Gegeben: Library im Such-Modus mit Trefferliste.
  Wenn: User macht Long-Press auf einen Treffer.
  Dann: Slider erscheint unter dem Treffer; Drag funktioniert wie in der Hauptliste.

### AK-10: VoiceOver kann den Slider als Adjustable bedienen

- Gegeben: VoiceOver aktiv, Preview laeuft, Slider sichtbar.
  Wenn: User wischt mit einem Finger nach oben/unten auf dem Slider.
  Dann: Position aendert sich in sinnvollen Schritten (Default-Slider-Adjustable); VoiceOver liest die neue Position vor. Slider hat ein klares Label ("Vorhoer-Position").

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Bottom-up, weil obere Schichten auf den unteren bauen:

1. **AK-2 (Position laeuft mit)** — Domain-Protokoll-Erweiterung + AudioService-Implementierung mit Update-Timer; Test gegen MockAudioService oder echtem AVAudioPlayer in Infrastructure-Test.
2. **AK-3 (Drag-Seek)** — `seekMeditationPreview(to:)` im Service; AudioService-Test (currentTime nach Seek korrekt).
3. **AK-7 (Audio-Ende)** — Delegate-Hookup; Service-Test via Mock-Delegate-Callback.
4. **AK-1, AK-5, AK-6 (Lifecycle in ViewModel)** — ViewModel publisht durchgeleitete Werte; `seekPreview(to:)` ruft Service auf. ViewModel-Test gegen MockAudioService.
5. **AK-1, AK-5, AK-9 (UI)** — `MeditationPreviewProgressRow` View + Integration in beiden Listen. SwiftUI-Preview als Smoke-Check; UI-Test fuer die Long-Press-Sequenz.
6. **AK-4, AK-8 (Edge Cases)** — fallen aus AK-3 und bestehendem Stop-Verhalten heraus; ggf. separate UI-Tests.
7. **AK-10 (VoiceOver)** — am Schluss verifizieren, ggf. nur manueller Test plus Accessibility-Identifier auf dem Slider.

---

## Offene Fragen

Keine. Alle Mehrdeutigkeiten geklaert (Update-Loop im Service, Audio-Ende beendet automatisch, lokaler State waehrend Drag).

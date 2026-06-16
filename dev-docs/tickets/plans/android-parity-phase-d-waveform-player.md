# Implementierungsplan: Android-Parität Phase D — Wellenform-Player „Tonkopf"

Ticket: [shared-109](../shared/shared-109-waveform-player-tonkopf.md)
Erstellt: 2026-06-16
Kontext: Viertes und letztes Paket der Android-Parität. Hängt an [Phase C](android-parity-phase-c-waveform-editor.md) (nutzt dieselbe Wellenform-Infrastruktur) und an [Phase A](android-parity-phase-a-trim-foundation.md) (Trim-Bereich). Bringt den Guided-Player auf den iOS-Endstand.

## Ziel

Der Wiedergabe-Screen einer gefuhrten Meditation zeigt statt des Atemkreises (`PlayerRing`/`BreathingCircle`) die echte Wellenform: Sie scrollt an einer feststehenden, leuchtenden Jetzt-Linie in der Bildschirmmitte vorbei — Vergangenes links (Kupfer), Kommendes rechts blass, sichtbares Fenster ca. ±30 s. Gespult wird durch direktes Ziehen der Welle (links = vor, rechts = zurück); beim Greifen pausiert die Wiedergabe, beim Loslassen läuft sie weiter. Eine Restzeit-Zeile darunter („Noch 17:08", Sonderzustände „Pausiert"/„Beendet"), eine Mini-Übersicht der ganzen Spur mit Gesamtfortschritt (antippen/ziehen springt). Bei gesetztem Zuschnitt beziehen sich Position, Restzeit und Gesamtlänge auf den hörbaren Bereich. Die bisherigen −10s/+10s-Tasten entfallen. Vorbereitungszeit und Start-/End-Gongs (Phase A/B) verhalten sich unverändert.

## Annahmen

- **Wiederverwendung der Wellenform-Infra aus Phase C** (`WaveformProvider`, `MeditationWaveform`). Der Player lädt die volle Wellenform der Datei und zeigt ein gleitendes Fenster um die aktuelle Position.
- **Bereichs-relative Anzeige aus Phase A** (`effectiveStart`/`effectiveEnd`/`effectiveDuration`): Restzeit, Gesamtlänge und Mini-Übersicht rechnen relativ zum Trim-Bereich.
- **Atemkreis bleibt für Timer-Idle/Pre-Roll erhalten.** Nur die Haupt-Wiedergabephase des Guided-Players wechselt zur Welle. Der Pre-Roll-Countdown (Vorbereitungszeit) behält seine bestehende Darstellung.
- **Scrub-by-Drag ersetzt die Skip-Buttons.** Ziehen der Welle pausiert (greifen) und resümiert (loslassen) — Apple-Music-Style. Die ±10s-Buttons werden entfernt.
- **Scrubbing bleibt im Trim-Bereich** (Phase A: Klemmung auf `[trimStart, trimEnd]`).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/meditations/components/PlayerWaveform.kt` | UI | **Neu** | Canvas: scrollende Welle an fester Mittellinie, ±30 s Fenster, Kupfer/blass; Drag-to-scrub |
| `presentation/ui/meditations/components/PlayerTrackOverview.kt` | UI | **Neu** | Mini-Übersicht der ganzen Spur mit Position; antippen/ziehen springt |
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | UI | Erweitern | Haupt-Phase: Welle + Restzeit-Zeile + Übersicht statt `PlayerRing`; Skip-Buttons entfernen; Pre-Roll unverändert |
| `presentation/ui/meditations/components/PlayerRing.kt` | UI | Behalten/prüfen | Bleibt für Pre-Roll/andere Nutzung; ggf. nur in Hauptphase ersetzt |
| `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` | ViewModel | Erweitern | Wellenform laden (`WaveformProvider`); `isDragging`/Scrub-State; Restzeit-Zustände (laufend/pausiert/beendet) bereichs-relativ |
| `app/src/main/res/values*/strings.xml` | Resources | Erweitern | Restzeit-Texte „Noch {Zeit}"/„Pausiert"/„Beendet" (DE+EN, identisch iOS) |
| `test/.../GuidedMeditationPlayerViewModelTest.kt` | Tests | Erweitern | Scrub-State, bereichs-relative Restzeit, Drag-pausiert/resümiert |

## API-Recherche

| API | Quelle | Hinweis |
|-----|--------|---------|
| `Canvas` + `drawIntoCanvas` (Compose) | Compose Docs | Scrollende Welle; Vorbild `TrimWaveformView` (Phase C), `GongWaveform` |
| `pointerInput`/`detectHorizontalDragGestures` | Compose Docs | Drag-to-scrub; greifen pausiert, loslassen resümiert |
| `MediaPlayer.seekTo(ms, SEEK_CLOSEST)` (API 26) | Android Docs | Scrub-Seek; bestehender `seekTo`-Pfad im `AudioPlayerService` |

## Design-Entscheidungen

### 1. Welle nur in der Hauptphase
Pre-Roll-Countdown behält die bestehende Darstellung; erst die laufende Wiedergabe zeigt die Welle. Vermeidet Umbau am Vorbereitungs-Pfad und hält die Änderung fokussiert.

### 2. Feste Jetzt-Linie, Welle bewegt sich
Die Mittellinie steht, die Welle scrollt — wie iOS. Das Fenster (±30 s) wird aus `MeditationWaveform.windowed()` um die aktuelle bereichs-relative Position gerechnet.

### 3. Scrub-by-Drag statt Skip-Buttons
Greifen pausiert (kein Knacken, sauberer Seek), loslassen resümiert. Die ±10s-Buttons entfallen ersatzlos — die Welle ist das Steuerelement.

### 4. Alles bereichs-relativ
Position 0 = `effectiveStart`, Gesamtlänge = `effectiveDuration`. Restzeit, Übersicht und Scrub-Grenzen rechnen im Trim-Bereich (Phase A).

## Fachliche Szenarien (Akzeptanzkriterien)

### AK: Welle scrollt an fester Linie
- Gegeben: Wiedergabe läuft
  Dann: Vergangenes links in Kupfer, Kommendes rechts blass; die Jetzt-Linie steht in der Mitte; Fenster ca. ±30 s.

### AK: Drag spult und pausiert/resümiert
- Gegeben: Wiedergabe läuft
  Wenn: Nutzer greift die Welle und zieht
  Dann: Wiedergabe pausiert, Mitte zeigt die Zielposition; beim Loslassen läuft sie ab dort weiter. Ziehen nach links = vor, nach rechts = zurück.

### AK: Restzeit-Zeile
- Laufend: „Noch 17:08". Pausiert: „Pausiert". Beendet: „Beendet". Bei Zuschnitt relativ zum hörbaren Bereich.

### AK: Mini-Übersicht
- Zeigt Gesamtfortschritt der ganzen (getrimmten) Spur; Antippen/Ziehen springt an die Stelle.

### AK: Skip-Buttons entfallen
- Keine −10s/+10s-Tasten mehr.

### AK: Scrub bleibt im Bereich
- Bei gesetztem Zuschnitt lässt sich nicht in Intro/Outro scrubben.

### AK: Vorbereitung + Gongs unverändert
- Pre-Roll und Start-/End-Gong (Phase A/B) verhalten sich wie zuvor.

### AK: Fehlende/fehlerhafte Wellenform
- Fallback wie Phase C (schlichte Linie); Restzeit/Übersicht/Scrub bleiben funktional.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **ViewModel** — Wellenform laden, Scrub-State (`isDragging`), bereichs-relative Restzeit-Zustände.
2. **`PlayerWaveform`** — scrollendes Fenster, Färbung, feste Mittellinie.
3. **Drag-to-scrub** — greifen pausiert, loslassen resümiert, Richtungslogik.
4. **`PlayerTrackOverview`** — Übersicht + Sprung.
5. **Screen-Integration** — Hauptphase ersetzt Ring; Skip-Buttons raus; Pre-Roll bleibt.
6. **Lokalisierung** — Restzeit-Texte DE+EN.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Scroll-Performance der Welle bei jedem Frame | Vorab `downsampled`/`windowed` cachen; nur Fenster neu zeichnen; Recomposition begrenzen |
| Drag-Geste vs. Position-Polling (Slider zappelt) | Lokaler Drag-State + nur synchronisieren wenn nicht gedraggt (Muster aus shared-098-Preview-Slider) |
| Entfernen der Skip-Buttons bricht Lock-Screen-Controls | Lock-Screen-Seek/Skip (±15 s) bleibt über `MediaSessionManager` (Phase A) erhalten — nur die In-App-Buttons entfallen |
| Cross-Platform-Divergenz (Fensterbreite, Farben) | ±30 s, Kupfer/blass, Mittellinie exakt von iOS übernehmen |

## Offene Fragen

- Verhalten der Welle im Pause-Zustand (eingefroren vs. dezent) — exakten iOS-Stand übernehmen.

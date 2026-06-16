# Implementierungsplan: Android-Parität Phase B — Gong pro Meditation

Tickets: [shared-106](../shared/shared-106-start-end-gong-pro-meditation.md) + [shared-116](../shared/shared-116-meditation-editor-gong-klang-picker.md) (kollabiert)
Erstellt: 2026-06-16
Kontext: Zweites von vier Paketen der Android-Parität (siehe [Phase A](android-parity-phase-a-trim-foundation.md)). iOS hat den Gong-Picker in shared-106 zunächst als schlichte Liste gebaut und in shared-116 zum Karten-Picker umgestaltet. Android baut direkt den Endzustand (Karten-Picker), weil die Karten-Komponenten aus shared-115 (`GongCard`, `GongPreviewButton`, `GongWaveform`, `GongSoundRow`) bereits existieren.

## Ziel

Pro Meditation ein optionaler Start- und End-Gong (unabhängig schaltbar), mit pro Meditation wählbarem Klang. Im Editor: zwei Schalter „Gong am Anfang"/„Gong am Ende", darunter — sobald einer aktiv ist — der Karten-Klang-Picker (wie Timer „Start & Ende", ohne Vibration, ohne Lautstärke-Regler) und klare Section-Überschriften „Informationen"/„Wiedergabebereich"/„Zusätzlicher Gong".

Phase B ist unabhängig von Phase A und kann parallel laufen. Einzige Berührung: der End-Gong braucht den End-Boundary-Trigger; ohne Phase A feuert er am Dateiende statt am Trim-Ende — funktional korrekt, nur eben ohne Trim.

## Annahmen

- **Dedizierter Gong-Player für den Meditations-Pfad, nicht `AudioService.playGong`.** `AudioService` ist der Timer-Singleton und registriert Conflict-/Pause-Handler für `AudioSource.TIMER`/`PREVIEW`; sein Gong über die Guided-Playback-Session zu spielen würde die `GUIDED_MEDITATION`-Session-Logik stören. Spiegelt iOS' Entscheidung, statt `AudioService` einen eigenen `MeditationGongPlayer` zu nutzen. Neuer `MeditationGongPlayer` (Infrastructure) über `MediaPlayerFactoryProtocol`, der die `GUIDED_MEDITATION`-Session **nicht** freigibt.
- **Lautstärke folgt der Timer-Gong-Lautstärke** (`MeditationSettings.gongVolume` aus `PraxisRepository`), nicht pro Meditation gespeichert — wie iOS.
- **Vibration ist ausgeschlossen.** Meditations-Gongs nutzen `GongSound.allSounds.filter { it.id != VIBRATION_ID }` (Android-Pendant zu iOS' `allMeditationGongSounds`). Kein Vibrations-Eintrag, kein Lautstärke-Regler im Editor-Picker.
- **Lock-Screen-fest.** Der `MeditationPlayerForegroundService` hält Prozess + Audio-Session am Leben; ein einfacher `MediaPlayer`-Gong spielt damit auch bei gesperrtem Screen. Der End-Gong hält den Service/die Session aktiv, bis er fertig ist (Pendant zum iOS-Lock-Screen-Gong-Bug-Präzedenzfall).
- **Persistenz wie Phase A:** neue Felder `startGongEnabled`/`endGongEnabled`/`gongSoundId` mit Defaults — rückwärtskompatibel über `encodeDefaults`/`ignoreUnknownKeys`. iOS faltet einen Legacy-`gongEnabled`-Kombi-Flag; auf Android gab es nie einen solchen Flag für Meditationen, daher reine Neufelder mit Default (aus, Standardklang).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/GuidedMeditation.kt` | Domain | Erweitern | `startGongEnabled: Boolean = false`, `endGongEnabled: Boolean = false`, `gongSoundId: String = GongSound.DEFAULT_SOUND_ID` |
| `domain/models/EditSheetState.kt` | Domain | Erweitern | Gepufferte editierbare Felder für die drei Gong-Werte; `hasChanges`/`applyChanges` berücksichtigen sie |
| `infrastructure/audio/MeditationGongPlayer.kt` | Infra | **Neu** | One-shot-Gong (Start/Ende) über `MediaPlayerFactory`; `play(soundId, volume, onComplete)`; gibt die Guided-Session nicht frei |
| `domain/services/MeditationGongPlayerProtocol.kt` | Domain | **Neu** | Protokoll für Testbarkeit (Mock im ViewModel-Test) |
| `infrastructure/di/AppModule.kt` | Infra | Erweitern | Binding `MeditationGongPlayerProtocol` → Impl |
| `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` | ViewModel | Erweitern | Start-Ablauf: (Vorbereitung →) Start-Gong vollständig → ~2 s Atempause → Audio; End-Ablauf: bei `effectiveEnd`/Dateiende End-Gong vollständig, dann Completion; Resume/Restart spielen keinen erneuten Start-Gong |
| `presentation/ui/timer/components/GongSoundRow.kt` (o.ä.) | UI | **Refactor/Extract** | `GongSoundRow` + `SoundCard` aus `SelectGongScreen.kt` (privat) in eine geteilte Komponente herausziehen, damit Editor + Timer sie teilen |
| `presentation/ui/meditations/MeditationEditSheet.kt` | UI | Erweitern | Section-Überschriften (Newsreader); Toggles „Gong am Anfang/Ende"; geteilter Klang-Picker, sichtbar wenn ≥1 Toggle aktiv |
| `presentation/ui/timer/SelectGongScreen.kt` | UI | Anpassen | Nutzt die extrahierte geteilte Row/Card-Komponente weiter (kein Verhaltenswechsel) |
| `app/src/main/res/values*/strings.xml` | Resources | Erweitern | Toggle-Labels, Section-Titel (DE + EN, identisch zu iOS) |
| `test/.../GuidedMeditationPlayerViewModelTest.kt` | Tests | Erweitern | Start-/End-Gong-Sequenz mit Mock-`MeditationGongPlayer` |
| `test/.../GuidedMeditationTest.kt` | Tests | Erweitern | Defaults + Backward-Compat der neuen Felder |

## API-Recherche

| API | Quelle | Hinweis |
|-----|--------|---------|
| `MediaPlayer.setOnCompletionListener` | Android Docs | Gong-Ende → Atempause/Completion-Callback (bereits in `AudioService.playGong` so genutzt) |
| Foreground-Service-Keep-Alive | bestehend | `MeditationPlayerForegroundService` läuft während des End-Gongs weiter; erst nach Gong-Ende stoppen |

## Design-Entscheidungen

### 1. Eigener `MeditationGongPlayer` statt `AudioService`-Mitbenutzung
Wie iOS (shared-106): ein kleiner, eigenständiger Gong-Player verhindert die doppelte Registrierung von Conflict-Handlern und Session-Freigaben, die `AudioService` für den Timer hält. Er spielt nur den Gong und meldet Completion zurück — die Session-/Service-Hoheit bleibt beim `AudioPlayerService` (Guided-Pfad).

### 2. Start-Ablauf atomar zur bestehenden Wiedergabe
Start-Gong → ~2 s Atempause → Audio-Start. Mit Vorbereitungszeit: Gong nach dem Countdown. Resume nach Pause und Restart nach Abschluss spielen **keinen** erneuten Start-Gong (der Gong markiert nur den Sitzungsbeginn) — wie iOS.

### 3. End-Gong hält die Session
Bei Erreichen des End-Punkts (Phase A: `effectiveEnd`; ohne Phase A: Dateiende) wird der End-Gong gespielt, **bevor** Service/Session freigegeben werden. Der Completion-/Abschluss-Screen erscheint regulär; die Session bleibt aktiv bis der Gong ausgeklungen ist — auch bei gesperrtem Screen.

### 4. Karten-Picker als geteilte Komponente
`GongSoundRow`/`SoundCard` werden aus `SelectGongScreen.kt` extrahiert (sie sind dort heute privat) und sowohl vom Timer als auch vom Editor genutzt — identische Optik, im Editor ohne Vibration und ohne Lautstärke-Karte. Vermeidet Duplikat-Drift zwischen Timer- und Editor-Picker.

## Fachliche Szenarien (Akzeptanzkriterien)

### AK: Toggles erscheinen im Editor
- Gegeben: Editor offen
  Wenn: Nutzer sieht den Abschnitt „Zusätzlicher Gong"
  Dann: zwei Schalter „Gong am Anfang" / „Gong am Ende", beide standardmäßig aus.

### AK: Klang-Picker erscheint nur bei aktivem Gong
- Gegeben: beide Toggles aus
  Wenn: Nutzer aktiviert „Gong am Anfang"
  Dann: darunter erscheint der Karten-Picker (vier Klänge, je Vorhör-Button + Mini-Wellenform), keine Vibration, kein Lautstärke-Regler.

### AK: Start-Gong rahmt den Beginn
- Gegeben: Meditation mit aktivem Start-Gong
  Wenn: Wiedergabe startet (ggf. nach Vorbereitungs-Countdown)
  Dann: Gong klingt vollständig aus, ~2 s Atempause, dann beginnt das Audio.

### AK: End-Gong klingt am Ende aus — auch gesperrt
- Gegeben: Meditation mit aktivem End-Gong, Screen gesperrt
  Wenn: die Wiedergabe das Ende erreicht
  Dann: der End-Gong spielt vollständig, bevor die Session freigegeben wird; Abschluss-Screen erscheint regulär.

### AK: Resume/Restart ohne erneuten Start-Gong
- Gegeben: pausierte oder beendete Meditation mit Start-Gong
  Wenn: Nutzer fortsetzt oder neu startet
  Dann: kein erneuter Start-Gong.

### AK: Klang gilt für beide Gongs, unabhängig vom Timer
- Gegeben: Meditation mit gewähltem Klang X
  Wenn: der Timer-Gong später auf Y geändert wird
  Dann: die Meditation spielt weiter X (Start und Ende); nur die Lautstärke folgt der Timer-Gong-Lautstärke.

### AK: Bestehende Meditationen spielen ohne Gong
- Gegeben: Library-Eintrag vor diesem Update
  Wenn: er geladen/gespielt wird
  Dann: beide Gong-Flags `false`, Standardklang gesetzt, kein Gong.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Domain `GuidedMeditation`** — Felder + Defaults + Backward-Compat-Test.
2. **`EditSheetState`** — Gong-Felder in Puffer/`hasChanges`/`applyChanges`.
3. **`MeditationGongPlayer`** — Protokoll + Impl, isoliert getestet (spielt, meldet Completion).
4. **ViewModel Start-Sequenz** — Gong → Pause → Audio (Mock-Gong-Player verifiziert Reihenfolge).
5. **ViewModel End-Sequenz** — End-Gong vor Session-Freigabe.
6. **UI-Extraktion** — `GongSoundRow`/`SoundCard` geteilt; Timer unverändert grün.
7. **Editor-UI** — Section-Titel, Toggles, Picker; Lokalisierung DE+EN.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| End-Gong wird bei Session-Freigabe abgeschnitten | Service/Session erst im Gong-Completion-Callback stoppen; expliziter Lock-Screen-Test |
| Doppelte Audio-Session-Registrierung Gong vs. Guided | Dedizierter Player ohne eigene Session-Hoheit (Design-Entscheidung 1) |
| Extraktion der Row/Card bricht Timer-Optik | Reines Move-Refactoring; Timer-Screenshot/Preview vor/nach vergleichen |
| detekt LongMethod im erweiterten Editor | Gong-Abschnitt früh in eigene Composables (`GongSection`, `GongToggleRow`) aufteilen (Memory) |

## Offene Fragen

- Atempausen-Dauer: iOS nutzt ~2 s. Exakten Wert aus dem iOS-Code übernehmen, bevor implementiert wird (Cross-Platform-Konsistenz).

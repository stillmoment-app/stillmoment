# Plan shared-106 (iOS): Start-/End-Gong pro Meditation

## Aenderungsrequest (2026-06-12): Klangauswahl pro Meditation

Die Basis-Implementierung (unten) ist gemergt (Commit 2667f61). Umbau:

1. **Domain:** `GuidedMeditation.gongSoundId: String` (Default
   `GongSound.defaultSoundId`, `decodeIfPresent ?? default` fuer Bestandsdaten),
   beide Inits + `withLocalFilePath` tragen es weiter. Neu:
   `GongSound.allMeditationGongSounds` = `allSounds` ohne Vibration (Vibration
   entfaellt bewusst fuer Meditationen).
2. **EditSheetState:** `editedGongSoundId` (Prefill/hasChanges/applyChanges).
3. **ViewModel:** `playStartGongThenTransition` und `configureEndGong` nutzen
   `meditation.gongSoundId`; Lautstaerke weiterhin `praxis.gongVolume`
   (kein eigener Regler pro Meditation — bewusste Entscheidung).
4. **UI:** Im Edit-Sheet unter dem Toggle (nur bei aktivem Toggle) Klang-Rows
   wie `GongSelectionView` (Checkmark, Tap = Auswahl + Preview via bereits
   injiziertem `audioService.playGongPreview`, Volume aus `PraxisRepository`).
   `stopGongPreview()` bei Disappear. Footer-Hint anpassen (Klang pro
   Meditation, Lautstaerke folgt Timer-Einstellungen).
5. **Lokalisierung:** `guided_meditations.edit.gongHint` (DE/EN) anpassen;
   `accessibility.sound.select.hint` und `gong.*`-Namen existieren bereits.
6. **Tests:** Erweiterung der bestehenden Gong-Testdateien
   (GuidedMeditationGongTests, EditSheetStateGongTests,
   PlayerViewModelGongTests, GuidedMeditationServiceTests+Gong);
   Helper `createTestMeditation` bekommt `gongSoundId`-Parameter.

## Stand & Wiedereinstieg (2026-06-11)

- **shared-105 (Trim-Punkte, iOS) ist FERTIG und auf main gemergt** (Commit a595cf5,
  Merge auf main; Tests 1041/1041 gruen, `make check` gruen, visuell verifiziert).
- **shared-106 (iOS): noch NICHT implementiert.** Branch `feature/shared-106-gong-ios`
  existiert, dieser Plan ist verbindlich. Naechster Schritt: TDD-Schritt 1 (Domain,
  `gongEnabled`-Flag) — Tests analog `GuidedMeditationTrimTests.swift` als Vorlage.
- Arbeitsmodus: vollautonom, NUR allowlisted Kommandos (`.claude/settings.local.json`
  lesen!), Tests via `make -C ios test-single-agent TEST=...`, keine Pipes/Chains,
  UI-Dumps mit Read-Tool parsen. Simulator: iPhone 17 / iOS 26.2
  (DF552057-88A2-4870-BF60-2F9E75E56131), Screenshots-Scheme `StillMoment-Screenshots`
  fuer geseedete Library.
- Nach Abschluss: CHANGELOG (Unreleased/iOS), Ticket + INDEX auf iOS [x],
  Merge --no-ff nach main, Branch loeschen, Abschlussbericht (inkl. Hinweis auf
  manuell zu verifizierende Lock-Screen-Faelle).

## Architektur-Entscheidungen

1. **Domain:** `GuidedMeditation.gongEnabled: Bool` (Default `false`). Codable mit
   `decodeIfPresent ?? false` (Legacy-Eintraege bleiben ohne Gong). `withLocalFilePath`
   traegt das Flag weiter. `EditSheetState.editedGongEnabled` + hasChanges/applyChanges.
2. **Klang/Lautstaerke aus den Timer-Einstellungen:** `Praxis.startGongSoundId` +
   `gongVolume` via `PraxisRepository` (im ViewModel injiziert) — keine eigene
   Klangauswahl, kein Per-Track-Override.
3. **Eigener kleiner Gong-Player statt AudioService-Mitbenutzung:**
   `MeditationGongPlayerProtocol` (Domain) + `MeditationGongPlayer` (Infrastructure,
   AVAudioPlayer + bestehender `GongPlayerDelegate`, Vibration-Sonderfall via
   `AudioServicesPlaySystemSound` mit sofortiger Completion). Begruendung: Eine
   zweite AudioService-Instanz wuerde Conflict-Handler/Keep-Alive doppelt
   registrieren; die Datei-Aufloesung (GongSound.findOrDefault + GongSounds/-Bundle)
   ist klein genug zum Spiegeln.
4. **Start-Ablauf (Orchestrierung im PlayerViewModel, wiederverwendet die
   Countdown-Maschinerie):**
   - Ohne Vorbereitungszeit: `startSilentBackgroundAudio()` (aktiviert Session +
     Keep-Alive) → Start-Gong → Completion-Callback → Atempause (2 s via Clock)
     → `transitionFromSilentToPlayback()` (luecken- und lockscreen-sicher).
   - Mit Vorbereitungszeit: bestehender Countdown laeuft (Silent-Audio aktiv);
     bei Countdown-Ende statt direkt zu transitionieren: Gong → Completion →
     Atempause → Transition.
   - Resume nach Pause: kein Gong (nur beim Session-Start, `hasSessionStarted`).
   - Neustart aus `.finished`: kein erneuter Start-Gong (bewusst minimal).
5. **End-Ablauf (im AudioPlayerService — Lock-Screen-kritisch):** ViewModel ruft
   nach `load()` `configureEndGong(soundId:volume:)` wenn `gongEnabled`. In
   `handlePlaybackFinished()` (natuerliches Ende UND Trim-Ende-Boundary aus
   shared-105): state `.finished` + NowPlaying-Cleanup wie bisher, aber die
   Session-Freigabe wird aufgeschoben — Gong spielt in der noch aktiven Session,
   erst der Gong-Completion-Callback ruft `releaseAudioSession`. `cleanup()`
   stoppt einen laufenden End-Gong und gibt sofort frei.
6. **UI:** Neue Edit-Sheet-Section mit Toggle "Gong am Anfang und Ende"
   (custom ToggleStyle des Projekts), Footer-Hinweis (Klang folgt Timer-
   Einstellungen). DE/EN + Accessibility.

## Reihenfolge (TDD)

1. Domain: gongEnabled + Codable + Migration (GuidedMeditationTrimTests-Pendant).
2. EditSheetState: Toggle-Aenderung (hasChanges/applyChanges).
3. Persistenz: Service-Roundtrip.
4. ViewModel-Orchestrierung gegen erweiterten MockAudioPlayerService + MockClock:
   - startPlayback mit Gong: erst Gong, Audio erst nach Completion + Pause
   - Countdown-Variante
   - Resume ohne Gong
   - configureEndGong wird bei gongEnabled nach load aufgerufen, sonst nicht
5. Infrastructure: MeditationGongPlayer + AudioPlayerService-Endgong (manuell
   verifizieren — AVAudioPlayer).
6. UI + Lokalisierung + Screenshot-Verifikation.

## Risiken

- Session-Freigabe-Reihenfolge am Ende (Praezedenzfall Lock-Screen-Gong-Bug) —
  deshalb komplett im AudioPlayerService gekapselt, Freigabe nur im Callback.
- Atempause waehrend Lock Screen: Silent-Keep-Alive laeuft bereits (Countdown-
  Infrastruktur), kein neuer Mechanismus.
- `file_length`/`type_body_length` im AudioPlayerService: Gong-Teil in
  `AudioPlayerService+Gong.swift`-Extension, Stored Properties in der Klasse.

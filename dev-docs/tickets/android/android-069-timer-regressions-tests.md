# Ticket android-069: Timer-Regressions-Tests implementieren

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Die leere `TimerViewModelRegressionTest.kt` mit konkreten Regressions-Tests befuellen — analog zu den iOS-Regressions-Tests die bekannte Bugs absichern.

## Warum

iOS hat 4 kritische Regressions-Tests die dokumentierte Bugs verhindern. Android hat eine leere Datei als Platzhalter. Ohne diese Tests koennen dieselben Bugs auf Android eingeschleppt werden ohne dass CI es merkt.

---

## Akzeptanzkriterien

### Tests (mindestens diese 4 Szenarien)

- [ ] **Audio-Reihenfolge beim Start**: Background-Audio startet NACH dem Start-Gong, nicht waehrend oder davor
  - Szenario: Timer starten → Start-Gong spielt → erst dann startet Background-Audio
  - iOS-Referenz: `testBackgroundAudioStartsWhenMeditationBegins()`

- [ ] **Completion-Gong vor Background-Audio-Stop**: Beim Timer-Ablauf spielt zuerst der End-Gong, DANN stoppt das Background-Audio
  - Szenario: Timer laeuft ab → End-Gong wird gespielt → danach erst `stopBackgroundAudio`-Effect
  - iOS-Referenz: `testCompletionGongPlaysBeforeBackgroundAudioStops()`

- [ ] **Interval-Gong mehrfach**: Interval-Gong spielt in einer laengeren Meditation mehrfach (nicht nur einmal)
  - Szenario: 10-Minuten-Timer, 3-Minuten-Interval → 3 Gongs (bei 3min, 6min, 9min)
  - iOS-Referenz: `testIntervalGongPlaysMultipleTimes_NotJustOnce()`

- [ ] **Background-Audio nach Introduction**: Nach Ende der Introduction startet Background-Audio (nicht vorher)
  - Szenario: Timer mit Introduction → Introduction endet → Background-Audio startet
  - iOS-Referenz: `testBackgroundAudioStartsAfterIntroductionFinishes()`

### Allgemein
- [ ] Tests laufen in `TimerViewModelRegressionTest.kt` (existierende Datei nutzen, nicht neue anlegen)
- [ ] Fakes/Mocks: Vorhandene Test-Infrastruktur nutzen (keine neuen Fakes anlegen wenn vorhanden)
- [ ] `make test` gruen

### Dokumentation
- [ ] Keine

---

## Referenz

- iOS: `ios/StillMomentTests/TimerViewModel/TimerViewModelRegressionTests.swift`
- Android: `android/app/src/test/.../viewmodel/TimerViewModelRegressionTest.kt` (leere Datei)
- Android: Bestehende Fakes in `...viewmodel/` oder `...domain/` als Vorlage

---

## Hinweise

Die Regressions-Tests testen Verhalten das aus Bug-Reports entstanden ist. Sie sollen sicherstellen dass bekannte Fehler nicht wieder eingeschleppt werden. Jeder Test soll seinen Ursprungs-Bug im Kommentar dokumentieren.

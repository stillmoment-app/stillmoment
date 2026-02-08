# Ticket ios-033: SettingsView — Business-Logik ins ViewModel verschieben

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: shared-024, ios-032
**Phase**: 2-Architektur

---

## Was

Audio-Preview-Logik aus SettingsView ins TimerViewModel verschieben. SettingsView wird zur reinen View ohne Services — analog zu GuidedMeditationSettingsView.

## Warum

SettingsView haelt aktuell `AudioService` (via `AudioServiceHolder`) und `BackgroundSoundRepository` intern und enthaelt Business-Logik (`playGongPreview`, `playBackgroundPreview`, `playIntervalGongPreview`). Das verletzt Clean Architecture: Views sollen keine Services halten und keine Business-Logik enthalten.

GuidedMeditationSettingsView zeigt das korrekte Pattern: reine View, keine Services, Daten rein, Callbacks raus.

Gefunden im Clean Architecture Review (shared-024).

---

## Ist-Zustand

```
SettingsView (haelt AudioService + BackgroundSoundRepository)
  ├── @StateObject AudioServiceHolder (erstellt intern AudioService)
  ├── soundRepository: BackgroundSoundRepositoryProtocol (Default im init)
  ├── playGongPreview(soundId:)           ← Business-Logik in View
  ├── playIntervalGongPreview()           ← Business-Logik in View
  ├── playBackgroundPreview(soundId:)     ← Business-Logik in View
  └── dismissWithCleanup()                ← Business-Logik in View
```

## Soll-Zustand

```
TimerViewModel (hat bereits AudioService, bekommt zusaetzlich BackgroundSoundRepository)
  ├── playGongPreview(soundId:, volume:)
  ├── playIntervalGongPreview(volume:)
  ├── playBackgroundPreview(soundId:, volume:)
  ├── stopAllPreviews()
  └── availableBackgroundSounds: [BackgroundSound]

SettingsView (reine View, kein Service — wie GuidedMeditationSettingsView)
  ├── @Binding settings: MeditationSettings
  ├── availableSounds: [BackgroundSound]         ← Daten, kein Repository
  ├── onGongChanged: (String, Float) -> Void     ← Callback fuer Preview
  ├── onBackgroundChanged: (String, Float) -> Void
  ├── onIntervalGongPreview: (Float) -> Void
  └── onDismiss: () -> Void
```

---

## Akzeptanzkriterien

### Feature
- [ ] Audio-Preview-Logik lebt im TimerViewModel, nicht in SettingsView
- [ ] `AudioServiceHolder` entfernt — kein interner Service in der View
- [ ] `BackgroundSoundRepository` wird im TimerViewModel gehalten, SettingsView bekommt nur `[BackgroundSound]`
- [ ] SettingsView hat keine Imports von Domain-Services
- [ ] Bestehende Funktionalitaet bleibt erhalten (Previews, Dismiss-Cleanup)

### Tests
- [ ] Bestehende Tests bleiben gruen
- [ ] Neue Unit-Tests fuer Preview-Methoden im TimerViewModel (mit MockAudioService)

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Umsetzungsschritte

1. **TimerViewModel erweitern**: `BackgroundSoundRepositoryProtocol` als Dependency hinzufuegen, Preview-Methoden und `availableBackgroundSounds` implementieren, `stopAllPreviews()` fuer Dismiss
2. **SettingsView umbauen**: Services entfernen, Callbacks als init-Parameter, `AudioServiceHolder` loeschen
3. **TimerView (Call-Site) anpassen**: Callbacks an TimerViewModel-Methoden binden
4. **Previews anpassen**: Verwenden leere Closures (wie GuidedMeditationSettingsView)
5. **Tests schreiben**: Preview-Methoden im TimerViewModel testen

---

## Manueller Test

1. Settings oeffnen
2. Gong-Sound aendern → Preview abspielen
3. Background-Sound aendern → Preview abspielen
4. Interval-Gong-Volume aendern → Preview abspielen
5. Sheet per Swipe schliessen → Previews stoppen
6. Sheet per Done-Button schliessen → Previews stoppen
7. Erwartung: Alles funktioniert wie bisher

---

## Referenz

- Vorbild: `GuidedMeditationSettingsView` — reine View ohne Services
- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- DI-Architektur: shared-007
- Vorgaenger: ios-032 (TimerSettingsRepository)

---

## Hinweise

- `TimerViewModel` hat bereits `AudioServiceProtocol` — die Preview-Methoden nutzen denselben Service
- `BackgroundSoundRepository` kommt als neue Dependency ins TimerViewModel (Constructor Injection, Protocol-basiert)
- Previews in SettingsView brauchen keine Mocks — leere Closures reichen (`{ _, _ in }`)

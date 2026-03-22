# Ticket shared-067: Rename Introduction → Attunement (Code + UI)

**Status**: [~] IN PROGRESS
**Plan**: [Implementierungsplan iOS](../plans/shared-067-ios.md)
**Prioritaet**: NIEDRIG
**Komplexitaet**: Mechanisch aber breit (~90 Dateien). Einziger konzeptioneller Teil: Persistenz-Migration.
**Phase**: 4-Polish

---

## Was

Alle Vorkommen von "Introduction" / "Einleitung" auf "Attunement" / "Einstimmung" umbenennen — im Code (Typen, Properties, Methoden, Enum-Cases, Dateinamen), in Lokalisierungs-Keys, in UI-Texten und in der Dokumentation. Der Domain-Begriff wurde bereits in Teilen der Dokumentation umbenannt (Glossar, Audio-System, DDD) — jetzt muessen Code und UI nachziehen.

## Warum

Code, UI und Dokumentation verwenden unterschiedliche Begriffe fuer dasselbe Konzept. "Attunement" / "Einstimmung" transportiert die meditative Absicht besser als das generische "Introduction" / "Einleitung". Konsistente Terminologie ueberall — vom Quellcode ueber die UI bis zur Doku — verhindert Verwirrung bei der Weiterentwicklung.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Code-Rename (beide Plattformen)

#### Typen und Dateien
- [ ] Domain-Model heisst `Attunement` (vorher `Introduction`)
- [ ] Dateinamen enthalten `Attunement` statt `Introduction`

#### Properties und Variablen
- [ ] `introductionId` → `attunementId` in Settings, Timer, DisplayState
- [ ] Audio-Player-Properties verwenden `attunement` statt `introduction`
- [ ] Publisher/Flow-Properties verwenden `attunement` statt `introduction`

#### Methoden
- [ ] `playIntroduction` → `playAttunement`
- [ ] `stopIntroduction` → `stopAttunement`
- [ ] `endIntroduction` → `endAttunement`
- [ ] Alle weiteren Methoden mit `introduction` im Namen

#### Enum-Cases und State Machine
- [ ] `TimerState.introduction` → `TimerState.attunement`
- [ ] `TimerAction.introductionFinished` → `TimerAction.attunementFinished`
- [ ] `TimerEffect.playIntroduction` → `TimerEffect.playAttunement`
- [ ] `TimerEffect.stopIntroduction` → `TimerEffect.stopAttunement`
- [ ] `TimerEffect.endIntroductionPhase` → `TimerEffect.endAttunementPhase`

### UI-Aenderungen (beide Plattformen)

#### Bildschirmtitel und Sektions-Header
- [ ] Settings-Screen: Sektions-Header zeigt "Attunement" (EN) / "Einstimmung" (DE) statt "Introduction" / "Einleitung"
- [ ] Auswahl-Screen: Titel zeigt "Attunement" / "Einstimmung" (iOS: `IntroductionSelectionView` → `AttunementSelectionView`, Android: `SelectIntroductionScreen` → `SelectAttunementScreen`)
- [ ] Praxis-Editor: Row-Label zeigt "Attunement" / "Einstimmung" statt "Introduction" / "Einleitung"
- [ ] Praxis-Editor: Leer-Zustand zeigt "No Attunement" / "Ohne Einstimmung" statt "No Introduction" / "Ohne Einleitung" (Android)

#### Import-Dialog
- [ ] `import_type_attunement_description`: EN "Use as attunement" statt "Use as introduction", DE pruefen

#### Accessibility
- [ ] Alle Accessibility-Labels konsistent auf neuen Begriff (beide Sprachen)
- [ ] Android: Inkonsistenz aufloesen — UI-Labels sagten "Einleitung", Accessibility-Labels sagten bereits "Einstimmung". Nach Rename einheitlich "Einstimmung"
- [ ] Accessibility-Hints aktualisiert (z.B. "Waehle eine optionale Einstimmung")

### Lokalisierung

#### Key-Rename
- [ ] Alle Lokalisierungs-Keys umbenennen: `introduction.*` → `attunement.*` (iOS: ~8 Keys, Android: ~14 Keys)
- [ ] `settings_introduction` → `settings_attunement`
- [ ] `accessibility_introduction_*` → `accessibility_attunement_*`
- [ ] `praxis_editor_introduction_*` → `praxis_editor_attunement_*`

#### Texte
- [ ] EN: Alle "Introduction" → "Attunement"
- [ ] DE: Alle "Einleitung" → "Einstimmung"

### Persistenz

- [ ] iOS: UserDefaults-Migration — gespeicherter `introductionId`-Key wird beim ersten Start zu `attunementId` migriert
- [ ] Android: SharedPreferences/DataStore-Migration — gespeicherter `introductionId`-Key wird migriert
- [ ] Kein Datenverlust der Benutzer-Einstellung durch Rename

### Tests
- [ ] Bestehende Unit Tests iOS angepasst und gruen (~31 Dateien betroffen)
- [ ] Bestehende Unit Tests Android angepasst und gruen (~17 Dateien betroffen)
- [ ] Persistenz-Migration getestet (alter Key → neuer Key)

### Dokumentation
- [ ] Glossar: "Code-Rename pending"-Hinweise entfernen
- [ ] Audio-System-Doku: Code-Referenzen aktualisieren
- [ ] Timer-State-Machine-Doku: State-Namen aktualisieren
- [ ] DDD-Doku: Effect/Action-Namen aktualisieren
- [ ] ADR-004: `introductionPlayer`-Referenz aktualisieren

### Allgemein
- [ ] Keine funktionale Aenderung — rein mechanischer Rename
- [ ] App baut und laeuft auf beiden Plattformen
- [ ] `make check` pass auf beiden Plattformen

---

## Manueller Test

1. App mit bestehender Einstimmungs-Einstellung oeffnen (vor Migration)
2. Erwartung: Einstimmung ist weiterhin konfiguriert (Migration hat gegriffen)
3. Timer-Einstellungen → Einstimmungs-Sektion pruefen: Header zeigt "Attunement" / "Einstimmung"
4. Einstimmungs-Picker oeffnen → Bildschirmtitel zeigt "Attunement" / "Einstimmung"
5. Einstimmung "Atemuebung" auswaehlen → Timer starten
6. Erwartung: Start-Gong → Einstimmung spielt → stille Phase beginnt (unveraendertes Verhalten)
7. Praxis-Editor oeffnen → Einstimmungs-Row zeigt "Attunement" / "Einstimmung"
8. VoiceOver/TalkBack aktivieren → Accessibility-Labels pruefen

---

## Scope

**~90 Dateien betroffen** (inkl. Tests und Doku):
- 6 iOS Source-Dateien + 31 Test-Dateien
- 5 Android Source-Dateien + 17 Test-Dateien
- 4 Lokalisierungs-Dateien (2 pro Plattform)
- 8 Dokumentations-Dateien

## Hinweise

- Rein mechanischer Rename — keine Logik-Aenderungen. IDE-Refactoring-Tools nutzen.
- Persistenz-Keys muessen auf beiden Plattformen migriert werden, damit bestehende Einstellungen nicht verloren gehen.
- Audio-Dateinamen (`intro-breath-de.mp3`) muessen NICHT umbenannt werden — nur Code-Identifier und UI-Texte.
- Beide Plattformen koennen unabhaengig voneinander umbenannt werden (keine geteilte Persistenz).
- Android hat bereits teilweise "Einstimmung" in Accessibility-Labels — dieses Ticket normalisiert die Inkonsistenz.

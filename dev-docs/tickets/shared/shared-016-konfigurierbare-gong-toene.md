# Ticket shared-016: Konfigurierbarer Start/Ende-Gong

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~M | Android ~M
**Phase**: 3-Feature

---

## Was

Der Start/Ende-Gong ist aus 5 verschiedenen Gong-Toenen waehlbar. Bei Auswahl im Settings-Menue wird automatisch eine Vorschau abgespielt. Der Intervall-Gong bleibt fest (`interval.mp3`).

## Warum

User haben unterschiedliche Vorlieben fuer Gong-Toene. Ein tieferer Ton kann entspannender wirken, ein hoeherer Ton kann aufweckender sein. Die Moeglichkeit zur individuellen Auswahl macht die Meditations-Erfahrung persoenlicher.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Start/Ende-Gong ist aus 5 Gong-Toenen waehlbar
- [x] Bei Auswahl spielt automatisch eine kurze Vorschau des Tons
- [x] Vorschau wird abgebrochen wenn naechster Ton gewaehlt wird (keine Ueberlagerung)
- [x] Einstellung wird persistent gespeichert
- [x] Default: "Classic Bowl" / "Klassisch"
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS (GongSound, MeditationSettings, AudioService)
- [x] Unit Tests Android (GongSound, MeditationSettings, AudioService)

### Dokumentation
- [ ] CHANGELOG.md
- [x] GLOSSARY.md (GongSound als neuer Domain-Begriff)

---

## Manueller Test

1. Timer-Settings oeffnen
2. "Gong-Ton" auf "Deep Zen" aendern
3. Erwartung: Vorschau spielt automatisch ab
4. Schnell auf "Clear Strike" wechseln
5. Erwartung: Vorherige Vorschau stoppt, neue spielt ab
6. Timer starten und bis zum Ende laufen lassen
7. Erwartung: Start-Gong und Ende-Gong spielen den gewaehlten Ton
8. App schliessen und neu oeffnen
9. Erwartung: Einstellung ist gespeichert

---

## Verfuegbare Sounds

Verwendet werden die 5-Sekunden-Versionen aus `singing_bowls/normalized/`:

| ID | Quelldatei | EN Label | DE Label |
|----|------------|----------|----------|
| `classic-bowl` | `singing-bowl-hit-3-33366-5s.mp3` | Classic Bowl | Klassisch |
| `deep-resonance` | `singing-bowl-male-frequency-29714-5s.mp3` | Deep Resonance | Tiefe Resonanz |
| `clear-strike` | `singing-bowl-strike-sound-84682-5s.mp3` | Clear Strike | Klarer Anschlag |
| `deep-zen` | `zen-tone-deep-202555-5s.mp3` | Deep Zen | Tiefer Zen |
| `warm-zen` | `zen-tone-mid-202556-5s.mp3` | Warm Zen | Warmer Zen |

---

## Lokalisierung

**Picker-Label (in der "Klang-Einstellungen" Section):**
- EN: "Gong Sound"
- DE: "Gong-Ton"

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`
- Sound-Dateien: `ios/StillMoment/Resources/GongSounds/`

---

## Implementierungshinweise (aus iOS)

### Accessibility

Der Gong-Picker braucht:
- **Label**: "Gong Sound" / "Gong-Ton"
- **Hint**: "Choose the gong sound for start and end of meditation" / "Waehle den Gong-Ton fuer Start und Ende der Meditation"

### Preview-Logik

1. **Separater Preview-Player** - Preview darf nicht den Haupt-Audio-Player blockieren
2. **Stop bei neuem Sound** - Vor jeder neuen Preview die vorherige stoppen (kein Overlap)
3. **Stop bei Dismiss** - Beim Schliessen des Settings-Sheets Preview stoppen

### AudioService API

Zwei neue Methoden fuer Preview-Funktion:
- `playGongPreview(soundId:)` - Spielt Vorschau, stoppt vorherige automatisch
- `stopGongPreview()` - Stoppt aktuelle Vorschau (idempotent)

Bestehende Methoden erweitern:
- `playStartGong(soundId:)` - War vorher ohne Parameter
- `playCompletionSound(soundId:)` - War vorher ohne Parameter

### Domain Model

`GongSound` als Value Object mit:
- `id: String` - Eindeutige ID (z.B. "classic-bowl")
- `filename: String` - Audio-Dateiname
- `name: LocalizedString` - Lokalisierter Name (DE/EN)

Statische Methoden:
- `allSounds` - Liste aller verfuegbaren Sounds
- `defaultSound` / `defaultSoundId` - Default-Wert
- `find(byId:)` - Optional, nil wenn nicht gefunden
- `findOrDefault(byId:)` - Gibt Default zurueck wenn nicht gefunden

---

## Hinweise

- `completion.mp3` wurde entfernt - Start/Ende-Gong nutzt jetzt die konfigurierbaren Sounds
- `interval.mp3` bleibt erhalten fuer den festen Intervall-Gong
- Default: "Classic Bowl" / "Klassisch"

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->

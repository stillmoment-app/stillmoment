# Ticket shared-051: Meditation Timer Presets & Custom Audio

**Status**: [x] SPLIT — Aufgeteilt in shared-061 bis shared-066
**Prioritaet**: MITTEL
**Aufwand**: iOS ~8 | Android ~8 (Gesamt, wird auf Sub-Tickets verteilt)
**Phase**: 3-Feature

---

## Was

Timer-Konfigurationen sollen als Presets gespeichert und schnell geladen werden koennen ("Meditation Timer Library"). Zusaetzlich sollen eigene Hintergrund-Sounds und Einleitungen importiert werden koennen.

## Warum

Die Timer-Konfiguration wird mit jedem Feature komplexer (Vorbereitung, Gong, Einleitung, Intervalle, Hintergrund). Wiederholtes Konfigurieren derselben Einstellungen ist muehsam. Presets ermoeglichen "Make it yours" ohne dass die Bedienung komplizierter wird — gute Presets statt zu viele Einstellungen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-050    |
| Android   | [ ]    | shared-050    |

---

## Design-Philosophie

**Trade-off: Flexibilitaet vs. Minimalismus.** Die App soll sich anfuehlen wie eine Pause, nicht wie ein Synthesizer-Cockpit.

Leitprinzipien:
- Timer-Screen bleibt der Startpunkt — Meditation starten ist maximal 1 Tap
- Presets sind Shortcuts, keine Pflicht — One-Shot-Konfiguration bleibt moeglich
- Neue User sehen keine zusaetzliche Komplexitaet (Presets erscheinen erst wenn man welche anlegt)
- Custom Audio ist ein Power-Feature, das sich dezent einordnet

---

## UX-Konzept

### Kern-Einsicht: Interaktionsmuster bestimmen die Struktur

| Audio-Typ              | Standalone? | Interaktion                        |
|------------------------|-------------|------------------------------------|
| Gefuehrte Meditationen | Ja          | Antippen → Abspielen               |
| Hintergrundklaenge     | Nein        | Nur als Teil einer Timer-Session   |
| Einleitungen           | Nein        | Nur als Teil einer Timer-Session   |

Hintergrundklaenge und Einleitungen sind **Konfiguration, kein Content**. Ein User tippt auf "Waldgeraeusche" und erwartet Abspielen — aber es ist kein eigenstaendiger Content. Deshalb gehoeren sie in Settings, nicht in einen Library-Tab.

### Tab-Struktur

```
Tab 1: TIMER
  Session starten & erleben
  Settings → Picker fuer Gong, Background, Introduction

Tab 2: MEDITATIONEN
  Wie heute: Antippen → Abspielen
  Nur standalone Content

Tab 3: EINSTELLUNGEN
  Theme, Appearance, Ueber
  Audio verwalten:
    ├─ Hintergrundklaenge (Import/Loeschen/Umbenennen)
    └─ Einleitungen (Import/Loeschen/Umbenennen)
```

### Timer Screen
- Horizontal scrollbare Preset-Chips unter dem Titel (nur sichtbar wenn Presets existieren)
- Tap auf Chip laedt die gespeicherte Konfiguration inkl. Dauer
- Settings-Icon oeffnet wie bisher die Einstellungen

### Timer Settings (Sheet)
- Progressive Disclosure: Top-Level zeigt Zusammenfassungen, Details in Sub-Screens
- Preset-Section oben: Aktives Preset waehlen, neues Preset anlegen
- "Aktuelle Einstellung" als Standard fuer One-Shot-Konfigurationen (kein Preset noetig)
- Aenderungen an einem aktiven Preset werden direkt gespeichert
- Sound-Picker referenzieren Content aus der Audio-Verwaltung in den Einstellungen

### Einstellungen-Tab: Audio-Verwaltung
- Eigener Bereich fuer Hintergrundklaenge und Einleitungen
- Import, Vorhoeren, Umbenennen, Loeschen — einheitliches Pattern fuer beide Typen
- Timer-Settings bleiben schlank: Nur Picker, kein Import-UI

### Content-Quellen

Es gibt zwei Quellen fuer Hintergrundklaenge und Einleitungen:

| Quelle | Beispiele | Verwaltung |
|--------|-----------|------------|
| **Mitgeliefert (Provided)** | Wald, Regen, Atem-Einleitung | Fest in der App, nicht loeschbar |
| **Vom User hochgeladen** | Eigene MP3s | Import, Umbenennen, Loeschen moeglich |

Beide Quellen erscheinen gemeinsam in den Timer-Settings-Pickern. In der Audio-Verwaltung (Einstellungen-Tab) sind nur die hochgeladenen Dateien editierbar — mitgelieferter Content wird dort angezeigt aber nicht veraenderbar.

### Verworfene Alternativen

**Library-Tab als Audio-Hub (verworfen):** Alle drei Audio-Typen in einem gemeinsamen Library-Tab. Verworfen weil Hintergrundklaenge und Einleitungen kein eigenstaendiger Content sind — unterschiedliches Interaktionsmuster fuehrt zu Verwirrung ("Warum kann ich Waldgeraeusche nicht abspielen?").

---

## Akzeptanzkriterien

### Presets (beide Plattformen)
- [ ] User kann aktuelle Timer-Konfiguration als Preset mit Name speichern
- [ ] User kann gespeichertes Preset laden und Meditation starten
- [ ] User kann Preset laden, Dauer anpassen und starten (ohne Preset zu veraendern)
- [ ] User kann Preset-Einstellungen bearbeiten (Aenderungen werden im Preset gespeichert)
- [ ] User kann Preset umbenennen
- [ ] User kann Preset loeschen
- [ ] One-Shot-Konfiguration ohne Preset bleibt moeglich
- [ ] Letztes Setup wird automatisch wiederhergestellt (wie bisher)
- [ ] Preset-Chips auf Timer Screen erscheinen erst wenn mindestens ein Preset existiert

### Custom Hintergrund-Sounds (beide Plattformen)
- [ ] User kann eigene Audio-Dateien als Hintergrund-Sound importieren (MP3, M4A, WAV)
- [ ] Importierte Sounds erscheinen in der Hintergrund-Sound-Auswahl
- [ ] User kann importierten Sound vorhoeren
- [ ] User kann importierten Sound umbenennen
- [ ] User kann importierten Sound loeschen
- [ ] Beim Loeschen: Warnung wenn Sound in Presets verwendet wird

### Custom Einleitungen (beide Plattformen)
- [ ] User kann eigene Audio-Dateien als Einleitung importieren
- [ ] Importierte Einleitungen erscheinen in der Einleitungs-Auswahl mit automatisch erkannter Dauer
- [ ] User kann importierte Einleitung vorhoeren
- [ ] User kann importierte Einleitung umbenennen
- [ ] User kann importierte Einleitung loeschen
- [ ] Beim Loeschen: Warnung wenn Einleitung in Presets verwendet wird

### Edge Cases
- [ ] Preset das auf geloeschten Custom Sound verweist: Graceful Fallback auf "Stille"
- [ ] Preset das auf geloeschte Einleitung verweist: Graceful Fallback auf "Keine Einleitung"
- [ ] Dateiformate die nicht unterstuetzt werden: Verstaendliche Fehlermeldung

### Allgemein
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Presets und Custom Audio bleiben nach App-Neustart erhalten
- [ ] Accessibility: Alle neuen Elemente mit Labels und Hints

### Tests
- [ ] Unit Tests iOS (Preset-Persistierung, Audio-Import, Edge Cases)
- [ ] Unit Tests Android (Preset-Persistierung, Audio-Import, Edge Cases)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (neue Begriffe: Preset, Custom Sound)
- [ ] Audio-System Doku aktualisieren

---

## Manueller Test

### Preset-Flow
1. Timer oeffnen, Settings oeffnen
2. Konfiguration anpassen (z.B. 15 Min, Waldgeraeusche, Atem-Einleitung, Intervall alle 5 Min)
3. "Als Preset speichern", Name: "Morgenritual"
4. Settings schliessen
5. Erwartung: Preset-Chip "Morgenritual" erscheint auf Timer Screen
6. Dauer aendern auf 20 Min, Meditation starten
7. Erwartung: Meditation laeuft mit Preset-Einstellungen aber 20 Min Dauer

### Custom Sound Flow
1. Settings oeffnen, Hintergrund-Sounds
2. "+" tippen, Audio-Datei aus Dateien-App waehlen
3. Erwartung: Sound erscheint in der Liste, kann vorgehoert werden
4. Sound in einer Konfiguration verwenden, Meditation starten
5. Erwartung: Custom Sound spielt als Hintergrund

### Loeschung mit Warnung
1. Custom Sound in einem Preset verwenden
2. Custom Sound loeschen
3. Erwartung: Warnung "Wird in 1 Preset verwendet"
4. Trotzdem loeschen bestaetigen
5. Preset oeffnen
6. Erwartung: Hintergrund-Sound steht auf "Stille"

---

## Hinweise

- Preset Import/Export (Teilen mit Freunden) bewusst NICHT eingeplant — fragwuerdig ob das zum Minimalismus der App passt
- "Preset duplizieren" und "Preset-Reihenfolge sortieren" sind Nice-to-haves, kein Must
- Die bestehende Timer-Konfiguration (ohne Presets) muss weiterhin funktionieren — kein Breaking Change fuer bestehende User

---

## Umsetzungs-Aufteilung

Dieses Konzept-Ticket wird vor der Umsetzung in Einzel-Tickets aufgeteilt (analog shared-038 → 043-045).

### Phase 1: Audio-Verwaltung & Settings-Umbau (Infrastruktur)

Loest das echte Problem: Wo verwalte ich mehrere Audio-Typen?

1. **Settings Progressive Disclosure** — Timer-Settings-Sheet mit Navigation-Hierarchie umbauen
2. **Audio-Verwaltung in Einstellungen** — Hintergrundklaenge und Einleitungen importieren/verwalten
3. **Custom Background Sounds** — Import, Vorhoeren, Umbenennen, Loeschen
4. **Custom Introductions** — Import, Vorhoeren, Umbenennen, Loeschen

### Phase 2: Timer Presets (Convenience)

Erst wenn Phase 1 steht und die saubere Trennung zwischen Content (Audio-Verwaltung) und Konfiguration (Timer-Settings) etabliert ist.

5. **Timer Presets** — Presets speichern, laden, verwalten, Preset-Chips auf Timer Screen

Phase 2 wird einfacher zu bauen, weil Phase 1 die Grundlagen schafft.

---

## Referenz

- Bestehendes Settings-UI als Ausgangspunkt
- Bestehende Introduction- und BackgroundSound-Models als Basis fuer Custom Audio
- Guided Meditation Import-Flow als Pattern fuer Audio-Import

# Ticket shared-065: Custom Audio Import (Soundscapes und Attunements)

**Status**: [~] IN PROGRESS
**Prioritaet**: MITTEL
**Aufwand**: iOS ~5 | Android ~5
**Phase**: 3-Feature
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

User koennen eigene Audio-Dateien als Hintergrundklaenge (Soundscapes) und Einstimmungen (Attunements) importieren, auswaehlen und loeschen. Import-UI lebt innerhalb der Praxis-Editor Sub-Screens.

**Abgrenzung:** Hintergrundklaenge spielen als Loop **waehrend** der Meditation. Einstimmungen spielen **einmalig** nach dem Start-Gong **vor** der stillen Phase.

## Warum

Die App soll mit eigenen MP3s personalisierbar sein — nicht nur gefuehrte Meditationen, sondern auch Soundscapes und Einstimmungen (Attunements). "Make it yours" ohne Server-Abhaengigkeit, passend zur Privatsphaerenphilosophie.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-064    |
| Android   | [ ]    | shared-064    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

#### Domain & Persistenz
- [x] CustomAudioFile-Modell: id, name, filename, duration (automatisch erkannt), type (soundscape/attunement), dateAdded
- [x] CustomAudioRepository: importieren, alle laden (nach Typ), loeschen
- [x] Importierte Dateien werden in den lokalen App-Speicher kopiert (nicht nur referenziert)
- [x] Unterstuetzte Formate: MP3, M4A, WAV

#### Import-Flow
- [x] "Eigene Datei importieren" Button in Soundscape-Sub-Screen und Einstimmung-Sub-Screen
- [x] Oeffnet nativen Document Picker (iOS) / SAF File Picker (Android)
- [x] Dateiname (ohne Extension) als initialer Name
- [x] Dauer wird automatisch aus der Audio-Datei erkannt und angezeigt
- [x] Importierte Datei wird sofort in der Liste angezeigt

#### Auswahl-Screens (Erweiterung von shared-064)
- [x] Sektion "Meine Klaenge" / "Meine Einstimmungen" unterhalb der mitgelieferten Sounds
- [x] Leerer Zustand: "Keine eigenen Dateien importiert"
- [x] Checkmark bei ausgewaehltem Sound (mitgeliefert ODER custom)
- [x] Loeschen-Button pro importierter Datei (Muelleimer-Icon)

#### Loeschen
- [x] Bestaetigungsdialog beim Loeschen
- [x] Warnung wenn Datei in einer oder mehreren Praxis-Presets verwendet wird ("Wird in X Praxis verwendet")
- [x] Nach Loeschen: betroffene Praxis-Presets fallen zurueck auf "Stille" (Soundscape) bzw. "Keine Einstimmung" (Attunement)
- [x] Datei wird aus dem lokalen App-Speicher entfernt

#### Edge Cases
- [x] Nicht unterstuetzte Formate: verstaendliche Fehlermeldung
- [x] Doppelter Import derselben Datei: erlaubt (separate Kopie)
- [x] Dauer-Erkennung fehlgeschlagen: Import trotzdem erlauben, Dauer als "Unbekannt" anzeigen

#### Allgemein
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [x] Accessibility: Labels und Hints

### Tests
- [x] Unit Tests iOS (Import, Loeschen, Fallback, Modell)
- [ ] Unit Tests Android (Import, Loeschen, Fallback, Modell)

### Dokumentation
- [x] CHANGELOG.md
- [x] Audio-System Doku aktualisieren

---

## Manueller Test

### Import
1. Praxis-Editor → Audio & Klaenge → Soundscape
2. "Eigene Datei importieren" → Datei-Picker → MP3 auswaehlen
3. Sound erscheint unter "Meine Klaenge" mit Name und Dauer
4. Sound auswaehlen (Checkmark) → Zurueck zum Editor → "Fertig"
5. Meditation starten → eigener Soundscape spielt als Loop

### Loeschen mit Warnung
1. Custom Soundscape in Praxis "Standard" verwenden
2. Neue Praxis "Abend" anlegen, denselben Soundscape verwenden
3. Soundscape loeschen → Warnung "Wird in 2 Praxis verwendet"
4. Trotzdem loeschen → Soundscape weg
5. Praxis "Standard" oeffnen → Soundscape steht auf "Stille"
6. Praxis "Abend" oeffnen → Soundscape steht auf "Stille"

### Einstimmung (Attunement)
1. Praxis-Editor → Audio & Klaenge → Einstimmung
2. "Eigene Datei importieren" → Audio-Datei waehlen
3. Datei erscheint unter "Meine Einstimmungen" mit Name und erkannter Dauer
4. Auswaehlen → Meditation starten → eigene Einstimmung spielt einmalig nach Start-Gong, dann stille Phase

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (SelectIntroScreen, SelectBackgroundScreen — "Eigene Datei importieren" Buttons)
- Bestehender Import-Flow fuer gefuehrte Meditationen als Pattern (Document Picker, Datei kopieren)
- iOS: `ios/StillMoment/Infrastructure/` (bestehende File-Import-Logik)
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/` (bestehende SAF-Integration)

---

## Hinweise

- Gleiche Import-Patterns wie gefuehrte Meditationen verwenden (Document Picker + lokale Kopie). Die Infrastruktur existiert bereits — wiederverwenden, nicht neu bauen.
- Soundscapes und Einstimmungen (Attunements) getrennt speichern (verschiedene Verzeichnisse / Typen), auch wenn das Modell aehnlich ist.
- Vorhoer-Funktion fuer Custom Sounds ist bewusst NICHT Teil dieses Tickets — kann als Follow-up ergaenzt werden.
- Umbenennen von Custom Sounds ist bewusst NICHT Teil dieses Tickets — reduziert Komplexitaet. Dateiname ist der initiale Name.

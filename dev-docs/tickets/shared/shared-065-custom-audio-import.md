# Ticket shared-065: Custom Audio Import (Hintergrundklaenge und Einstimmungen)

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~5 | Android ~5
**Phase**: 3-Feature
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

User koennen eigene Audio-Dateien als Hintergrundklaenge und Einstimmungen importieren, auswaehlen und loeschen. Import-UI lebt innerhalb der Praxis-Editor Sub-Screens.

## Warum

Die App soll mit eigenen MP3s personalisierbar sein — nicht nur gefuehrte Meditationen, sondern auch Ambient Sounds und Einstimmungen. "Make it yours" ohne Server-Abhaengigkeit, passend zur Privatsphaerenphilosophie.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-064    |
| Android   | [ ]    | shared-064    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

#### Domain & Persistenz
- [ ] CustomAudioFile-Modell: id, name, filename, duration (automatisch erkannt), type (background/introduction), dateAdded
- [ ] CustomAudioRepository: importieren, alle laden (nach Typ), loeschen
- [ ] Importierte Dateien werden in den lokalen App-Speicher kopiert (nicht nur referenziert)
- [ ] Unterstuetzte Formate: MP3, M4A, WAV

#### Import-Flow
- [ ] "Eigene Datei importieren" Button in Hintergrundklang-Sub-Screen und Einstimmung-Sub-Screen
- [ ] Oeffnet nativen Document Picker (iOS) / SAF File Picker (Android)
- [ ] Dateiname (ohne Extension) als initialer Name
- [ ] Dauer wird automatisch aus der Audio-Datei erkannt und angezeigt
- [ ] Importierte Datei wird sofort in der Liste angezeigt

#### Auswahl-Screens (Erweiterung von shared-064)
- [ ] Sektion "Meine Klaenge" / "Meine Einstimmungen" unterhalb der mitgelieferten Sounds
- [ ] Leerer Zustand: "Keine eigenen Dateien importiert"
- [ ] Checkmark bei ausgewaehltem Sound (mitgeliefert ODER custom)
- [ ] Loeschen-Button pro importiertem Sound (Muelleimer-Icon)

#### Loeschen
- [ ] Bestaetigungsdialog beim Loeschen
- [ ] Warnung wenn Sound in einer oder mehreren Praxis-Presets verwendet wird ("Wird in X Praxis verwendet")
- [ ] Nach Loeschen: betroffene Praxis-Presets fallen zurueck auf "Stille" (Hintergrund) bzw. "Keine Einstimmung"
- [ ] Datei wird aus dem lokalen App-Speicher entfernt

#### Edge Cases
- [ ] Nicht unterstuetzte Formate: verstaendliche Fehlermeldung
- [ ] Doppelter Import derselben Datei: erlaubt (separate Kopie)
- [ ] Dauer-Erkennung fehlgeschlagen: Import trotzdem erlauben, Dauer als "Unbekannt" anzeigen

#### Allgemein
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Accessibility: Labels und Hints

### Tests
- [ ] Unit Tests iOS (Import, Loeschen, Fallback, Modell)
- [ ] Unit Tests Android (Import, Loeschen, Fallback, Modell)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] Audio-System Doku aktualisieren

---

## Manueller Test

### Import
1. Praxis-Editor → Audio & Klaenge → Hintergrundklang
2. "Eigene Datei importieren" → Datei-Picker → MP3 auswaehlen
3. Sound erscheint unter "Meine Klaenge" mit Name und Dauer
4. Sound auswaehlen (Checkmark) → Zurueck zum Editor → "Fertig"
5. Meditation starten → eigener Background spielt

### Loeschen mit Warnung
1. Custom Sound in Praxis "Standard" verwenden
2. Neue Praxis "Abend" anlegen, denselben Sound verwenden
3. Sound loeschen → Warnung "Wird in 2 Praxis verwendet"
4. Trotzdem loeschen → Sound weg
5. Praxis "Standard" oeffnen → Hintergrundklang steht auf "Stille"
6. Praxis "Abend" oeffnen → Hintergrundklang steht auf "Stille"

### Einstimmung
1. Praxis-Editor → Audio & Klaenge → Einstimmung
2. "Eigene Datei importieren" → Audio-Datei waehlen
3. Datei erscheint unter "Meine Einstimmungen" mit Name und erkannter Dauer
4. Auswaehlen → Meditation starten → eigene Einstimmung spielt nach Start-Gong

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (SelectIntroScreen, SelectBackgroundScreen — "Eigene Datei importieren" Buttons)
- Bestehender Import-Flow fuer gefuehrte Meditationen als Pattern (Document Picker, Datei kopieren)
- iOS: `ios/StillMoment/Infrastructure/` (bestehende File-Import-Logik)
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/` (bestehende SAF-Integration)

---

## Hinweise

- Gleiche Import-Patterns wie gefuehrte Meditationen verwenden (Document Picker + lokale Kopie). Die Infrastruktur existiert bereits — wiederverwenden, nicht neu bauen.
- Hintergrundklaenge und Einstimmungen getrennt speichern (verschiedene Verzeichnisse / Typen), auch wenn das Modell aehnlich ist.
- Vorhoer-Funktion fuer Custom Sounds ist bewusst NICHT Teil dieses Tickets — kann als Follow-up ergaenzt werden.
- Umbenennen von Custom Sounds ist bewusst NICHT Teil dieses Tickets — reduziert Komplexitaet. Dateiname ist der initiale Name.

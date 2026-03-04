# Ticket shared-073: Datei-Import mit Typ-Auswahl

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~M | Android ~M
**Phase**: 3-Feature

---

## Was

Beim Teilen einer Audio-Datei mit der App soll der User waehlen koennen, ob die Datei als Gefuehrte Meditation, Klangkulisse oder Einstimmung importiert wird. Nach der Auswahl navigiert die App zur passenden Stelle und oeffnet dort die Edit-View fuer die importierte Datei.

## Warum

Aktuell werden geteilte Audio-Dateien immer als Gefuehrte Meditation importiert. Dateien koennten aber auch Klangkulissen (Hintergrund-Loops) oder Einstimmungen (vor der Meditation) sein. Die Infrastruktur fuer Custom Soundscapes und Custom Attunements existiert bereits, wird aber vom Share-Flow nicht genutzt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Typ-Auswahl-Sheet erscheint beim Teilen einer Audio-Datei
- [ ] Drei Optionen: Gefuehrte Meditation, Klangkulisse, Einstimmung
- [ ] Bestehende Icons konsistent verwendet (play.circle / PlayCircle, waveform.circle / Audiotrack, wind / entsprechendes Material Icon)
- [ ] Nach Typ-Auswahl Navigation zur richtigen Stelle mit geoeffneter Edit-View
- [ ] Metadaten (Name, ggf. Teacher) aus ID3-Tags vorausgefuellt
- [ ] Laufende Meditation (Timer oder Guided) wird beim File-Share abgebrochen (kein Completion-Screen)
- [ ] Abbrechen/Wegwischen verwirft die Datei
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Fachliche Testszenarien

### Import-Routing
1. Audio-Datei geteilt, Typ "Gefuehrte Meditation" gewaehlt → Datei erscheint in der Meditationsliste
2. Audio-Datei geteilt, Typ "Klangkulisse" gewaehlt → Datei erscheint in der Klangkulissen-Auswahl
3. Audio-Datei geteilt, Typ "Einstimmung" gewaehlt → Datei erscheint in der Einstimmungs-Auswahl

### Metadaten
4. ID3-Tags vorhanden → Name und Kuenstler sind in der Edit-View vorausgefuellt
5. Keine ID3-Tags → Dateiname wird als Name verwendet

### Abbruch
6. Typ-Auswahl abgebrochen → keine Datei importiert, kein neuer Eintrag

### Laufende Meditation
7. Timer-Meditation laeuft + Datei geteilt → Meditation beendet, Import-Flow startet
8. Gefuehrte Meditation laeuft + Datei geteilt → Meditation beendet, Import-Flow startet

### Navigation
9. Nach Import als Klangkulisse → Edit-View in Klangkulissen-Auswahl geoeffnet
10. Nach Import als Einstimmung → Edit-View in Einstimmungs-Auswahl geoeffnet
11. Nach Import als Gefuehrte Meditation → Edit-View in Meditationsliste geoeffnet

### Duplikat-Erkennung
12. Dieselbe Datei erneut geteilt → Hinweis "Bereits importiert"

### Ungueltiges Format
13. Nicht-Audio-Datei geteilt → Fehlermeldung, kein Import

### Mehrfach-Import verschiedener Typen
14. Dieselbe Datei als Klangkulisse UND als Gefuehrte Meditation importiert → beide Eintraege existieren unabhaengig voneinander

---

## Manueller Test

1. Audio-Datei aus Dateien-App mit Still Moment teilen
2. Typ-Auswahl-Sheet erscheint mit drei Optionen
3. "Klangkulisse" waehlen
4. Erwartung: App navigiert zur Klangkulissen-Auswahl, Edit-View mit vorausgefuelltem Namen oeffnet sich
5. Namen bestaetigen
6. Erwartung: Neue Klangkulisse erscheint in der Liste

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Auswahl-UI | Half-Sheet (Drag Indicator) | Bottom Sheet (Handle) |
| Icons | SF Symbols (play.circle, waveform.circle, wind) | Material Icons (PlayCircle, Audiotrack, entsprechend) |
| Abbruch | Wegwischen oder "Abbrechen" | Wegwischen oder "Abbrechen" |

---

## Referenz

- iOS: Aktueller Import-Flow in `DocumentPicker` und `GuidedMeditationService`
- Android: Aktueller Import-Flow in `FileOpenHandler` und `GuidedMeditationRepository`
- Custom Audio Import: `CustomAudioRepository` (beide Plattformen, shared-065)

---

## Hinweise

- Die Custom-Audio-Infrastruktur (CustomAudioFile mit Typ SOUNDSCAPE/ATTUNEMENT) existiert bereits auf beiden Plattformen (shared-065)
- Android hat bereits Duplikat-Erkennung in FileOpenHandler (gleicher Dateiname + Dateigroesse)
- iOS hat noch keine Duplikat-Erkennung — muss ergaenzt werden
- Meditation-Abbruch: Kein Bestaetigungs-Dialog — die Aktion selbst ist die Entscheidung

---

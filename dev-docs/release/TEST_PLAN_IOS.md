# iOS Release Test-Plan

**Typ**: Manueller Test-Plan (vor jedem Release durchfuehren)
**Dauer**: ~30-45 Minuten
**Voraussetzung**: Echtes iOS-Geraet (kein Simulator)

---

## Hinweis

Dieser Test-Plan enthaelt nur Punkte, die **nicht automatisiert** verifiziert werden koennen.
Automatisierte Tests decken bereits ab:
- Timer State-Uebergaenge und UI-Zustaende (Unit + UI Tests)
- Settings Sheet Anzeige und Toggle-Interaktion
- Timer Countdown und Zeitformat
- Tab Navigation (Timer ↔ Library)
- Library Empty State UI
- Timer State-Erhaltung bei Tab-Wechsel
- Audio Coordination Logik
- ViewModel und Domain-Logik

---

## 1. Audio-Wiedergabe

### 1.1 Timer Audio
- [ ] Start Gong wird hoerbar gespielt (nach Countdown)
- [ ] Completion Gong wird hoerbar gespielt
- [ ] Background Audio (Silent) ist leise hoerbar
- [ ] Background Audio (Forest) spielt Waldgeraeusche
- [ ] Interval Gongs werden zum richtigen Zeitpunkt gespielt
- [ ] Fade-In bei Background Audio Start (2 Sekunden)

### 1.2 Einstimmung (Attunement)
- [ ] Einstimmung "Atemuebung" wird nach Start-Gong hoerbar abgespielt
- [ ] Einstimmung spielt mit leicht reduzierter Lautstaerke (0.9)
- [ ] Nach Einstimmung startet Hintergrund-Sound (falls konfiguriert)
- [ ] Timer-Countdown laeuft waehrend der Einstimmung weiter
- [ ] Abbruch (Close) waehrend Einstimmung beendet Meditation sofort
- [ ] Ohne Einstimmung: Verhalten wie bisher (keine Regression)

### 1.3 Einstimmung mit kurzer Meditationszeit
- [ ] Meditationszeit 1 Min + Einstimmung 1:35: Einstimmung wird abgeschnitten, End-Gong spielt

### 1.4 Guided Meditation Audio
- [ ] MP3-Wiedergabe funktioniert
- [ ] Lautstaerke ist angemessen
- [ ] Seek Slider aendert Position hoerbar

---

## 2. Background & Lock Screen

### 2.1 Timer
- [ ] Background Audio laeuft bei gesperrtem Bildschirm weiter
- [ ] Completion Gong spielt bei gesperrtem Bildschirm
- [ ] Interval Gongs spielen bei gesperrtem Bildschirm
- [ ] Einstimmung spielt bei gesperrtem Bildschirm weiter
- [ ] Uebergang Einstimmung → stille Meditation (inkl. Hintergrund-Sound) funktioniert bei gesperrtem Bildschirm

### 2.2 Guided Meditation
- [ ] Audio laeuft bei gesperrtem Bildschirm weiter
- [ ] Now Playing Info auf Lock Screen sichtbar
- [ ] Play/Pause Controls auf Lock Screen funktionieren
- [ ] Skip Forward/Backward auf Lock Screen funktionieren
- [ ] Control Center zeigt Now Playing Info

---

## 3. System-Interaktionen

### 3.1 Document Picker
- [ ] Import-Button oeffnet System Document Picker
- [ ] MP3-Datei kann ausgewaehlt werden
- [ ] Metadaten werden nach Import angezeigt
- [ ] Security-Scoped Bookmark funktioniert (Playback nach App-Neustart)

### 3.2 Unterbrechungen
- [ ] Eingehender Anruf pausiert Audio
- [ ] Nach Anruf-Ende: Audio kann fortgesetzt werden
- [ ] Siri-Aktivierung pausiert Audio
- [ ] App-Minimieren: Timer Audio laeuft weiter
- [ ] App-Kill: Sauberer Neustart ohne Crash
- [ ] Anruf waehrend Einstimmung: Einstimmung setzt nach Unterbrechung fort, Timer laeuft weiter

### 3.3 Kopfhoerer
- [ ] Play/Pause ueber Kopfhoerer-Taste (kabelgebunden)
- [ ] Play/Pause ueber AirPods

---

## 4. Lokalisierung

### 4.1 Deutsch (Geraetesprache: Deutsch)
- [ ] Alle UI-Texte auf Deutsch
- [ ] Affirmationen auf Deutsch
- [ ] Empty State Text auf Deutsch
- [ ] Tab-Labels auf Deutsch
- [ ] Einstimmungs-Section "Einstimmung" sichtbar in Timer-Settings
- [ ] Einstimmung "Atemuebung" in Picker verfuegbar

### 4.2 Englisch (Geraetesprache: Englisch)
- [ ] Alle UI-Texte auf Englisch
- [ ] Affirmationen auf Englisch
- [ ] Empty State Text auf Englisch
- [ ] Tab-Labels auf Englisch
- [ ] Einstimmungs-Section NICHT sichtbar (keine englischen Einstimmungen verfuegbar)
- [ ] Gespeicherte Einstimmung faellt auf "Keine" zurueck

---

## 5. Accessibility (VoiceOver)

- [ ] Timer Screen: Alle Elemente werden vorgelesen
- [ ] Duration Picker: Wert wird angekuendigt
- [ ] Timer Display: Verbleibende Zeit wird vorgelesen
- [ ] Library Screen: Liste navigierbar
- [ ] Player Screen: Controls bedienbar
- [ ] Seek Slider: Per Geste steuerbar
- [ ] Settings Sheet: Toggle und Picker bedienbar

---

## 6. Performance

- [ ] App-Start in <2 Sekunden (Cold Start)
- [ ] Keine Haenger waehrend Tests
- [ ] Keine Crashes waehrend Tests
- [ ] Nach 10 Min Nutzung: Kein spuerbarer Lag
- [ ] Batterieverbrauch akzeptabel bei Background Audio

---

## Bekannte Limitierungen

1. _____
2. _____

---

## Nach dem Test

Nach erfolgreichem Test weiter mit `RELEASE_GUIDE.md`.

---

## Sign-Off

| Tester | Datum | Version | Ergebnis |
|--------|-------|---------|----------|
| ______ | ______ | ______ | PASS / FAIL |

**Notizen:**

_

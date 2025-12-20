# Android Release Test-Plan

**Typ**: Manueller Test-Plan (vor jedem Release durchfuehren)
**Dauer**: ~30-45 Minuten
**Voraussetzung**: Echtes Android-Geraet (kein Emulator)

---

## Hinweis

Dieser Test-Plan enthaelt nur Punkte, die **nicht automatisiert** verifiziert werden koennen.
Automatisierte Tests decken bereits ab:
- Timer State-Uebergaenge und UI-Zustaende
- Settings Sheet Anzeige und Persistenz
- Library Empty State und FAB
- Player Controls Anzeige
- Tab Navigation
- Audio Coordination Logik

---

## 1. Audio-Wiedergabe

### 1.1 Timer Audio
- [ ] Completion Gong wird hoerbar gespielt
- [ ] Background Audio (Silent) ist leise hoerbar
- [ ] Background Audio (Forest) spielt Waldgeraeusche
- [ ] Interval Gongs werden zum richtigen Zeitpunkt gespielt

### 1.2 Guided Meditation Audio
- [ ] MP3-Wiedergabe funktioniert
- [ ] Lautstaerke ist angemessen
- [ ] Seek Slider aendert Position hoerbar

---

## 2. Background & Lock Screen

### 2.1 Timer
- [ ] Background Audio laeuft bei gesperrtem Bildschirm weiter
- [ ] Completion Gong spielt bei gesperrtem Bildschirm

### 2.2 Guided Meditation
- [ ] Audio laeuft bei gesperrtem Bildschirm weiter
- [ ] Now Playing Info auf Lock Screen sichtbar
- [ ] Play/Pause Controls auf Lock Screen funktionieren
- [ ] Notification wird angezeigt

---

## 3. System-Interaktionen

### 3.1 Document Picker
- [ ] FAB oeffnet System Document Picker
- [ ] MP3-Datei kann ausgewaehlt werden
- [ ] Metadaten werden nach Import angezeigt

### 3.2 Unterbrechungen
- [ ] Eingehender Anruf pausiert Audio
- [ ] Nach Anruf-Ende: Audio kann fortgesetzt werden
- [ ] App-Minimieren: Audio laeuft weiter
- [ ] App-Kill: Sauberer Neustart ohne Crash

---

## 4. Lokalisierung

### 4.1 Deutsch (Geraetesprache: Deutsch)
- [ ] Alle UI-Texte auf Deutsch
- [ ] Affirmationen auf Deutsch
- [ ] Empty State Text auf Deutsch

### 4.2 Englisch (Geraetesprache: Englisch)
- [ ] Alle UI-Texte auf Englisch
- [ ] Affirmationen auf Englisch
- [ ] Empty State Text auf Englisch

---

## 5. Accessibility (TalkBack)

- [ ] Timer Screen: Alle Elemente werden vorgelesen
- [ ] Library Screen: Liste navigierbar
- [ ] Player Screen: Controls bedienbar
- [ ] Seek Slider: Per Geste steuerbar

---

## 6. Performance

- [ ] App-Start in <2 Sekunden (Cold Start)
- [ ] Keine ANR waehrend Tests
- [ ] Keine Crashes waehrend Tests
- [ ] Nach 10 Min Nutzung: Kein spuerbarer Lag

---

## Bekannte Limitierungen

1. _____
2. _____

---

## Release Checkliste

Nach erfolgreichem Test:

- [ ] Version erhoehen in `build.gradle.kts`
- [ ] CHANGELOG.md aktualisieren
- [ ] `./gradlew assembleRelease`
- [ ] APK signieren

---

## Sign-Off

| Tester | Datum | Version | Ergebnis |
|--------|-------|---------|----------|
| ______ | ______ | ______ | PASS / FAIL |

**Notizen:**

_

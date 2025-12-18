# Ticket android-013: Final Integration Test

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein (~1-2h)
**Abhaengigkeiten**: Alle vorherigen Tickets
**Phase**: 5-QA

---

## Beschreibung

Abschliessender Integrationstest aller Features um sicherzustellen, dass alles zusammen funktioniert. Manueller Test-Durchlauf mit Checkliste.

---

## Akzeptanzkriterien

- [ ] Alle Features funktionieren zusammen
- [ ] Keine Regressionen
- [ ] Performance ist akzeptabel
- [ ] Keine Memory Leaks
- [ ] Alle Sprachen funktionieren
- [ ] App ist bereit fuer Beta/Release

### Dokumentation (Final Review)
- [ ] README.md: Android Feature-Liste aktuell
- [ ] CLAUDE.md: Android-Sektion vollstaendig und aktuell
- [ ] CHANGELOG.md: Alle Aenderungen dokumentiert
- [ ] dev-docs/tickets/INDEX.md: Alle Tickets auf [x] DONE

---

## Test-Checkliste

### 1. Timer Feature

#### 1.1 Grundfunktion
- [ ] Duration Picker zeigt 1-60 Minuten
- [ ] Start-Button startet Countdown (15s)
- [ ] Countdown-Animation und Affirmation angezeigt
- [ ] Nach Countdown: Timer laeuft
- [ ] Progress Ring aktualisiert sich
- [ ] Pause funktioniert
- [ ] Resume funktioniert
- [ ] Reset funktioniert
- [ ] Completion Gong wird gespielt

#### 1.2 Settings
- [ ] Settings Sheet oeffnet sich
- [ ] Background Sound waehlbar (Silent/Forest)
- [ ] Interval Gongs aktivierbar
- [ ] Interval (3/5/10 min) waehlbar
- [ ] Settings werden gespeichert
- [ ] Settings persistieren nach App-Neustart

#### 1.3 Background Audio
- [ ] Background Audio startet nach Countdown
- [ ] Audio laeuft bei gesperrtem Bildschirm
- [ ] Audio stoppt bei Reset
- [ ] Interval Gongs werden gespielt

### 2. Guided Meditations Feature

#### 2.1 Library
- [ ] Empty State wird angezeigt
- [ ] Import FAB oeffnet Document Picker
- [ ] MP3 kann importiert werden
- [ ] Metadaten werden extrahiert (Titel, Artist)
- [ ] Meditation erscheint in Liste
- [ ] Gruppierung nach Teacher funktioniert
- [ ] Edit Sheet oeffnet sich
- [ ] Metadaten koennen bearbeitet werden
- [ ] Swipe-to-Delete funktioniert
- [ ] Importierte Meditationen persistieren

#### 2.2 Player
- [ ] Player oeffnet sich bei Klick
- [ ] Meditation-Info wird angezeigt
- [ ] Play startet Wiedergabe
- [ ] Pause pausiert Wiedergabe
- [ ] Seek Slider funktioniert
- [ ] Progress wird aktualisiert
- [ ] Zurueck-Navigation funktioniert

#### 2.3 Lock Screen (Ticket android-010)
- [ ] Now Playing Info auf Lock Screen
- [ ] Play/Pause Controls funktionieren
- [ ] Notification wird angezeigt

### 3. Navigation

- [ ] Bottom Navigation angezeigt
- [ ] Timer Tab aktiv beim Start
- [ ] Wechsel zu Library Tab
- [ ] Wechsel zurueck zu Timer Tab
- [ ] State bleibt bei Tab-Wechsel erhalten
- [ ] Player versteckt Bottom Navigation
- [ ] Zurueck von Player zeigt Bottom Navigation

### 4. Audio Coordination

- [ ] Timer Audio laeuft
- [ ] Wechsel zu Library → Timer Audio laeuft weiter
- [ ] Start Guided Meditation → Timer Audio stoppt
- [ ] Meditation Audio spielt
- [ ] Zurueck zu Timer → Timer kann neu gestartet werden

### 5. Lokalisierung

#### 5.1 Englisch
- [ ] Alle UI-Texte auf Englisch
- [ ] Affirmationen auf Englisch
- [ ] Tab-Labels auf Englisch

#### 5.2 Deutsch
- [ ] Alle UI-Texte auf Deutsch
- [ ] Affirmationen auf Deutsch
- [ ] Tab-Labels auf Deutsch

### 6. Accessibility

- [ ] TalkBack navigiert alle Screens
- [ ] Alle Buttons werden vorgelesen
- [ ] Progress wird angekuendigt
- [ ] Slider ist bedienbar

### 7. Performance & Stabilitaet

- [ ] App startet in <2 Sekunden
- [ ] Keine ANR (App Not Responding)
- [ ] Keine Crashes waehrend Tests
- [ ] Speicherverbrauch stabil (kein Leak)
- [ ] Battery Drain akzeptabel

### 8. Edge Cases

- [ ] App-Minimieren waehrend Timer → Audio laeuft
- [ ] App-Kill waehrend Timer → Sauberer Neustart
- [ ] Rotation (falls unterstuetzt)
- [ ] Eingehender Anruf → Audio pausiert
- [ ] Nach Anruf → Audio resumiert (wenn konfiguriert)

---

## Performance-Metriken

```bash
# Memory Usage pruefen
adb shell dumpsys meminfo com.stillmoment

# Battery Stats
adb shell dumpsys batterystats --reset
# ... App verwenden ...
adb shell dumpsys batterystats com.stillmoment
```

---

## Bekannte Limitierungen

Dokumentiere hier bekannte Einschraenkungen oder offene Issues:

1. _____
2. _____
3. _____

---

## Release Checkliste

Nach erfolgreichem Integration Test:

- [ ] Version erhoehen in `build.gradle.kts`
- [ ] CHANGELOG.md aktualisieren
- [ ] Release Build erstellen: `./gradlew assembleRelease`
- [ ] APK signieren
- [ ] Play Store Submission vorbereiten
- [ ] Screenshots fuer Store erstellen

---

## Sign-Off

| Tester | Datum | Ergebnis |
|--------|-------|----------|
| ______ | ______ | PASS / FAIL |

### Kommentare

_Platz fuer Notizen waehrend des Tests_

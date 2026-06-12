# Ticket shared-109: Waveform Player „Tonkopf"

**Status**: [ ] TODO
**Plan (iOS)**: [Implementierungsplan](../plans/shared-109-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Hoch — kontinuierlich scrollendes Canvas-Rendering (gecachte Waveform), Drag-Scrub mit Pausier-/Fortsetz-Logik, Anbindung an echte Audio-Position als Source of Truth, korrektes Fenster-Mapping bei gesetztem Trim. Risiko liegt im fluessigen Scrollen ohne Akku-/Performance-Probleme und in der Accessibility (Welle dekorativ, Scrub als Slider).
**Phase**: 3-Feature

---

## Was

Der Wiedergabe-Screen einer gefuehrten Meditation wird zum „Tonkopf"-Waveform-Player: Statt des bisherigen Atemkreises zeigt die Playing-Phase die echte Waveform der Audiodatei, die an einer festen, leuchtenden Jetzt-Linie in der Bildschirmmitte vorbeiscrollt. Gespult wird durch direktes Ziehen der Welle — die `±10s`-Logik und der Atemkreis-Player entfallen in der Wiedergabe. Design-Vorlage: `handoffs/design_handoff_waveform_player` (high-fidelity, pixelgenau nachzubauen).

## Warum

Eine gesprochene Meditation soll auf den ersten Blick als Audio-Sitzung erkennbar sein — nicht als generischer Timer. Die Welle macht das unverkennbar, und das direkte Ziehen ist eine intuitivere, ruhigere Geste als Buttons. So findet man eine Stelle wieder, ohne zu raten.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | iOS zuerst    |

iOS wird zuerst umgesetzt, Android danach mit der iOS-Implementierung als Referenz.

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Die Playing-Phase zeigt die Waveform der Meditation; der bisherige Atemkreis-Player (Wiedergabe) ist ersetzt.
- [ ] Die Welle scrollt waehrend der Wiedergabe kontinuierlich an einer mittigen, leuchtenden Jetzt-Linie vorbei; Vergangenes links (Akzent-Faerbung), Kommendes rechts (blass). Sichtbares Fenster ca. ±30 s.
- [ ] Greifen der Welle pausiert die Wiedergabe; Ziehen verschiebt die Position (links = vor, rechts = zurueck); Loslassen setzt die Wiedergabe fort, sofern sie vorher lief.
- [ ] Waehrend des Ziehens zeigt die Mitte die Live-Position als `Position / Gesamtlaenge`.
- [ ] Im Ruhezustand zeigt eine dezente zentrale Zeile die Restzeit („Noch 17:08"), mit Sonderzustaenden „Pausiert" und „Beendet".
- [ ] Gesamtfortschritt als Mini-Uebersicht der ganzen Spur (Variante `mini`); Antippen/Ziehen der Mini-Uebersicht springt absolut zur getippten Position.
- [ ] Titelblock zeigt Lehrer (Artist) und Titel der Meditation.
- [ ] Play/Pause-Button startet/pausiert ab der aktuellen Position; nach Ende startet ein Tap die Sitzung neu.
- [ ] Close-Button schliesst die Sitzung.
- [ ] Pre-Roll-Vorbereitungszeit und Start-/End-Gongs verhalten sich unveraendert wie heute; nur die Wiedergabe-Darstellung wechselt vom Atemkreis zur Welle.
- [ ] Bei gesetztem Trim bildet das Fenster auf `[trimStart, trimEnd]` ab: Position, Restzeit und Gesamtlaenge sind relativ zum Trim-Bereich; ausserhalb liegende Welle wird nicht angefahren.
- [ ] Abspielposition wird aus der echten Audio-Position abgeleitet (sauberes Recovery nach Hintergrund/Suspend), nicht aus einem eigenen Frame-Zaehler.
- [ ] Schlaegt die Waveform-Berechnung fehl (z.B. exotisches Format), bleibt der Player voll funktionsfaehig (Scrub, Zeiten) mit reduzierter Darstellung (schlichte Mittellinie statt Amplituden).
- [ ] Reduzierte Bewegung respektiert: Puls aus, Scrollen ggf. ruckweise — Information bleibt ueber Zahl und Position erhalten.
- [ ] Welle ist dekorativ (fuer Screenreader verborgen); Scrub als Slider mit Zeit-Wert exponiert; Play/Pause und Close mit klaren Labels.
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell konsistent zwischen iOS und Android.

### Tests
- [ ] Unit Tests iOS (Scrub-/Seek-Logik, Pausier-/Fortsetz-Verhalten, Fenster-Mapping bei Trim, Restzeit-/Position-Formatierung).
- [ ] Unit Tests Android.

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung am Player).

---

## Manueller Test

1. Eine gefuehrte Meditation aus der Bibliothek oeffnen und abspielen lassen.
2. Erwartung: Pre-Roll/Gongs wie gewohnt; danach scrollt die Welle an der Jetzt-Linie vorbei, „Noch …" zaehlt herunter, Mini-Uebersicht zeigt die Gesamtposition.
3. Welle greifen und nach rechts ziehen → Wiedergabe pausiert, Mitte zeigt Live-Position, Position springt zurueck. Loslassen → Wiedergabe laeuft ab der neuen Stelle weiter.
4. Mini-Uebersicht antippen → Position springt absolut dorthin.
5. Eine Meditation mit gesetztem Trim oeffnen → Gesamtlaenge und Restzeit beziehen sich auf den Trim-Bereich; ueber die Trim-Grenzen hinaus laesst sich nicht spulen.
6. Meditation bis zum Ende laufen lassen → Restzeile zeigt „Beendet"; Tap auf Play startet neu.
7. Identisches Verhalten auf iOS und Android.

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_waveform_player/` (README mit Massen, Tokens, Fenster-Mathematik; `screens/` mit 4 Zustaenden; Variante `mini` ist gewaehlt).
- Bestehende Waveform-Infrastruktur (aus Trim-Editor, wiederverwenden): Waveform-Berechnung, -Cache und -Provider sowie das `MeditationWaveform`-Modell mit Downsampling/Windowing existieren bereits und werden beim Import vorberechnet.
- Bisheriger Player (wird in der Wiedergabe abgeloest): `GuidedMeditationPlayerView` / `GuidedMeditationPlayerViewModel` / `AudioPlayerService`.
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- Android: `android/app/src/main/kotlin/com/stillmoment/`

---

## Hinweise

- Die Waveform muss **nicht** neu erfunden werden — sie wird wie im Trim-Editor aus dem Provider geladen (Cache oder einmalige Berechnung beim Import).
- iOS: Lock-Screen-Keep-Alive und Now-Playing-Info des bestehenden Players bleiben unberuehrt; nur die Darstellung der Wiedergabe-View aendert sich.
- Kontinuierliches Scrollen sollte zeichenseitig (Canvas) und nicht ueber Layout-Updates laufen, um fluessig und akkuschonend zu bleiben.
- Out of Scope (Handoff): Trim-Editor selbst, Geschwindigkeit/Sleep-Timer/AirPlay, Haptik beim Spulen, Library-/Detail-Screen. Fortschritts-Varianten `bar`/`keiner` entfallen — `mini` ist final.

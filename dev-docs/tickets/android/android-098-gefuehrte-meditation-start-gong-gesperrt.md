---
id: android-098
title: "Geführte Meditation mit Start-Gong oder Vorbereitung startet nicht, wenn sofort gesperrt wird"
status: todo
phase: 1-Quick Fix
priority: kritisch
depends_on: [android-094]
---

# Ticket android-098: Geführte Meditation mit Start-Gong oder Vorbereitung startet nicht, wenn sofort gesperrt wird

## Was

**Beobachtet:** Eine geführte Meditation mit eingeschaltetem Start-Gong wird gestartet, danach wird sofort der Bildschirm gesperrt. Der Start-Gong klingt, nach der Atempause bleibt es still: Die Meditation spielt nie. Nach dem Entsperren steht der Player auf 0:00, es gibt keine Benachrichtigung und keine Steuerung auf dem Sperrbildschirm. Dasselbe passiert, wenn man statt zu sperren zum Startbildschirm wechselt. Im Vordergrund funktioniert der Start.
**Erwartet:** Nach Start-Gong und Atempause beginnt die Meditation, auch bei gesperrtem Bildschirm, so wie beim Timer und wie auf iOS.
**Umstände:** Emulator API 36 (Android 16), Dev-Build von main, 2026-10-10. Betrifft alle Geräte ab Android 15: Dort bekommt eine App im Hintergrund nur dann Audiofokus, wenn sie einen Vordergrund-Dienst hat ([Android 15 behavior changes](https://developer.android.com/about/versions/15/behavior-changes-15), „Restrictions on requesting audio focus“). Die App fordert Audiofokus und Vordergrund-Dienst aber erst nach Start-Gong und Atempause an, dann ist sie schon im Hintergrund. Laut Code gilt dasselbe für die Vorbereitungszeit vor einer geführten Meditation (am Emulator nicht geprüft). Der Timer ist nicht betroffen: Er startet seinen Vordergrund-Dienst schon beim Tipp.

## Warum

Das ist der Kern-Anwendungsfall: Meditation starten, Telefon weglegen. Wer den Start-Gong oder eine Vorbereitungszeit nutzt und das Telefon sofort sperrt, hört nach dem Gong nichts mehr – und merkt es erst, wenn er nachsieht.

---

## Akzeptanzkriterien

- [ ] Geführte Meditation mit Start-Gong starten und sofort sperren: Nach Gong und Atempause spielt die Meditation
- [ ] Dasselbe mit Vorbereitungszeit (mit und ohne Start-Gong)
- [ ] Dasselbe, wenn statt zu sperren zum Startbildschirm gewechselt wird
- [ ] Während Vorbereitung und Start-Gong ist die Wiedergabe auf dem Sperrbildschirm bzw. in der Benachrichtigung bereits sichtbar
- [ ] Bricht man während Vorbereitung oder Start-Gong ab (Player schließen), verschwinden Benachrichtigung und Sperrbildschirm-Steuerung, und es spielt nichts nach
- [ ] Ohne Start-Gong und ohne Vorbereitung verhält sich der Start wie bisher
- [ ] Timer, Gongs und Hintergrundklang des Timers bleiben unverändert

---

## Manueller Test

1. Bei einer Meditation „Gong zu Beginn“ einschalten, speichern
2. Meditation starten und sofort den Bildschirm sperren
3. Erwartung: Gong, kurze Pause, dann die Meditation – bei gesperrtem Bildschirm
4. Dasselbe mit eingestellter Vorbereitungszeit
5. Meditation starten, während des Gongs den Player schließen. Erwartung: keine Benachrichtigung, kein Audio danach
6. Auf einem echten Gerät mit Android 15 oder neuer wiederholen

---

## Hinweise

- iOS aktiviert die Audio-Session bereits zu Beginn der Gong- bzw. Vorbereitungsphase; der Timer auf Android startet seinen Vordergrund-Dienst beim Tipp. Beides ist das Vorbild.
- Baut auf android-094 auf (Vordergrund-Dienst und Sperrbildschirm-Steuerung für geführte Meditationen sind dort erstmals angeschlossen).
- Gefunden 2026-10-10 bei der Emulator-Prüfung von android-094.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->

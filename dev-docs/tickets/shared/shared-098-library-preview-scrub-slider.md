# Ticket shared-098: Library-Preview mit Scrub-Slider

**Status**: [~] IN PROGRESS
**Prioritaet**: MITTEL
**Komplexitaet**: Klein. Audio-Wiedergabe-Position muss als beobachtbarer Wert nach aussen sichtbar werden, Slider greift darauf zu. Apple-Music-Style Scrubbing ist auf beiden Plattformen idiomatisch.
**Phase**: 3-Feature
**Plan**: [iOS-Implementierungsplan](../plans/shared-098-ios.md)

---

## Was

Wenn ein Nutzer eine Meditation in der Bibliothek per Long-Press vorhoert, blendet sich unter der Zeile eine schmaler Fortschritts-Slider ein. Per Drag laesst sich an jede Stelle der Meditation springen — Audio laeuft waehrend des Drags durchgehend weiter und spielt sofort von der neuen Position.

## Warum

Heute hoert man beim Vorhoeren nur den Anfang einer Meditation. Wer pruefen will, ob Tempo, Inhalt oder Aussprache eines Lehrers stimmt, muss die volle Meditation oeffnen und sich blind auf die Auswahl verlassen. Mit dem Slider wird Vorhoeren zu dem, was es ist: aktives Probieren vor dem ersten Meditieren.

Der Meditations-Player selbst bleibt bewusst minimal (eine Geste, kein Slider) — Vorhoeren und Meditieren sind unterschiedliche Aktivitaeten. Die Trennung gehoert in die UI: Vorhoeren = Bibliothek, Meditieren = Player.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-075    |
| Android   | [ ]    | shared-075    |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Long-Press auf den Play-Button in der Bibliothek startet Preview (unveraendert) und blendet animiert (ca. 0.25 s) einen Slider unter der Zeile ein.
- [ ] Slider zeigt links die aktuelle Wiedergabeposition (mm:ss), rechts die Gesamtdauer (mm:ss).
- [ ] Wiedergabeposition aktualisiert sich waehrend der Wiedergabe fluessig (kein sichtbares Stocken).
- [ ] Drag am Slider-Punkt springt die Wiedergabe an die neue Stelle und spielt dort sofort weiter (kein Pause, kein hoerbares Stocken).
- [ ] Tap auf den Stop-Button (■) beendet die Preview; der Slider blendet animiert wieder aus.
- [ ] Wechsel zu einer anderen Zeile oder Verlassen des Tabs beendet die Preview und blendet den Slider aus (unveraendert zum bisherigen Stop-Verhalten).
- [ ] Slider erscheint auch in der Such-Ergebnisliste, wenn dort eine Preview laeuft.
- [ ] Tap auf ▶ (wenn keine Preview laeuft) oeffnet wie bisher den Meditations-Player.
- [ ] Lokalisiert (DE + EN) — Accessibility-Label fuer den Slider beschreibt die Funktion.
- [ ] Visuell konsistent zwischen iOS und Android.

### Accessibility
- [ ] Slider ist per VoiceOver / TalkBack als "Vorhoer-Position" bedienbar, mit Adjustable-Verhalten (vorwaerts/rueckwaerts in sinnvollen Schritten).

### Tests
- [ ] Unit Tests iOS — Vorhoer-Wiedergabe-Position wird beobachtbar exponiert; Seek aktualisiert die Position und Audio spielt weiter.
- [ ] Unit Tests Android — analog.
- ~~UI- / Screenshot-Test iOS: Long-Press → Slider sichtbar; Drag → angezeigter Wert aktualisiert.~~ Gestrichen: Drag-Pfad ist unit-getestet (ViewModel → AudioService.seek), Sichtbarkeit strukturell trivial (`if isThisPreviewing { MeditationPreviewProgressRow(...) }`), und UI-Tests mit aktivem AVAudioPlayer im Simulator sind erfahrungsgemaess flaky (Audio-Session-Konflikte, Timing).

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Library oeffnen, eine Meditation per Long-Press vorhoeren — Slider erscheint unter der Zeile, Audio startet.
2. Warten ein paar Sekunden — Slider-Punkt und linkes Zeit-Label wandern mit.
3. Slider-Punkt mit dem Finger in die Mitte der Meditation ziehen, Finger waehrend des Drags drauf halten — Audio springt zur Drag-Position und spielt durchgehend von dort weiter (kein Pause, kein Knacken).
4. Stop-Button (■) tippen — Slider blendet aus, Audio stoppt.
5. Eine andere Zeile per Long-Press vorhoeren waehrend bereits eine Preview laeuft — neue Preview startet, alter Slider verschwindet.
6. Vorhoeren starten, Tab wechseln — Preview stoppt, beim Zurueckkehren ist der Slider weg.
7. Im Suchergebnis (Such-Modus aktiv) ebenfalls vorhoeren — Slider erscheint dort genauso.
8. VoiceOver / TalkBack: Slider via Adjustable-Geste vor- und zurueckspulen.

Erwartung: Identisches Verhalten auf iOS und Android. Apple-Music-Feeling beim Scrubbing.

---

## UX-Konsistenz

Apple-Music-Style: Audio laeuft waehrend des Drags weiter, springt zur Drag-Position. Kein "Pause-beim-Drag, Resume-beim-Loslassen"-Verhalten. Auf beiden Plattformen identisch.

---

## Referenz

- Vorgaenger-Feature: shared-075 (Long-Press Preview in der Meditations-Bibliothek)
- iOS: Library-Bereich und Audio-Vorhoer-Wiedergabe
- Android: Library-Bereich und Vorhoer-Wiedergabe

---

## Hinweise

- Die Wiedergabe-Position des Vorhoer-Audios ist heute auf beiden Plattformen nicht nach aussen sichtbar — sie muss beobachtbar gemacht werden, ohne die bestehende Start/Stop-API zu brechen.
- Beim Scrubbing auf der Wiedergabe weiterlaufen lassen ist auf beiden Plattformen idiomatisch (Position direkt setzen, kein Pause/Resume noetig). Update-Rate des Sliders ca. 10–20 Hz reicht — kein Frame-perfect noetig.
- Slider-Update-Schleife muss bei Stop sauber aufhoeren, sonst leakt der Listener.
- Im Player darf sich nichts aendern — Vorhoeren passiert ausschliesslich in der Bibliothek.

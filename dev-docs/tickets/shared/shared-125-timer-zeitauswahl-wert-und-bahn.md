# Ticket shared-125: Timer-Zeitauswahl als Wert und Bahn

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Ueberschaubar im Umfang, aber es ersetzt das zentrale Bedienelement des Timer-Startbildschirms. Die Risiken liegen weniger im neuen Regler als im Umgang mit gespeicherten Dauern, die auf keiner Raststufe liegen, und in der Barrierefreiheit, die der Atemkreis heute mitbringt.
**Phase**: 4-Polish

---

## Was

Die Zeitauswahl auf dem Timer-Startbildschirm wechselt vom Atemkreis zum Muster "Wert und Bahn":
grosse Zahl mit Einheit, darunter eine Bahn zum Ziehen, die auf feste Stufen einrastet.

## Warum

Auf dem Kreis liegen sechzig Minuten auf einem einzigen Umlauf — eine Minute ist ein Bogen von
gut elf Punkten, waehrend die Fingerkuppe viermal so breit ist und beim Ziehen genau die Zahl
verdeckt, die man treffen will. Wer zwanzig Minuten einstellen moechte, landet bei achtzehn und
muss nachbessern. Die Vorbereitungszeit beantwortet dieselbe Frage bereits mit einer gerasteten
Bahn; danach waehlt man Dauern in der App an beiden Stellen gleich.

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
- [ ] Der Timer-Startbildschirm zeigt die gewaehlte Dauer als grosse Zahl mit der Einheit darunter
- [ ] Unter der Zahl liegt eine Bahn zum Ziehen, deren Enden mit kleinster und groesster Dauer beschriftet sind
- [ ] Die Bahn rastet auf 1, 2, 3, 4 und 5 Minuten und danach in Fuenf-Minuten-Schritten bis 60
- [ ] Jede Raststufe belegt auf der Bahn denselben Weg — die kurzen Zeiten sind genauso leicht zu treffen wie die langen
- [ ] Die Zahl aendert sich waehrend des Ziehens mit
- [ ] Bei 1 Minute und bei 60 Minuten ist Schluss; die Bahn springt an keinem Ende auf den anderen Wert um
- [ ] Eine gespeicherte Dauer, die auf keiner Raststufe liegt (etwa 23 Minuten), wird beim Oeffnen auf die naechste Stufe gebracht — ohne Fehlermeldung und ohne Ruecksprung auf einen Standardwert
- [ ] Der Atemkreis entfaellt auf diesem Bildschirm; in Vorbereitungszeit und laufender Sitzung bleibt er unveraendert
- [ ] Mit VoiceOver und TalkBack laesst sich die Dauer schrittweise erhoehen und verringern, und der jeweils erreichte Wert wird angesagt
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS: Rastung auf die zulaessigen Stufen, Grenzen bei 1 und 60, Umgang mit gespeicherten Zwischenwerten
- [ ] Unit Tests Android: dieselben Faelle

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Timer-Tab oeffnen und die Bahn langsam von links nach rechts ziehen, dabei auf die Zahl schauen
2. Auf 3 Minuten stellen, zu einem anderen Tab wechseln und zurueckkommen
3. App beenden und neu starten
4. Erwartung: Die Zahl folgt dem Finger in spuerbaren Stufen und bleibt jederzeit lesbar; am linken Ende steht 1 Minute, am rechten 60. Nach Tab-Wechsel und Neustart stehen wieder 3 Minuten — auf beiden Plattformen gleich.

---

## Referenz

- Entwurf: Claude Design, Projekt "Still Moment", `prototypen/timer-dauer/Zeitauswahl.html` — Vorschlag 3 "Wert und Bahn"
- Vorbild in der App: die Dauerwahl der Vorbereitungszeit
- iOS: `ios/StillMoment/Presentation/Views/Timer/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/timer/`

---

## Hinweise

- Die Rastung ist bewusst ungleichmaessig: unten fuenf einzelne Minuten, darueber Fuenferschritte. Das haelt kurze Atem-Momente erreichbar, ohne die Bahn zu ueberfuellen.
- Gespeicherte Dauern von Bestands-Nutzern koennen jeden Wert von 1 bis 60 haben — auch aus gespeicherten Praxis-Konfigurationen.
- Der Intervall-Gong waehlt seine Dauer weiterhin ueber Plus und Minus. Dass die App damit immer noch zwei Bedienarten fuer Dauern hat, ist bekannt und gehoert nicht in dieses Ticket.

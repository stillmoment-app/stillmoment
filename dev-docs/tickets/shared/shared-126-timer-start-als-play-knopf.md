---
id: shared-126
title: Timer-Start als runder Play-Knopf
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: niedrig
---

# Ticket shared-126: Timer-Start als runder Play-Knopf

**Komplexitaet**: Kleine Aenderung mit zwei Stolpersteinen: die Beschriftung faellt nur sichtbar weg, nicht fuer die Sprachausgabe, und bestehende automatisierte Tests tippen den Knopf heute ueber seinen Text an.

---

## Was

Aus dem beschrifteten "Beginnen"-Knopf auf dem Timer-Startbildschirm wird ein runder Knopf,
der nur noch das Play-Zeichen zeigt.

## Warum

Der Bildschirm wird ruhiger, und das Play-Zeichen erklaert sich ohne Worte. Ausserdem startet
man eine Meditation damit ueberall in der App auf dieselbe Weise — in der Bibliothek loest
bereits ein runder Play-Knopf die Wiedergabe aus.

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Der Start-Knopf ist rund und zeigt allein das Play-Zeichen, ohne sichtbare Beschriftung
- [ ] Die Tippflaeche ist mindestens 44 Punkt gross
- [ ] Mit VoiceOver und TalkBack wird der Knopf weiterhin als "Meditation beginnen" angesagt — der Wegfall der sichtbaren Beschriftung aendert daran nichts
- [ ] Der Knopf sitzt sichtbar ueber der Tab-Leiste und wird von ihr nicht ueberdeckt
- [ ] Es bleiben keine ungenutzten Texte zurueck
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Bestehende UI- und Screenshot-Tests, die den Start-Knopf antippen, laufen weiterhin durch

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Timer-Tab oeffnen
2. Den Bildschirm mit VoiceOver bzw. TalkBack abfahren, bis der Start-Knopf erreicht ist
3. Knopf antippen
4. Erwartung: Ein runder Knopf mit Play-Zeichen ueber der Tab-Leiste, angesagt als "Meditation beginnen", und die Meditation startet — auf beiden Plattformen gleich.

---

## Referenz

- Entwurf: Claude Design, Projekt "Still Moment", `prototypen/timer-dauer/Zeitauswahl.html` — der Knopf ist dort in allen Varianten gleich
- Vorbild in der App: der runde Play-Knopf in der Bibliothek
- iOS: `ios/StillMoment/Presentation/Views/Timer/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/timer/`

---

## Hinweise

- Der Entwurf zeigt den Knopf auch neben dem heutigen Atemkreis. Die Aenderung haengt damit nicht an shared-125 und kann unabhaengig davon umgesetzt werden — wenn beide zusammen laufen, wird der Bildschirm nur einmal visuell geprueft.

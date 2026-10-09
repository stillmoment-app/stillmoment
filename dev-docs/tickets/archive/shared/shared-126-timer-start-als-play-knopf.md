---
id: shared-126
title: Timer-Start als runder Play-Knopf
status:
  ios: done
  android: done
phase: 4-Polish
priority: niedrig
---

# Ticket shared-126: Timer-Start als runder Play-Knopf

**Komplexitaet**: Kleine Aenderung. Die Ansage fuer VoiceOver/TalkBack ist auf beiden Plattformen schon heute unabhaengig von der sichtbaren Beschriftung gesetzt, und die automatisierten Tests finden den Knopf nicht ueber seinen Text (iOS ueber `timer.button.start`, Android ueber die Ansage). Der Hauptaufwand liegt in der Optik und im Aufraeumen.

---

## Was

Aus dem beschrifteten "Beginnen"-Knopf auf dem Timer-Startbildschirm wird ein runder Knopf,
der nur noch das Play-Zeichen zeigt.

## Warum

Der Bildschirm wird ruhiger, und das Play-Zeichen erklaert sich ohne Worte. Ausserdem startet
man eine Meditation damit ueberall in der App auf dieselbe Weise — in der Bibliothek fuehrt
bereits ein runder Play-Knopf zur Meditation.

Damit wird eine Entscheidung aus shared-097 bewusst aufgegeben: Dort sahen der Start-Knopf und
der "Fertig"-Knopf auf dem Danke-Screen gleich aus, damit Anfang und Ende der Praxis dasselbe
Vokabular sprechen. Die Einheitlichkeit des Startens (Bibliothek und Timer) wiegt hier schwerer.
Der "Fertig"-Knopf bleibt unveraendert.

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [x] Der Start-Knopf ist rund (68 Punkt Durchmesser, wie im Entwurf) und zeigt allein das Play-Zeichen, ohne sichtbare Beschriftung
- [x] Er traegt dieselbe Farbgebung wie der runde Play-Knopf der Bibliothek
- [x] Mit VoiceOver und TalkBack wird der Knopf weiterhin als "Meditation starten" (EN: "Start meditation") angesagt — der Wegfall der sichtbaren Beschriftung aendert daran nichts
- [x] Der Knopf sitzt sichtbar ueber der Tab-Leiste und wird von ihr nicht ueberdeckt — auch nicht auf kleinen Geraeten, obwohl er hoeher ist als der heutige Knopf
  - iOS: geprueft auf iPhone 16 Plus und iPhone SE (3. Gen.)
  - Android: geprueft auf Pixel 8 und 393×851dp (dafuer Abstand Liste→Knopf im kompakten Layout 24→12dp). Unter ~360×740dp war das Idle-Layout schon vor diesem Ticket zu hoch, auch der alte Knopf war dort nicht sichtbar — bewusst nicht Teil dieses Tickets.
- [x] Es bleiben keine ungenutzten Texte, Parameter oder veralteten Kommentare zurueck (u.a. die sichtbare Start-Beschriftung, das Play-Icon des warmen Primaerknopfs auf Android, Kommentare zum "Beginnen-Button")
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Bestehende UI- und Screenshot-Tests, die den Start-Knopf antippen, laufen weiterhin durch
  - iOS: `TimerFlowUITests`, `LibraryFlowUITests` gruen; `ScreenshotTests` nutzen den unveraenderten Identifier `timer.button.start`
  - Android: zwei Tests suchten den Knopf ueber den Text "Start" und wurden auf die Ansage umgestellt; `TimerScreenTest.timerScreen_showsStartButton_whenIdle` gruen. Fuenf `settingsSheet_*`-Tests in `TimerScreenTest` schlagen fehl — sie betreffen `SettingsSheet`, das dieses Ticket nicht beruehrt.

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer-Tab oeffnen
2. Den Bildschirm mit VoiceOver bzw. TalkBack abfahren, bis der Start-Knopf erreicht ist
3. Knopf antippen
4. Erwartung: Ein runder Knopf mit Play-Zeichen ueber der Tab-Leiste, angesagt als "Meditation starten", und die Meditation startet — auf beiden Plattformen gleich.
5. Dasselbe auf dem kleinsten unterstuetzten Geraet: Knopf vollstaendig sichtbar, nichts ueberlappt.

---

## Referenz

- Entwurf: Claude Design, Projekt "Still Moment", `prototypen/timer-dauer/Zeitauswahl.html` — der Knopf ist dort in allen Varianten gleich; Masse in `prototypen/timer-dauer/dauer.css` (`.startbtn`: 68px, Verlauf `#d68a6e` → `#b06a4f`, weicher Schein statt Schlagschatten)
- Vorbild in der App: `PlayButtonCircle` (iOS `Presentation/Views/Shared/`, Android `presentation/ui/components/`), in der Bibliothek mit 36 Punkt
- iOS: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` (`controlButtons`)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt` (`StartButton`)

---

## Hinweise

- Der Entwurf zeigt den Knopf auch neben dem heutigen Atemkreis. Die Aenderung haengt damit nicht an shared-125 und kann unabhaengig davon umgesetzt werden — wenn beide zusammen laufen, wird der Bildschirm nur einmal visuell geprueft.
- Der Knopf im Entwurf ist fast doppelt so gross wie der Bibliotheks-Knopf. Auf Android hat `PlayButtonCircle` bereits einen Parameter fuer den Durchmesser, auf iOS ist er fest eingebaut. Ob der Start-Knopf `PlayButtonCircle` wiederverwendet oder eine eigene Komponente bekommt, entscheidet die Planung.
- Den Ansagetext bewusst nicht aendern: Der Android-Screengrab-Test sucht den Knopf ueber "Start meditation" / "Meditation starten".

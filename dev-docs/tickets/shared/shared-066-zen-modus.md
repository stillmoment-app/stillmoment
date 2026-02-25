# Ticket shared-066: Zen-Modus (Tab-Bar bei Meditation ausblenden)

**Status**: [~] IN PROGRESS (iOS done)
**Prioritaet**: MITTEL
**Aufwand**: iOS ~3 | Android ~1
**Phase**: 4-Polish
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

Tab-Bar wird bei laufender Meditation fliessend ausgeblendet — sowohl beim Timer als auch bei gefuehrten Meditationen. Maximale Immersion ohne ablenkende UI-Elemente.

## Warum

Waehrend der Meditation soll der Bildschirm so ruhig wie moeglich sein. Die Tab-Bar ist waehrend einer Session nutzlos und lenkt visuell ab. Passt zur Philosophie "Die App soll sich anfuehlen wie eine Pause".

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-061    |
| Android   | [ ]    | shared-061    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Timer: Ab Start (Preparation-Phase) gleitet Tab-Bar nach unten aus dem Bildschirm
- [ ] Timer: Bei Abbruch (X) oder Meditation-Ende gleitet Tab-Bar fliessend zurueck
- [ ] Gefuehrte Meditationen: Tab-Bar wird waehrend der Wiedergabe ausgeblendet
- [ ] Gefuehrte Meditationen: Tab-Bar kehrt bei Stopp/Ende zurueck
- [ ] Animation: fliessend, ~0.3-0.5s Dauer
- [ ] Praxis-Pill auf Timer Screen wird bei laufender Meditation ebenfalls ausgeblendet
- [ ] Waehrend Meditation nur sichtbar: Timer-Ring/Player, Zeit/Fortschritt, Affirmation/Titel, X-Button

### Tests
- [x] Unit Tests iOS (State-driven visibility)
- [ ] Unit Tests Android (falls Aenderungen noetig)

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer starten → Tab-Bar gleitet nach unten weg
2. Nur Timer-Ring, Zeit, Affirmation und X-Button sichtbar
3. X antippen → Tab-Bar gleitet zurueck
4. Timer starten, laufen lassen bis Ende → Tab-Bar gleitet zurueck
5. Bibliothek → Meditation starten → Tab-Bar weg
6. Meditation beenden → Tab-Bar zurueck
7. Waehrend Meditation: kein Praxis-Pill sichtbar

---

## UX-Konsistenz

| Verhalten | iOS | Android | Aenderung noetig |
|-----------|-----|---------|------------------|
| Timer: Tab-Bar ausblenden | Aktuell NICHT ausgeblendet | Focus Screen blendet NavBar aus | iOS: Ja, Android: pruefen ob Animation fliessend |
| Guided: Tab-Bar ausblenden | Aktuell NICHT ausgeblendet | Player blendet NavBar aus | iOS: Ja, Android: pruefen |
| Animation | — | — | iOS: neu, Android: ggf. verfeinern |

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (TabBar-Komponente mit `isRunning ? 'translate-y-full' : 'translate-y-0'`)
- Android: `TimerFocusScreen` und `GuidedMeditationPlayerScreen` als Referenz (NavBar bereits ausgeblendet)

---

## Hinweise

- Android hat den Zen-Modus fuer den Timer bereits (Focus Screen ohne NavBar). Hauptarbeit liegt auf iOS.
- Auf Android pruefen ob die Navigation-Bar-Transition fliessend animiert ist oder abrupt. Falls abrupt: Animation ergaenzen.
- iOS: `.toolbar(.hidden, for: .tabBar)` (ab iOS 16) oder aequivalenter Ansatz.
- Der Praxis-Pill ist bereits bei laufender Meditation nicht mehr interaktiv — er soll jetzt zusaetzlich visuell ausgeblendet werden.

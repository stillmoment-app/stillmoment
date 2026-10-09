---
id: ios-058
title: Audio-Koordinator wie alle anderen Dienste im App-Einstieg erzeugen
status: todo
phase: 5-QA
priority: niedrig
depends_on: [ios-055]
---

# Ticket ios-058: Audio-Koordinator wie alle anderen Dienste im App-Einstieg erzeugen

**Komplexitaet**: Wenig Code, aber er betrifft die Audio-Session und damit den Kern-Use-Case (Gongs und Keep-Alive bei gesperrtem Bildschirm). Risiko: Tests, die heute unbemerkt vom gemeinsamen Zustand des Koordinators abhängen, werden rot, wenn jeder Test seinen eigenen bekommt.
**Abhaengigkeiten**: ios-055

---

## Was

Der Audio-Koordinator, der regelt, welche Audioquelle (Timer, geführte Meditation, Vorschau) gerade die Audio-Session besitzt, entsteht wie alle anderen Dienste einmal im App-Einstieg und wird nach unten gereicht. Es gibt keinen global erreichbaren Koordinator mehr, und jeder Unit-Test arbeitet mit einem eigenen.

## Warum

Seit ios-055 entstehen alle Dienste an einer Stelle, und ein Lint-Check verhindert, dass sie anderswo erzeugt werden. Der global erreichbare Koordinator ist die letzte Ausnahme davon — und seine ursprüngliche Aufgabe ("es gibt nur einen") erfüllt inzwischen der App-Einstieg selbst. Gleichzeitig teilen sich heute alle Unit-Tests denselben Koordinator samt dessen Zustand (aktive Quelle, registrierte Konflikt-Handler). Ein Test kann so das Ergebnis eines anderen beeinflussen.

---

## Akzeptanzkriterien

### Feature
- [ ] In der App gibt es genau einen Audio-Koordinator; Timer, Vorschauen und Player nutzen denselben.
- [ ] Der Koordinator ist nicht mehr global erreichbar; die Lint-Ausnahme für ihn entfällt.
- [ ] Verhalten unverändert: Start-, Intervall- und End-Gong spielen bei gesperrtem Bildschirm, eine geführte Meditation unterbricht eine laufende Vorschau und umgekehrt wie bisher.

### Tests
- [ ] Jeder Unit-Test, der einen Audio-Dienst braucht, bekommt einen eigenen Koordinator; kein Test liest den Zustand eines anderen.
- [ ] Ein Test belegt, dass Timer-Audio und Player in der App-Verdrahtung denselben Koordinator verwenden.
- [ ] Alle bestehenden Unit-Tests sind grün.

### Dokumentation
- [ ] DI-Regel (`.claude/rules/ios-dependency-injection.md`) und `ios/CLAUDE.md`: Ausnahme für den einzigen Singleton entfernen.
- [ ] `dev-docs/architecture/audio-system.md`, falls dort der globale Zugriff beschrieben ist.

---

## Manueller Test

1. Timer mit Start-, Intervall- und End-Gong starten, Bildschirm sperren, Handy weglegen.
2. Erwartung: Alle Gongs spielen bei gesperrtem Bildschirm, wie vor der Änderung.
3. In der Bibliothek eine Vorschau starten, dann eine Meditation öffnen und abspielen.
4. Erwartung: Die Vorschau stoppt, die Meditation spielt — wie vor der Änderung.

---

## Hinweise

- Heute liest nur noch die Composition Root (`AppDependencies.live()`) den globalen Zugriff; die Tests greifen dagegen direkt darauf zu. Der Umbau betrifft also vor allem die Test-Seite.
- Thematisch verwandt mit ios-057 (Testisolation).

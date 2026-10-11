---
id: ios-058
title: Audio-Tests arbeiten mit eigenem Audio-Koordinator
status: in-progress
phase: 5-QA
priority: niedrig
depends_on: [ios-055]
---

# Ticket ios-058: Audio-Tests arbeiten mit eigenem Audio-Koordinator

**Komplexitaet**: Wenig Code, fast nur auf der Test-Seite. Der App-Pfad bleibt bewusst unverändert, damit das Risiko für Gongs und Keep-Alive bei gesperrtem Bildschirm praktisch null ist. Risiko: Tests, die heute unbemerkt vom gemeinsamen Zustand des Koordinators abhängen, werden rot.
**Abhaengigkeiten**: ios-055

---

## Was

Jeder Unit-Test, der Audio-Dienste braucht, arbeitet mit einem eigenen Audio-Koordinator statt mit dem einen, den die App benutzt. Die App selbst behält ihren einen, global erreichbaren Koordinator.

Zusätzlich belegt ein Test, dass die App Timer-Audio und Player mit demselben Koordinator verdrahtet. Das ist die Eigenschaft, an der Gongs und Keep-Alive bei gesperrtem Bildschirm hängen, und bisher prüft sie kein Test.

## Warum

Heute teilen sich alle Unit-Tests denselben Koordinator samt Zustand (aktive Quelle, registrierte Konflikt-Handler). Jeder Test muss deshalb am Ende aufräumen. Vergisst einer das, beeinflusst er andere Tests.

**Warum der Singleton bleibt (Entscheidung):** Der Koordinator verwaltet die `AVAudioSession`, und die gibt es pro Prozess genau einmal. Ein einzelner globaler Koordinator bildet das ehrlich ab. Ihn wie die übrigen Dienste in `AppDependencies.live()` zu erzeugen, brächte keinen Nutzen für die App. Es würde nur die Möglichkeit schaffen, versehentlich einen zweiten Koordinator für dieselbe Session anzulegen. Am Audio-Handling bei gesperrtem Bildschirm ist schon mehrfach etwas gebrochen. Deshalb bleibt der App-Pfad unangetastet, und die Lint-Ausnahme für `AudioSessionCoordinator.shared` bleibt bestehen, jetzt begründet dokumentiert.

---

## Akzeptanzkriterien

### Feature
- [ ] Der App-Pfad ist unverändert: `AppDependencies.live()` verwendet weiterhin `AudioSessionCoordinator.shared`, und der Koordinator selbst ändert sich höchstens in der Sichtbarkeit seines Initializers.
- [ ] Im App-Code kann weiterhin kein zweiter Koordinator entstehen (die Lint-Regel `service_created_outside_composition_root` fängt das ab).

### Tests
- [ ] Ein Test belegt, dass Timer-Audio und Player in der App-Verdrahtung denselben Koordinator verwenden.
- [ ] Kein Unit-Test greift mehr auf `AudioSessionCoordinator.shared` zu, außer wenn er ausdrücklich die App-Verdrahtung prüft.
- [ ] Tests, die das Zusammenspiel mehrerer Audio-Quellen prüfen (z.B. Vorschau gegen Timer), geben beiden Seiten ausdrücklich denselben Koordinator.
- [ ] Alle bestehenden Unit-Tests sind grün.

### Dokumentation
- [ ] DI-Regel (`.claude/rules/ios-dependency-injection.md`), `ios/CLAUDE.md` und `dev-docs/architecture/audio-system.md`: Der Singleton ist als bewusste Ausnahme mit Begründung beschrieben, und Tests erzeugen ihren eigenen Koordinator.

---

## Manueller Test

Nicht nötig, weil der App-Pfad unverändert bleibt. Zur Absicherung genügt der Diff: In `ios/StillMoment/` ändert sich höchstens die Sichtbarkeit des Koordinator-Initializers.

---

## Nicht Teil dieses Tickets

- Den Koordinator in `AppDependencies.live()` erzeugen oder `shared` entfernen (siehe Entscheidung oben).
- Testisolation gegenüber der echten, prozessweiten `AVAudioSession`.

---

## Hinweise

- Heute liest nur die Composition Root (`AppDependencies.live()`) den globalen Zugriff. Die Tests greifen direkt darauf zu: `AudioService+Testing.swift` (Default-Argument), `AudioServiceTests`, `AudioServiceIntegrationTests`, `AudioServiceBackgroundPreviewTests`, `AudioServiceKeepAliveTests`, `AudioPlayerServiceTests`, `AudioSessionCoordinatorTests`.
- Thematisch verwandt mit ios-056 (Testisolation).

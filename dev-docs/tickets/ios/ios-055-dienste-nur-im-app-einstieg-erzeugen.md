# Ticket ios-055: Dienste nur im App-Einstieg erzeugen (Composition Root)

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-055.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Breiter, mechanischer Umbau über ~35 Default-Argumente in ViewModels, Views und Infrastructure-Diensten. Das Risiko liegt in stillen Verhaltensänderungen: Heute bekommen einige Bildschirme eigene Instanzen, künftig teilen sie eine. Dienste mit internem Zustand (In-Flight-Dedup, Conflict-Handler, Caches) verhalten sich danach anders, und zwar gewollt. Das muss pro Dienst bewusst geprüft werden.
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Alle Dienste der App (Services, Repositories, Provider, Clock) werden an genau einer Stelle erzeugt, dem App-Einstieg, und von dort an die Bildschirme weitergegeben. Kein ViewModel, keine View und kein Dienst erzeugt sich seine Abhängigkeiten selbst, auch nicht als Default-Argument. Ein automatischer Check verhindert, dass dieses Muster wieder eingebaut wird.

## Warum

Default-Argumente wie `= WaveformProvider()` oder `= AudioService()` springen still ein, wenn jemand vergisst, eine Abhängigkeit weiterzugeben. Der Compiler meldet das nicht, und die Tests merken es nicht, weil sie Mocks immer ausdrücklich übergeben. In Produktion ist das schon passiert: Die Waveform wird doppelt berechnet (ios-054), und `AudioService`-Instanzen überschreiben sich gegenseitig den Conflict-Handler (Verstoß gegen ios-040). Das Standardmuster dagegen ist ein Composition Root mit Pure DI (Seemann, „Dependency Injection Principles, Practices, and Patterns“). Default-Instanzen für Dienste gelten dort als Anti-Pattern („Bastard Injection“).

---

## Akzeptanzkriterien

### Feature
- [x] Im Produktionscode gibt es keine Default-Argumente mehr, die einen Dienst erzeugen. Fehlt eine Weitergabe, baut die App nicht.
- [x] Dienste werden nur noch im App-Einstieg erzeugt. Jeder Dienst mit internem Zustand existiert genau einmal.
- [x] `make check` schlägt fehl, wenn außerhalb des App-Einstiegs ein Dienst erzeugt wird. Ausgenommen sind Tests und Previews.
- [x] App-Verhalten bleibt unverändert: Timer, Bibliothek, Import, Editor, Trim-Editor und Player funktionieren wie vorher, auch auf dem Lock Screen.

### Tests
- [x] Alle bestehenden Unit- und UI-Tests sind grün.
- [x] Ein Test belegt, dass der Lint-Check ein neues Default-Argument für einen Dienst erkennt (z. B. Testfall in der Lint-Konfiguration oder ein dokumentierter Gegenbeweis).

### Dokumentation
- [x] `ios/CLAUDE.md`: Die DI-Konvention um „Erzeugung nur im App-Einstieg, keine Default-Argumente für Dienste“ ergänzen.
- [x] `.claude/rules/ios-dependency-injection.md` mit dem Endzustand abgleichen.
- [x] Status-Tabelle in `dev-docs/architecture/architecture-review-2026-09.md` (Befund 1) aktualisieren.

---

## Manueller Test

1. Timer starten, Handy sperren: Gongs und Hintergrundklang laufen wie bisher.
2. Eine Meditation importieren, sofort Editor, Trim-Editor und Player öffnen: Alles funktioniert, die Waveform erscheint.
3. Während einer geführten Meditation kommt ein Anruf oder anderes Audio dazu: Die Konfliktbehandlung greift wie vorher.

---

## Referenz

- Quelle: `dev-docs/architecture/architecture-review-2026-09.md`, Befund 1 „Dependency-Identität hat keinen Ort“
- App-Einstieg: `ios/StillMoment/StillMomentApp.swift` (dort entsteht `sharedAudioService` schon heute richtig)
- Android-Gegenstück: Hilt `AppModule` mit `@Singleton` löst dasselbe Problem dort per Container.

---

## Hinweise

- **Bewusst ohne Container-Bibliothek** (`swift-dependencies`, `Factory`). Die Init-Kette ohne Defaults lässt sich mit Bordmitteln umsetzen und wird vom Compiler geprüft.
- Der `nonisolated init` samt `nonisolated(unsafe)` in `WaveformProvider` existiert laut eigenem Kommentar nur, damit `WaveformProvider()` als Default-Argument funktioniert. Prüfen, ob er danach entfallen kann.
- Löst die Ursache von ios-054. ios-054 bleibt als beobachtbarer Nachweis für den Waveform-Fall bestehen.
- Default-Argumente für reine Werte (Konfiguration, Zahlen, Flags) sind nicht betroffen, nur erzeugte Dienst-Instanzen.

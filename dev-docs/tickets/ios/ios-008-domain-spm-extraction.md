# Ticket ios-008: Domain-Layer SPM-Extraktion

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Gross
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Domain-Layer in ein separates Swift Package extrahieren, damit Domain-Tests ohne iOS-Simulator laufen koennen.

## Warum

Unit Tests dauern ~45s, obwohl die reine Testausfuehrung nur wenige Sekunden betraegt. Der Overhead kommt vom Simulator-Start. Mit einem SPM-Package koennten reine Logik-Tests in <5s laufen.

**Hinweis**: Seit ios-011 (separate Test-Schemes) ist das Problem weniger dringend - `make test-unit` laeuft jetzt isoliert. Die SPM-Extraktion waere trotzdem ein Architektur-Gewinn.

---

## Akzeptanzkriterien

- [ ] `StillMomentCore` Swift Package erstellt
- [ ] Domain/Models und Domain/Services (Protokolle) im Package
- [ ] Reine Logik-Tests laufen ohne Simulator (`swift test`)
- [ ] App importiert Package und funktioniert wie vorher
- [ ] CI Pipeline angepasst (Package-Tests separat)
- [ ] Bestehende Tests weiterhin gruen

---

## Manueller Test

1. `cd Packages/StillMomentCore && swift test` - Erwartet: <5s, alle gruen
2. `cd ios && make test-unit` - Erwartet: Weiterhin gruen
3. App starten und Timer/Library testen - Erwartet: Funktioniert wie vorher

---

## Referenz

- Domain-Layer: `ios/StillMoment/Domain/`
- Tests: `ios/StillMomentTests/`
- Apple SPM Doku: https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode

---

## Hinweise

- Domain hat by design KEINE iOS-Abhaengigkeiten - Extraktion sollte sauber sein
- Tests mit AVFoundation/AVAudioSession muessen in App-Tests bleiben
- Combine ist in SPM verfuegbar (kein Blocker)

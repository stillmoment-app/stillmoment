# Discussion Items: shared-059

Gesammelt waehrend automatischem Review. Zum spaeteren Abarbeiten.

## Review-Runde 1

- ios/StillMoment/Application/ViewModels/TimerViewModel.swift:49 - `displayState` wurde von `@Published private(set)` auf `@Published` (ohne Zugriffseinschränkung) angehoben. Im Kontext des Projekts ist das vertretbar (nur intern, SwiftUI-Preview-Zweck), aber es entfernt die Setter-Kontrolle vom ViewModel vollständig. Alternativer Ansatz: eine dedizierte `setPreviewState(_ state: TimerDisplayState)` Methode in der Preview-Extension würde den Setter weiterhin absichern.
- ios/StillMoment/Infrastructure/Services/AudioService.swift:276-287 - `stop()` ruft `coordinator.releaseAudioSession(for: .timer)` auf, setzt aber `timerSessionActive` nicht auf `false`. Ist in der Praxis kein Problem (stop() wird nicht über den ViewModel-Timer-Pfad aufgerufen, und der Konflikt-Handler setzt das Flag selbst), aber der inkonsistente Zustand könnte in zukünftigen Codepfaden zu einem Bug führen.
- ios/StillMomentTests/AudioServiceKeepAliveTests.swift:85-93 - `testKeepAliveRunsDuringIntroductionPhase` startet keine echte Introduction (kein Audio-File im Test-Bundle), sondern nur `stopIntroduction()` als No-op. Das testet nicht wirklich, ob Keep-Alive parallel zu einem laufenden Introduction-Player läuft — aber das ist durch AVFoundation-Architektur schwer unit-testbar und kann als struktureller Nachweis akzeptiert werden.

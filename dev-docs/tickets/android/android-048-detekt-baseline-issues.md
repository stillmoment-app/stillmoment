# Ticket android-048: detekt Baseline Issues beheben

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Die bei der detekt-Integration identifizierten Code-Qualitaets-Issues aus der Baseline beheben. Fokus auf Issues, die echte Probleme darstellen (SwallowedException, UnusedParameter, ImplicitDefaultLocale).

## Warum

- **SwallowedException**: Fehler verschwinden spurlos, erschwert Debugging
- **UnusedParameter/Property**: Toter Code, verwirrt Entwickler
- **ImplicitDefaultLocale**: Kann auf manchen Geraeten zu falscher Zahlenformatierung fuehren
- **TooGenericExceptionCaught**: Kann unerwartete Fehler maskieren

---

## Akzeptanzkriterien

- [ ] SwallowedException (4x): Exceptions loggen oder gezielt behandeln
- [ ] UnusedParameter (2x): Parameter entfernen oder verwenden
- [ ] UnusedPrivateProperty (2x): Properties entfernen oder verwenden
- [ ] ImplicitDefaultLocale (5x): `Locale.ROOT` bei String.format verwenden
- [ ] TooGenericExceptionCaught (4x): Spezifischere Exceptions oder bewusst ignorieren
- [ ] `./gradlew detekt` laeuft ohne Baseline durch
- [ ] Baseline-Datei entfernen oder auf LongMethod/LongParameterList reduzieren

---

## Manueller Test

1. `./gradlew detekt` ausfuehren
2. Erwartung: Build SUCCESSFUL ohne die behobenen Issues

---

## Referenz

- Baseline: `android/config/detekt/baseline.xml`
- Config: `android/config/detekt/detekt.yml`

Betroffene Dateien (aus Baseline):
- `GuidedMeditationDataStore.kt` - SwallowedException
- `GuidedMeditationRepositoryImpl.kt` - SwallowedException, TooGenericExceptionCaught
- `AudioPlayerService.kt` - SwallowedException, UnusedPrivateProperty
- `AudioService.kt` - TooGenericExceptionCaught
- `MediaSessionManager.kt` - UnusedParameter
- `TimerViewModel.kt` - UnusedPrivateProperty
- `SettingsSheet.kt` - UnusedParameter
- `GuidedMeditation.kt` - ImplicitDefaultLocale
- `TimerDisplayState.kt` - ImplicitDefaultLocale
- `GuidedMeditationPlayerViewModel.kt` - ImplicitDefaultLocale

---

## Hinweise

**NICHT fixen** (Compose-typisch, kein echter Code-Smell):
- `LongMethod` bei Composables - State Hoisting Pattern
- `LongParameterList` bei Screen-Content-Funktionen - Standard Compose Pattern

Diese koennen in der Baseline verbleiben oder die Regeln fuer UI-Layer deaktiviert werden.

---

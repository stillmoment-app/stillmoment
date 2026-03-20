# Ticket shared-076: Vibration als Gong-Signal

**Status**: [~] IN PROGRESS
**Plan Android**: [Implementierungsplan Android](../plans/shared-076-android.md)
**Plan iOS**: [Implementierungsplan iOS](../plans/shared-076-ios.md)
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 3-Feature

---

## Was

Im Gong-Klang-Picker kann der User "Vibration" als Option auswählen — gleichwertig zu einem Gong-Sound. Gilt für Start/Ende-Gong und Intervall-Gong.

## Warum

Manche User meditieren in Situationen, in denen ein hörbares Signal stört oder nicht wahrnehmbar ist (z.B. Handy in der Hosentasche bei Outdoor-Meditation, Partner schläft). Vibration ist ein dezentes, körpernahes Signal ohne Lärm.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Im Klang-Picker erscheint "Vibration" als auswählbare Option (neben den Gong-Sounds)
- [ ] Wenn "Vibration" gewählt ist, wird kein Audio abgespielt — stattdessen ein einzelnes Haptic-Feedback ausgelöst
- [ ] Wenn "Vibration" gewählt ist, ist der Lautstärke-Slider ausgeblendet
- [ ] Die Option gilt für Start/Ende-Gong und Intervall-Gong gleichermassen
- [ ] Beim Antippen von "Vibration" im Klang-Picker wird ein kurzes Haptic als Preview ausgelöst (konsistent zur Gong-Sound-Vorschau)
- [ ] Lokalisiert (DE + EN): "Vibration" (identisch in beiden Sprachen)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS: Vibration-Option wird korrekt persistiert und geladen
- [ ] Unit Tests Android: Vibration-Option wird korrekt persistiert und geladen

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Praxis-Editor öffnen → Gong → Klang antippen
2. "Vibration" in der Liste auswählen
3. Erwartung: Lautstärke-Slider verschwindet; beim Speichern und Starten des Timers vibriert das Gerät zum Gong-Zeitpunkt (kein Ton)
4. Handy stumm schalten → Timer starten → Erwartung: Vibration funktioniert weiterhin

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Start/Ende-Gong | `CHHapticEngine` `.hapticContinuous(duration: 0.4)` | `VibrationEffect.createOneShot(400ms)` |
| Intervall-Gong | `CHHapticEngine` `.hapticTransient` (kurzer Tap) | `VibrationEffect.createOneShot(150ms)` |
| Hintergrund (iOS) | `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` — funktioniert bei aktiver AVAudioSession (keepAlive) | ✅ funktioniert |
| Lautstärke-Slider | Ausgeblendet wenn Vibration gewählt | Ausgeblendet wenn Vibration gewählt |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/`
- Android: `android/app/src/main/kotlin/com/stillmoment/`

---

## Hinweise

- iOS: `UIImpactFeedbackGenerator(.medium)` — kein `.heavy` (zu alarmierend), kein `.light` (zu subtil)
- Android: `VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE)` — min SDK 26, kein Fallback nötig
- "Vibration" ist kein GongSound-enum-Wert der Audio lädt — es ist ein eigenständiger Signal-Typ
- Beim Antippen von "Vibration" im Klang-Picker wird ein kurzes Haptic als Preview ausgelöst (konsistent zum Gong-Vorschau-Sound bei anderen Optionen)

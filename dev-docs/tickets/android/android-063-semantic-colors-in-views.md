# Ticket android-063: Semantische Farben in Views konsumieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Android-Views sollen die semantischen Farbrollen aus `StillMomentColors` (`LocalStillMomentColors`) nutzen statt Material3-Defaults. Betrifft: Timer-Ring-Fortschritt, Toggle/Slider-Track, Card-Hintergrund und Card-Border im Dark Mode.

## Warum

iOS nutzt diese vier Rollen bereits aktiv (Timer-Ring, custom ToggleStyle, ThemedSlider, Cards mit Dark-Mode-Border). Die Android-Infrastruktur (`StillMomentColors`, `LocalStillMomentColors`, `resolveStillMomentColors`) ist vorhanden und getestet, aber keine View liest die Werte. Das fuehrt zu sichtbaren Farbunterschieden zwischen den Plattformen.

---

## Akzeptanzkriterien

### Feature
- [ ] Timer-Ring nutzt `progress`-Farbe statt Material3 `primary`
- [ ] Toggle inaktiver Track nutzt `controlTrack`-Farbe (WCAG >= 3:1 vs Hintergrund)
- [ ] Slider inaktiver Track nutzt `controlTrack`-Farbe
- [ ] Card-Hintergruende nutzen `cardBackground`
- [ ] Dark Mode: Cards zeigen subtilen Border (`cardBorder`)
- [ ] Light Mode: Cards haben keinen sichtbaren Border (transparent)
- [ ] Alle drei Themes (Candlelight, Forest, Moon) sehen konsistent aus

### Tests
- [ ] Bestehende WCAG-Kontrast-Tests bleiben gruen
- [ ] Visueller Vergleich mit iOS-Screenshots fuer alle 6 Theme/Mode-Kombinationen

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. App oeffnen, jedes Theme durchschalten (Candlelight, Forest, Moon)
2. Jeweils Light und Dark Mode pruefen
3. Timer-Screen: Ring-Farbe, Toggle-Track, Slider-Track pruefen
4. Library-Screen: Card-Hintergrund und Border im Dark Mode pruefen
5. Erwartung: Farben stimmen visuell mit iOS ueberein

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Theme/ThemeColors.swift` (progress, controlTrack, cardBackground, cardBorder)
- iOS: `ios/StillMoment/Presentation/Views/Shared/ToggleStyles.swift` (controlTrack-Nutzung)
- iOS: `ios/StillMoment/Presentation/Views/Shared/ThemedSlider.swift` (controlTrack-Nutzung)
- Android: `LocalStillMomentColors` bereits bereitgestellt in Theme.kt

---

## Hinweise

- iOS nutzt custom `ToggleStyle` und `ThemedSlider` weil UIKit-Bridges nicht auf Theme-Aenderungen reagieren. Android braucht ggf. custom `SwitchColors`/`SliderColors` mit den semantischen Werten.
- `cardBorder` ist in Light Modes `Color.Transparent` — kein spezielles Handling noetig, einfach immer den Border setzen.

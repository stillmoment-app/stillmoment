# Ticket android-046: Gradient an iOS angleichen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Hintergrund-Gradient in Android soll an iOS angeglichen werden: 3-Farben-Gradient (warmCream → warmSand → paleApricot) statt des aktuellen 2-Farben-Gradients mit Alpha.

## Warum

Visuelle Konsistenz zwischen iOS und Android. Der iOS-Gradient wirkt durch 3 Farben deutlicher und waermer, waehrend Android aktuell flacher wirkt.

---

## Akzeptanzkriterien

- [x] `WarmGradientBackground` verwendet 3 Farben wie iOS
- [x] Farbreihenfolge: WarmCream (oben) → WarmSand (mitte) → PaleApricot (unten)
- [x] Kein Alpha-Kanal mehr noetig
- [ ] Visuell konsistent mit iOS (manuell pruefen)

---

## Manueller Test

1. App starten
2. Timer-Screen anschauen
3. Erwartung: Gradient zeigt deutlichen Verlauf von hell (oben) nach warm (unten), identisch zu iOS

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Shared/Color+Theme.swift` (warmGradient)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Theme.kt` (WarmGradientBackground)

---

## Hinweise

iOS-Implementation:
```swift
LinearGradient(
    colors: [.warmCream, .warmSand, .paleApricot],
    startPoint: .top,
    endPoint: .bottom
)
```

Android aktuell (zu aendern):
```kotlin
Brush.verticalGradient(
    colors = listOf(WarmSand, PaleApricot.copy(alpha = 0.5f))
)
```

---

# Ticket android-053: WheelPicker API-Verbesserungen

**Status**: [x] DONE (teilweise - nur kritischer Pixel-Fix)
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

WheelPicker-Komponente mit robusterer API und konsistenterem Verhalten versehen.

## Warum

Die aktuelle Implementierung funktioniert, hat aber technische Schulden:
- Hardcoded Pixel-Wert fuer Item-Hoehe (fragil bei verschiedenen Densities)
- Keine zentrale Defaults-Konfiguration
- Fling-Verhalten erlaubt weite Spruenge statt kontrolliertem Scrollen
- Content-Rendering ist fest eingebaut statt flexibel

---

## Akzeptanzkriterien

- [x] Pixel-Berechnung nutzt `LocalDensity` statt hardcoded Wert
- [~] `WheelPickerDefaults` Objekt - WONTFIX (Overengineering, nur 1 Consumer)
- [~] FlingBehavior begrenzt - WONTFIX (kein reales Problem)
- [~] Slot-Pattern - WONTFIX (YAGNI)
- [x] Bestehendes Verhalten bleibt unveraendert (keine Breaking Changes)
- [~] Unit Tests - WONTFIX (stabile UI-Komponente)

---

## Manueller Test

1. Timer-Screen oeffnen
2. Minuten-Picker scrollen (langsam und schnell)
3. Erwartung: Smooth Snapping, kein Ueberspringen mehrerer Werte bei schnellem Fling

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/WheelPicker.kt`
- Inspiration: [compose-m3-picker](https://github.com/Seo-4d696b75/compose-m3-picker)

---

## Hinweise

Zeile 72 hat einen hardcoded Pixel-Wert:
```kotlin
val itemHeightPx = 150 // Approximate pixel height for 50.dp
```

Besser:
```kotlin
val density = LocalDensity.current
val itemHeightPx = with(density) { itemHeight.toPx() }
```

---

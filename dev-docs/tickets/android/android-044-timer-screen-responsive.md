# Ticket android-044: TimerScreen Responsive Layout

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der TimerScreen soll sich besser an verschiedene Bildschirmgroessen anpassen - sowohl kurze Screens (Landscape, kleine Phones) als auch lange Screens (Tablets).

## Warum

Aktuell verwendet der TimerScreen feste Groessen (150dp Bild, 150dp WheelPicker, 250dp TimerDisplay). Bei Landscape werden Elemente abgeschnitten, bei Tablets entstehen grosse ungenuetzte Luecken.

---

## Akzeptanzkriterien

- [ ] `heightIn(min, max)` statt fester Groessen verwenden
- [ ] Maximale Lueckengroesse auf langen Screens begrenzen
- [ ] @Preview fuer: Phone, Landscape (640x360), Tablet
- [ ] Layout bleibt visuell ausgewogen auf allen Bildschirmgroessen

---

## Manueller Test

1. App auf Phone im Landscape oeffnen
2. Timer-Screen pruefen: Alle Elemente sichtbar?
3. App auf Tablet oeffnen (oder Emulator)
4. Erwartung: Keine riesigen Luecken, Content gut verteilt

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`

---

## Hinweise

**Preview-Strategie (ohne Emulator pruefen):**
```kotlin
@Preview(name = "Phone", device = Devices.PIXEL_4)
@Preview(name = "Landscape", widthDp = 640, heightDp = 360)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET)
@Composable
fun TimerScreenPreview() { ... }
```

Bekannte Problemstellen:
- Zeilen 226-232: Bild feste Groesse (150.dp)
- Zeilen 248-253: WheelPicker feste Hoehe (150.dp)
- Zeile 299: TimerDisplay feste Groesse (250.dp)
- Zeile 172: `weight(1f)` erzeugt unbegrenzte Luecken auf Tablets

# Ticket android-045: GuidedMeditationPlayerScreen Responsive Layout

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der GuidedMeditationPlayerScreen soll sich besser an verschiedene Bildschirmgroessen anpassen, insbesondere bei langen Screens (Tablets).

## Warum

Aktuell verwendet der PlayerScreen `Arrangement.SpaceBetween`, was auf Tablets riesige Luecken zwischen Header und Controls erzeugt. Zusaetzlich verschwenden feste Spacer Platz auf kurzen Screens.

---

## Akzeptanzkriterien

- [x] Flexible Spacer mit `weight()` oder `heightIn()` verwenden
- [x] Maximale Lueckengroesse auf langen Screens begrenzen
- [x] @Preview fuer: Phone, Landscape (640x360), Tablet
- [x] Controls bleiben gut erreichbar auf allen Bildschirmgroessen

---

## Manueller Test

1. Eine Meditation im Player oeffnen
2. Auf Tablet (oder Emulator) pruefen
3. Erwartung: Keine riesige Luecke zwischen Titel und Controls

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`

---

## Hinweise

**Preview-Strategie (ohne Emulator pruefen):**
```kotlin
@Preview(name = "Phone", device = Devices.PIXEL_4)
@Preview(name = "Landscape", widthDp = 640, heightDp = 360)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET)
@Composable
fun GuidedMeditationPlayerScreenPreview() { ... }
```

Bekannte Problemstellen:
- Zeilen 328, 384: Feste Spacer (32.dp + 24.dp)
- Zeile 163: `Arrangement.SpaceBetween` erzeugt riesige Luecken auf Tablets
- Zeile 355: FAB feste Groesse (72.dp)

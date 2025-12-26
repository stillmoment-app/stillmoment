# Ticket android-043: SettingsSheet Scroll + Responsive Layout

**Status**: [ ] TODO
**Prioritaet**: KRITISCH
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das SettingsSheet soll bei Landscape oder kleinen Screens scrollbar sein und sich responsiv an verschiedene Bildschirmgroessen anpassen.

## Warum

Aktuell hat das SettingsSheet keinen Scroll-Container. Bei Landscape oder kleinen Phones wird Content abgeschnitten und ist nicht erreichbar. Zusaetzlich fehlen Window Insets, sodass die NavBar Content ueberdecken kann.

---

## Akzeptanzkriterien

- [ ] Column in scrollbaren Container wrappen
- [ ] Feste Spacer durch flexible Layouts ersetzen
- [ ] Window Insets (`navigationBarsPadding()`) hinzufuegen
- [ ] @Preview fuer: Phone, Landscape (640x360), Tablet
- [ ] Content ist bei allen Optionen sichtbar (Background Sound + Interval aktiv)

---

## Manueller Test

1. App im Landscape-Modus oeffnen
2. Timer starten und Settings oeffnen
3. Alle Optionen aktivieren (Background Sound + Interval)
4. Erwartung: Alle Optionen sind erreichbar, Content scrollt bei Bedarf

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`

---

## Hinweise

**Preview-Strategie (ohne Emulator pruefen):**
```kotlin
@Preview(name = "Phone", device = Devices.PIXEL_4)
@Preview(name = "Landscape", widthDp = 640, heightDp = 360)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET)
@Composable
fun SettingsSheetPreview() { ... }
```

Bekannte Problemstellen:
- Zeilen 97, 108, 128-130, 141, 183, 191, 204: Feste Spacer (~120dp gesamt)
- Kein Scroll-Container vorhanden
- Keine `navigationBarsPadding()` fuer Window Insets

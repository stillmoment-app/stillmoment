# Ticket android-043: SettingsSheet Scroll + Responsive Layout

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das SettingsSheet soll auf kleinen Screens scrollbar sein und sich responsiv an verschiedene Bildschirmgroessen anpassen.

## Warum

Aktuell hat das SettingsSheet keinen Scroll-Container. Bei kleinen Phones kann Content abgeschnitten werden. Zusaetzlich fehlen Window Insets, sodass die NavBar Content ueberdecken kann.

**Hinweis:** App ist Portrait-only (shared-012), daher keine Landscape-Unterstuetzung noetig.

---

## Akzeptanzkriterien

- [ ] Column in scrollbaren Container wrappen (verticalScroll)
- [ ] Feste Spacer durch flexible Layouts ersetzen (isCompactHeight Pattern)
- [ ] Window Insets (`navigationBarsPadding()`) hinzufuegen
- [ ] @Preview fuer: Phone, Tablet
- [ ] Content ist bei allen Optionen sichtbar (Background Sound + Interval aktiv)

---

## Manueller Test

1. App auf kleinem Phone oeffnen (oder Emulator)
2. Timer starten und Settings oeffnen
3. Alle Optionen aktivieren (Background Sound + Interval)
4. Erwartung: Alle Optionen sind erreichbar, Content scrollt bei Bedarf

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`
- Vergleich: TimerScreen/MinutePicker hat bereits `isCompactHeight` Pattern

---

## Hinweise

**Preview-Strategie:**
```kotlin
@Preview(name = "Phone", device = Devices.PIXEL_4)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET)
@Composable
fun SettingsSheetPreview() { ... }
```

**Responsive Pattern (siehe TimerScreen):**
```kotlin
BoxWithConstraints {
    val isCompactHeight = maxHeight < 700.dp
    val spacing = if (isCompactHeight) 8.dp else 16.dp
    // ...
}
```

Bekannte Problemstellen:
- Zeilen 97, 108, 128-130, 141, 183, 191, 204: Feste Spacer (~120dp gesamt)
- Kein Scroll-Container vorhanden
- Keine `navigationBarsPadding()` fuer Window Insets

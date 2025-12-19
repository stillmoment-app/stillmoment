# Ticket android-037: App-Icon an iOS angleichen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das Android App-Icon soll durch das iOS-Icon ersetzt werden, damit beide Plattformen ein einheitliches Erscheinungsbild haben.

## Warum

Aktuell unterscheiden sich die Icons visuell stark (iOS: Gradient-Ring, Android: einfache Kreise). Ein einheitliches Icon staerkt die Markenidentitaet und vermeidet Verwirrung bei plattformuebergreifenden Nutzern.

---

## Akzeptanzkriterien

- [ ] Android verwendet das gleiche Icon-Design wie iOS (Gradient-Ring)
- [ ] Adaptive Icons (Android 8.0+) funktionieren korrekt
- [ ] Legacy Icons (Android < 8.0) funktionieren korrekt
- [ ] Icon wird in allen Launcher-Formen korrekt dargestellt (rund, eckig, Squircle)
- [ ] Build laeuft erfolgreich

---

## Manueller Test

1. App auf Android-Geraet oder Emulator installieren
2. Launcher oeffnen und App-Icon pruefen
3. Erwartung: Gradient-Ring Icon wie iOS (blau-orange Gradient)

---

## Referenz

- iOS-Icon: `ios/StillMoment/Assets.xcassets/AppIcon.appiconset/AppIcon-1024x1024.png`
- Android-Icon: `android/app/src/main/res/mipmap-anydpi-v26/`

---

## Hinweise

- Hintergrundfarbe fuer Adaptive Icon: #5B7C8A (blau-grau, passend zum iOS-Gradient)
- PNG-Generierung aus iOS-Icon mit macOS `sips` Tool
- Foreground-PNGs in 5 Groessen: 108, 162, 216, 324, 432 px
- Legacy-Icons in 5 Groessen: 48, 72, 96, 144, 192 px

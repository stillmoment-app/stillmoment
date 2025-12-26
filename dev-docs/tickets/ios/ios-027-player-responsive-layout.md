# Ticket ios-027: GuidedMeditationPlayerView Responsive Layout

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die GuidedMeditationPlayerView soll sich besser an verschiedene Bildschirmgroessen anpassen - sowohl kurze Screens (iPhone SE Landscape) als auch lange Screens (iPhone 15 Pro Max).

## Warum

Aktuell verwendet die View feste Button-Groessen und Spacing-Werte. Bei iPhone SE im Landscape werden Buttons gequetscht, bei langen Titeln wird Text abgeschnitten. Auf langen Screens entstehen unnoetig grosse Luecken.

---

## Akzeptanzkriterien

- [ ] Responsive Button-Groessen (Dynamic Type oder GeometryReader)
- [ ] Titel passt auf alle Bildschirmgroessen (flexibles lineLimit)
- [ ] Spacing passt sich Bildschirmbreite an
- [ ] SwiftUI Previews fuer: iPhone SE, iPhone SE Landscape, iPhone 15 Pro Max
- [ ] Controls bleiben gut erreichbar auf allen Bildschirmgroessen

---

## Manueller Test

1. Player mit langer Meditation oeffnen (langer Titel)
2. iPhone SE im Landscape testen (Simulator)
3. iPhone 15 Pro Max testen
4. Erwartung: Titel lesbar, Buttons nicht gequetscht, keine riesigen Luecken

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Vergleich: TimerView hat bereits responsive Layout (ios-026)

---

## Hinweise

**Preview-Strategie (ohne Simulator pruefen):**
```swift
#Preview("iPhone SE") {
    GuidedMeditationPlayerView(...)
        .previewDevice("iPhone SE (3rd generation)")
}

#Preview("iPhone SE Landscape", traits: .landscapeLeft) {
    GuidedMeditationPlayerView(...)
}

#Preview("iPhone 15 Pro Max") {
    GuidedMeditationPlayerView(...)
        .previewDevice("iPhone 15 Pro Max")
}
```

Bekannte Problemstellen:
- Zeilen 107, 118, 132: Buttons mit festen Groessen (32px, 64px)
- Zeile 55: `lineLimit(2)` schneidet lange Titel ab
- Zeile 101: `HStack(spacing: 40)` zu eng auf schmalen Screens
- Zeile 56: `minimumScaleFactor(0.7)` macht Text zu klein

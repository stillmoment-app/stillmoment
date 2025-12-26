# Ticket ios-027: GuidedMeditationPlayerView Responsive Layout

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die GuidedMeditationPlayerView soll sich besser an verschiedene Bildschirmgroessen anpassen - kleine Phones (iPhone SE) bis große Phones (iPhone 15 Pro Max).

## Warum

Aktuell verwendet die View feste Button-Groessen und Spacing-Werte. Bei langen Titeln wird Text abgeschnitten. Auf langen Screens entstehen unnoetig grosse Luecken.

**Hinweis:** App ist Portrait-only (shared-012), daher keine Landscape-Unterstuetzung noetig.

---

## Akzeptanzkriterien

- [ ] Responsive Button-Groessen (Dynamic Type oder GeometryReader)
- [ ] Titel passt auf alle Bildschirmgroessen (flexibles lineLimit)
- [ ] Spacing passt sich Bildschirmhoehe an (isCompactHeight Pattern)
- [ ] SwiftUI Previews fuer: iPhone SE, iPhone 15, iPhone 15 Pro Max
- [ ] Controls bleiben gut erreichbar auf allen Bildschirmgroessen

---

## Manueller Test

1. Player mit langer Meditation oeffnen (langer Titel)
2. iPhone SE testen (Simulator)
3. iPhone 15 Pro Max testen
4. Erwartung: Titel lesbar, Buttons nicht gequetscht, keine riesigen Luecken

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Vergleich: TimerView hat bereits responsive Layout mit `isCompactHeight` Pattern (ios-026)

---

## Hinweise

**Preview-Strategie:**
```swift
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    GuidedMeditationPlayerView(...)
}

#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    GuidedMeditationPlayerView(...)
}

#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    GuidedMeditationPlayerView(...)
}
```

**Responsive Pattern (siehe TimerView):**
```swift
let isCompactHeight = geometry.size.height < 700
let buttonSize: CGFloat = isCompactHeight ? 48 : 64
let spacing: CGFloat = isCompactHeight ? 24 : 40
```

Bekannte Problemstellen:
- Zeilen 107, 118, 132: Buttons mit festen Groessen (32px, 64px)
- Zeile 55: `lineLimit(2)` schneidet lange Titel ab
- Zeile 101: `HStack(spacing: 40)` zu eng auf kleinen Screens
- Zeile 56: `minimumScaleFactor(0.7)` macht Text zu klein

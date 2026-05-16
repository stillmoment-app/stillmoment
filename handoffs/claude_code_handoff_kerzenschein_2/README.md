# Handoff: Kerzenschein 2.0 — Theme Refinement (Dark + Light)

## Übersicht

Dies ist ein **Theme-Refinement** für Still Moment, keine neuen Screens. Beide Modi werden überarbeitet, der Mechanismus ist in beiden derselbe:

- **Dark · Lifted Warm** — Karten lösen sich gegen alle drei Gradient-Stops über einen Helligkeits-Lift; warmer Border statt neutral; weicher Bottom-Fade in den Akzent-Stop.
- **Light · Sunrise Confident** — gleicher Mechanismus, gespiegelt: Karte heller als bg-top, warmer Schatten als strukturelle Definition (statt optional wie im Dark). Sunrise-Verlauf bleibt, aber gesättigt statt pastellig. Festere Tinte, plastischerer Play-Button.

**Wir liefern bewusst nur 2 Screens** (Library + Timer Idle) als Validierungs-Vehikel. Die eigentliche Lieferung sind die **Tokens** — sobald die in `ThemeColors+Palettes.swift` korrekt sitzen, propagieren sie sich durch alle anderen Screens, die die Slots schon benutzen. Wir wollen das System einmal auf Device sehen, bevor wir den Rest durchziehen.

## Über die Design-Dateien

`Theme Pair Preview.html` ist eine **HTML-Design-Referenz**, kein Produktionscode. In SwiftUI mit den etablierten Patterns nachbauen.

## Fidelity

**High-fidelity.** Alle Hex-Werte, Opacities, Shadow-Stops und Stroke-Widths sind final. Pixelgenau übernehmen.

---

## Was sich ändert — die drei Mechanismen + Tabbar

### 1. Karten-Lift gegen den Gradient

Die Karte muss sich gegen **alle drei Gradient-Stops** trennen. Lösung: Karten-Helligkeit so wählen, dass sie zwischen den extremsten Stops liegt und sich nach oben wie unten abhebt.

| Modus | Karte | gegen |
|---|---|---|
| Dark | `#2E211A` | bg-mid `#321F19` (heller als mid, dunkler als bot) |
| Light | `#FFF6E6` | bg-top `#FBEEDB` (heller als top, deutlich heller als bot) |

### 2. Warmer Border statt neutral

Ein neutraler/grauer Border würde im warmen Kontext kühl wirken. Beide Modi nutzen denselben Hue (Kupfer/Erde), nur anderes Alpha.

| Modus | cardBorder |
|---|---|
| Dark | solid `#4E382C` |
| Light | `rgba(120, 55, 28, 0.11)` |

### 3. Warmer Doppelschatten

Im Dark optional (Lift trägt schon viel allein), im **Light strukturell obligatorisch**, weil weniger Luminance-Spielraum existiert. Beide nutzen denselben Doppel-Shadow: scharfer Kontakt + weicher Body, beide warm getönt.

| Modus | cardShadow |
|---|---|
| Dark | `0 1px 2px rgba(0,0,0,0.25), 0 8px 20px rgba(0,0,0,0.30)` |
| Light | `0 1px 2px rgba(120,55,28,0.06), 0 6px 16px rgba(120,55,28,0.10)` |

### 4. Soft Fade (beide Modi)

Eigenständiger neuer Token, paint-Mechanismus identisch in Dark und Light: vom transparenten Top über `--t-fade-mid` in `--t-bg-bot` auslaufen lassen. Sitzt **über** der Scroll-Region, **unter** der Tabbar (z-Index zwischen Content und Tabbar).

```
linear-gradient(180deg,
  transparent 0%,
  var(--t-fade-mid) 55%,
  var(--t-bg-bot) 92%)
```

Höhe: 140 px (gemessen am 393er-Frame). Pointer-events: none.

| Modus | fadeMid |
|---|---|
| Dark | `rgba(93, 58, 47, 0.78)` (Mahagoni-Smoke) |
| Light | `rgba(232, 160, 116, 0.72)` (Apricot-Smoke) |

### 5. Tabbar — warm getintet, Active-Pill in accent-fill

Die System-Standard-Tabbar liest sich gegen den warmen Gradient + Soft Fade falsch (kühl, fremd). Sie muss zur Theme-Familie gehören. Ist Teil **dieses** Handovers, nicht des zweiten Sweeps.

- **Material/Tint:** warmes Tint statt System-Default. Dark `rgba(46, 33, 26, 0.88)` über `.ultraThinMaterial`-Äquivalent, Light `rgba(255, 246, 230, 0.86)`. Beide mit Blur (`backdrop-filter: blur(20px) saturate(1.4)` → SwiftUI: `.background(.ultraThinMaterial)` + warmer Tint-Overlay).
- **Border:** dünner warmer Border (cardBorder-Token wiederverwenden).
- **Active-Pill:** Hintergrund `interactive @ 0.10–0.18` (`--t-accent-fill`), Label + Glyph in `interactive`. Inactive-Items in `textSecondary`.
- **Pragmatischer Fallback:** Wenn die System-`TabView`-Architektur custom-Material zu invasiv macht (Accessibility / Auto-Switching Dark↔Light), reicht als Minimum: `UITabBar.appearance().tintColor = interactive`. Active-Pill kann dann entfallen — der Tint allein deckt 80 % der visuellen Wirkung.

---

## Token-Map (alt → neu)

### Dark

| Slot | Aktuell | Neu — Lifted Warm |
|---|---|---|
| `backgroundPrimary` | `#1A100C` | `#1A100C` *(unverändert)* |
| `backgroundSecondary` | `#321F19` | `#321F19` *(unverändert)* |
| `accentBackground` | `#5D3A2F` | `#5D3A2F` *(unverändert)* |
| `cardBackground` | `#252322` (neutral) | **`#2E211A`** (warm, lifted) |
| `cardBorder` | `#3E3C3B` (neutral) | **`#4E382C`** (warm) |
| `cardShadow` *(neu)* | — | `0 1px 2px rgba(0,0,0,0.25), 0 8px 20px rgba(0,0,0,0.30)` |
| `divider` | `rgba(242,228,211,0.05)` (zu schwach, Trenner zwischen Tracks einer Lehrerin kaum sichtbar) | **`rgba(242,228,211,0.10)`** (doppelt — klar sichtbar, nicht hart) |
| `fadeMid` *(neu)* | — | `rgba(93, 58, 47, 0.78)` |
| `textPrimary` | `#E5DCCD` | `#E5DCCD` *(unverändert)* |
| `textSecondary` | `#A68A80` | `#A68A80` *(unverändert)* |
| `interactive` (Akzent) | `#C77D63` | `#C77D63` *(unverändert)* |
| `playButton` | flach `#C77D63` | Gradient `#D68A6E → #B06A4F` + Shadow `0 4px 12px rgba(196,122,94,0.4)` + Innen-Highlight-Rim |

### Light

| Slot | Aktuell | Neu — Sunrise Confident |
|---|---|---|
| `backgroundPrimary` | `#FFFBF5` (fast-weiß) | **`#FBEEDB`** (gesättigter Cream) |
| `backgroundSecondary` | `#FFE4D6` (Pastell-Pfirsich) | **`#F6CDA8`** (echter Pfirsich) |
| `accentBackground` | `#FFCBA4` (Pastell-Apricot) | **`#E8A074`** (warmer Apricot, fest) |
| `cardBackground` | `#FFFBF5` (= bg-top, verschmilzt) | **`#FFF6E6`** (heller als bg-top, Lift) |
| `cardBorder` | clear/keiner | **`rgba(120, 55, 28, 0.11)`** (warmer Hauch) |
| `cardShadow` *(neu)* | — | `0 1px 2px rgba(120,55,28,0.06), 0 6px 16px rgba(120,55,28,0.10)` |
| `divider` | `rgba(74,59,50,0.06)` (kaum sichtbar) | **`rgba(120,55,28,0.14)`** (doppelt + Hue an Akzent-Familie gezogen) |
| `fadeMid` *(neu)* | — | `rgba(232, 160, 116, 0.72)` |
| `textPrimary` | `#4A3B32` (Bleistift) | **`#3A2418`** (Tinte, wärmer) |
| `textSecondary` | `#8A5A53` (rosé) | **`#7A4E3C`** (Erdbraun) |
| `interactive` (Akzent) | `#9E5344` | **`#A2503E`** (Spur tiefer) |
| `playButton` | flach `#9E5344` | Gradient `#B85F46 → #7E3A2D` + Shadow `0 4px 12px rgba(126,58,45,0.32)` + Innen-Highlight-Rim |

---

## Swift-Snippet (Vorschlag — anpassen an euer Pattern)

```swift
extension Color {
    // ============== DARK · Lifted Warm ==============
    static let darkBackgroundPrimary   = Color(hex: 0x1A100C)
    static let darkBackgroundSecondary = Color(hex: 0x321F19)
    static let darkAccentBackground    = Color(hex: 0x5D3A2F)
    static let darkCardBackground      = Color(hex: 0x2E211A)   // ← geändert
    static let darkCardBorder          = Color(hex: 0x4E382C)   // ← geändert
    static let darkDivider             = Color(red: 242/255, green: 228/255, blue: 211/255, opacity: 0.10) // ← verstärkt
    static let darkFadeMid             = Color(red: 93/255, green: 58/255, blue: 47/255, opacity: 0.78) // ← neu
    static let darkTextPrimary         = Color(hex: 0xE5DCCD)
    static let darkTextSecondary       = Color(hex: 0xA68A80)
    static let darkInteractive         = Color(hex: 0xC77D63)
    static let darkPlayGradientTop     = Color(hex: 0xD68A6E) // ← neu (Gradient-Top)
    static let darkPlayGradientBot     = Color(hex: 0xB06A4F) // ← neu (Gradient-Bot)

    // ============== LIGHT · Sunrise Confident ==============
    static let lightBackgroundPrimary   = Color(hex: 0xFBEEDB) // ← geändert
    static let lightBackgroundSecondary = Color(hex: 0xF6CDA8) // ← geändert
    static let lightAccentBackground    = Color(hex: 0xE8A074) // ← geändert
    static let lightCardBackground      = Color(hex: 0xFFF6E6) // ← geändert
    static let lightCardBorder          = Color(red: 120/255, green: 55/255, blue: 28/255, opacity: 0.11) // ← geändert
    static let lightDivider             = Color(red: 120/255, green: 55/255, blue: 28/255, opacity: 0.14) // ← verstärkt + Hue
    static let lightFadeMid             = Color(red: 232/255, green: 160/255, blue: 116/255, opacity: 0.72) // ← neu
    static let lightTextPrimary         = Color(hex: 0x3A2418) // ← geändert
    static let lightTextSecondary       = Color(hex: 0x7A4E3C) // ← geändert
    static let lightInteractive         = Color(hex: 0xA2503E) // ← geändert
    static let lightPlayGradientTop     = Color(hex: 0xB85F46) // ← neu (Gradient-Top)
    static let lightPlayGradientBot     = Color(hex: 0x7E3A2D) // ← neu (Gradient-Bot)
}

// Card shadow als ViewModifier — beide Modi nutzen identische
// Schatten-Geometrie, nur die Farben kommen aus dem Theme:
struct LiftedCardShadow: ViewModifier {
    let isDark: Bool
    func body(content: Content) -> some View {
        let contactColor = isDark ? Color.black.opacity(0.25)
                                  : Color(red: 120/255, green: 55/255, blue: 28/255, opacity: 0.06)
        let bodyColor   = isDark ? Color.black.opacity(0.30)
                                 : Color(red: 120/255, green: 55/255, blue: 28/255, opacity: 0.10)
        let bodyRadius: CGFloat = isDark ? 20 : 16
        let bodyY: CGFloat      = isDark ? 8  : 6
        content
            .shadow(color: contactColor, radius: 2, x: 0, y: 1)
            .shadow(color: bodyColor,    radius: bodyRadius, x: 0, y: bodyY)
    }
}
```

---

## Screen 1 — Library (Geführte Meditationen)

### Was zu zeigen ist (Validierung)

- Karten (`Group` mit Tracks) liegen sichtbar **über** dem Gradient-Hintergrund — der Lift muss am oberen Rand der Scrollarea **und** am Akzent-Stop unten funktionieren (Scroll-Test!).
- Track-Divider zwischen mehreren Titeln einer Lehrerin sind **klar sichtbar** als feine Linie (`--t-divider`, doppelte Opacity gegenüber vorher), aber nie als harte Trennung. Hue gehört in die Akzent-Familie (warm), nicht grau.
- Play-Button auf jeder Track-Row ist plastisch (Gradient + Highlight-Rim oben), nicht flach.
- Soft Fade läuft am unteren Rand sauber in den Akzent-Stop aus, **unter** der Tabbar.
- Tabbar hat Blur (`backdrop-filter: blur(20px) saturate(1.4)` → SwiftUI: `.background(.ultraThinMaterial)`-Äquivalent + warmes Tint).
- Active-Tab-Pill verwendet `accentBackground` (im neuen Sprachgebrauch: `--t-accent-fill`, eine `0.10–0.18`-Variante des Akzents).

### Akzeptanzkriterium (Library)

> Eine Karte am oberen Rand (gegen bg-top) und eine Karte am unteren Rand (gegen accentBackground) lesen sich **gleich gut** als gehobene Elemente. Wenn unten der Lift zerfällt, ist `cardBackground` falsch gewählt.

---

## Screen 2 — Timer Idle

### Was zu zeigen ist (Validierung)

- **Headline** „Wie viel Zeit schenkst du dir?" — Newsreader, weight 400, ~22 px, zentriert, in `textPrimary` (nicht im Akzent).
- **Ring** — hauchdünn:
  - Track: `stroke="interactive", opacity 0.32, width 1px`
  - Progress-Arc: `stroke="interactive", opacity 0.72, width 1.5px, stroke-linecap: round`
  - Drag-Handle: kleine Perle (r=5) in `interactive` + Glow `drop-shadow(0 0 8px interactive)`
  - Geometrie: r=91 in einer 236×236 viewBox, dargestellt bei ~204px
  - Ist exakt derselbe Ring wie im **Running Timer**, nur dass die Progress-Länge dem Slider folgt statt der Restzeit.
- **Wert in der Mitte**: Newsreader 60–68 px, weight 300, `letter-spacing: -0.02em`, `font-variant-numeric: tabular-nums`. Eyebrow „MINUTEN" 10 px, letter-spacing 0.28em, uppercase, in `textSecondary`.
- **Settings-Liste** — **keine Karten**, nur ruhige Trenner:
  - Erster + jeder weitere Row: `border-top` und `border-bottom` in `--t-divider` (warm, sehr leise)
  - Label links in `textPrimary`, Wert rechts in `interactive` (Akzent!), Chevron in `textSecondary @ 0.6`
  - Padding 10 px vertikal pro Row, horizontaler Outer-Margin 26–28 px
- **CTA „Beginnen"** — plastischer Kupfer-Pill:
  - Padding `14px 32px`, border-radius 100px
  - Background = `playButton`-Gradient
  - Shadow = `playButton`-Shadow
  - Innerer Highlight-Rim: `linear-gradient(180deg, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0) 50%)` als 1px-inset-Pseudo (oder Overlay-Capsule)
  - Play-Glyph + „Beginnen"-Text in `on-accent` Farbe (Dark: `#1A100C`, Light: `#FFF6E6`)
- **Tabbar identisch zu Library** (Timer-Tab aktiv).

### Akzeptanzkriterium (Timer Idle)

> Der Ring sieht **sofort verwandt** zum Running-Timer-Ring aus (gleiche Strichstärken, gleiche Perle, gleicher Glow). Die Wert-Spalte in der Settings-Liste zieht die Aufmerksamkeit, ohne dass die Liste in Karten aufbricht.

---

## Implementierungs-Reihenfolge

1. **`ThemeColors+Palettes.swift`** — alle Token-Werte ersetzen / hinzufügen (s.o.). Vergiss `divider` nicht — Vorher-Werte waren halb so stark.
2. **`LiftedCardShadow` ViewModifier** anlegen (oder in eurer bestehenden Card-Component verdrahten).
3. **Card-Component** (Library Group, Search Bar, Library Head Pill, Tabbar) — Shadow-Modifier anwenden, neuen Border-Token verwenden.
4. **Soft Fade Overlay** — als wiederverwendbare `Rectangle().fill(LinearGradient(...))` mit `allowsHitTesting(false)`, z-Order zwischen Scroll-Content und Tabbar.
5. **Tabbar** — warmes Tint-Material, dünner Border, Active-Pill mit `accent-fill` (Fallback: nur `tintColor = interactive` wenn System-`TabView` zu invasiv).
6. **Library Screen** — visuell prüfen (Akzeptanzkriterium oben).
7. **Timer Idle Screen**:
   - Ring auf 1px/1.5px reduzieren (war vorher dicker), Perle einbauen.
   - Settings von Karten- auf Listen-Form umstellen (falls noch Karten).
   - CTA-Capsule mit Play-Gradient + Highlight-Rim.

---

## Was wir _nicht_ in diesem Handover liefern

- **Running Timer** (Sanduhr-Vessel) — bleibt unverändert, das Theme-Refinement wirkt sich auf ihn nicht aus (das Vessel hat eigene, vom Theme entkoppelte Farben).
- **Player, Settings-Sheets, Onboarding** — sobald die Tokens stimmen, ziehen sich diese Screens automatisch mit. Wenn doch was ausbricht, fixen wir das im zweiten Sweep nach diesem Handover.
- **Animations-Verhalten** — der Atembewegungs-Glow des Running Timers und etwaige Sheet-Transitions bleiben unangetastet.

---

## Dateien in diesem Bundle

| Datei | Zweck |
|---|---|
| `README.md` | Dieses Dokument |
| `Theme Pair Preview.html` | HTML-Referenz mit beiden Modi · Library + Timer Idle nebeneinander |

Im Browser öffnen für visuelle Referenz. Tokens und Mechanismen aus diesem README sind die Lieferung — das HTML ist nur die Anschauung.

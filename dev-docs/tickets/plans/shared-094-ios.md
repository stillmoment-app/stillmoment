# Implementierungsplan: shared-094 (iOS)

Ticket: [shared-094](../shared/shared-094-theme-refinement-kerzenschein.md)
Erstellt: 2026-05-16

---

## Annahmen

- **LiftedCardShadow als ColorScheme-aware ViewModifier**, nicht als Theme-Token. Werte werden im Modifier hardcoded gegen `@Environment(\.colorScheme)` geschaltet — analog zum bestehenden Pattern in `CardRowBackground`. Begruendung: Single-Theme-System, der Mehrwert einer zusaetzlichen Token-Indirektion ist hier nicht gegeben. Wenn spaeter doch eine zweite Palette dazukommt, kann das nachgezogen werden.
- **Neuer Slot `divider`** in `ThemeColors` (Light: `rgba(120,55,28,0.14)`, Dark: `rgba(242,228,211,0.10)`). Wird einheitlich fuer Library-Track-Trenner UND Idle-Settings-Trenner verwendet. Der bestehende derived `settingsDivider` wird auf den neuen `divider` umgestellt (Wert ueberschreibt die bisherige `controlTrack.opacity(0.30)`-Herleitung). Begruendung: Beide Stellen wollen den gleichen Hue/Helligkeitseindruck; zwei Tokens fuer dieselbe semantische Rolle waeren Pflegelast.
- **Soft Fade pro Screen** (Library, Timer-Idle) als `.overlay(alignment: .bottom)` auf den jeweiligen Content-Container, nicht als globaler App-Level-Overlay. Begruendung: Die Z-Order zwischen Scroll-Content und Tabbar muss klar definiert sein, und beide Screens haben unterschiedliche Toolbars / NavigationStacks.
- **`textOnInteractive` im Light wird angepasst** von `.white` auf das warme Cream `#FFF6E6` (= neuer `cardBackground` Light). Begruendung: Auf dem neuen Play-Gradient (`#B85F46 → #7E3A2D`) sieht reines Weiss zu kalt aus; das warme Cream zieht die Akzent-Geometrie zusammen. WCAG-Kontrast bleibt deutlich ueber 4.5.
- **Bestehende Button-Geometrie bleibt**: `WarmPrimary` behaelt `buttonCornerRadiusPrimary` (28) und das aktuelle Padding. Nur Fuellung (Gradient statt Solid) und Inner-Highlight-Rim kommen dazu.
- **Library Play-Button als eigene wiederverwendbare View**: `PlayButtonCircle` (oder ViewModifier), nicht inline im Row, damit Library + Search-Results den gleichen Look bekommen.
- **`UITabBarAppearance` wird in `ThemeRootView` erweitert**: bestehender `applyTabBarAppearance(_:)` bekommt zusaetzlich `backgroundEffect = UIBlurEffect(...)`, getoenten `backgroundColor`, und `selectionIndicatorImage` als gerenderte Pille. Pattern existiert bereits — Erweiterung statt Neuanfang.
- **Soft-Fade-Hoehe 140px** wie im Handover. Nicht responsiv an Geraet/Insets gekoppelt; das Handover ist gegen den 393er-Frame gemessen, kleinere/groessere Geraete sehen die gleichen 140px.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Presentation/Theme/ThemeColors.swift` | Presentation | Erweitern | Neue Slots `playGradientTop`, `playGradientBot`, `divider`. `settingsDivider` wird zu Alias auf `divider`. `textOnInteractive` semantisch unveraendert, aber Wert in der Palette aktualisiert. |
| `Presentation/Theme/ThemeColors+Palettes.swift` | Presentation | Aendern | Light: gesaettigter Sunrise + warmer Card + warmer Border + waermere Tinte + Play-Gradient + warmer Divider. Dark: cardBackground/cardBorder warm, Play-Gradient, verstaerkter Divider. |
| `Presentation/Views/Shared/CardRowBackground.swift` | Presentation | Refactoring | Light = warmer Doppelschatten (statt einfachem grauen Shadow) + warmer Border. Dark = warmer Border (Lift kommt von hellerer Card-Farbe) + optional dezenter Doppelschatten. |
| `Presentation/Views/Shared/ButtonStyles.swift` | Presentation | Refactoring | `WarmPrimary`: Capsule mit `LinearGradient(playGradientTop → playGradientBot)`, warmer Schlagschatten, Inner-Highlight-Rim als 1pt-Overlay oben. |
| `Presentation/Views/Shared/SoftFadeOverlay.swift` | Presentation | NEU | Wiederverwendbare View: 140pt hohes Bottom-Overlay mit `LinearGradient(.clear → fadeMid → backgroundBot)`, `.allowsHitTesting(false)`. Fade-Farben aus Theme. |
| `Presentation/Views/Shared/PlayButtonCircle.swift` | Presentation | NEU | Plastischer runder Play-Button (Circle mit `playGradientTop → playGradientBot`, Schlagschatten, Inner-Highlight-Rim, Play-Glyph in `textOnInteractive`). Reusable fuer Library + Search-Results. |
| `Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Presentation | Aendern | `playButton(for:)` nutzt `PlayButtonCircle`. Content-Container bekommt `.overlay(alignment: .bottom) { SoftFadeOverlay() }`. List-Row-Separator auf `theme.divider` (`.listRowSeparatorTint(_:)` mit `.visible`). |
| `Presentation/Views/GuidedMeditations/SearchResultsListView.swift` | Presentation | Aendern | Analog: Play-Button auf `PlayButtonCircle` umstellen. |
| `Presentation/Views/Timer/TimerView.swift` | Presentation | Aendern | Idle-Content bekommt Soft-Fade-Overlay zwischen Liste und Tabbar. CTA-Button-Wiedergabe bleibt unveraendert (`warmPrimaryButton()` zieht den neuen Stil automatisch). |
| `Presentation/Theme/ThemeRootView.swift` | Presentation | Erweitern | `applyTabBarAppearance(_:)` erweitert um Blur (`UIBlurEffect(style: .systemUltraThinMaterial)`), warmen `backgroundColor` (Dark `rgba(46,33,26,0.88)`, Light `rgba(255,246,230,0.86)`), Top-`shadowImage` in `cardBorder`-Farbe, und `selectionIndicatorImage` als gerenderte Pille mit `interactive @ 0.10-0.18`. Selected-Item Tint = `interactive`, Unselected = `textSecondary`. |
| `StillMomentTests/Presentation/WCAGContrastTests.swift` | Tests | Aendern | `testLightModeCardBorderIsClear` durch `testLightModeCardBorderIsWarmTinted` ersetzen (Pruefung auf warmen Hue + niedrige Opacity). Bestehende Kontrast-Tests laufen gegen neue Werte. |
| `StillMomentTests/Presentation/ThemeColorsTests.swift` | Tests | Erweitern | Tests fuer neue Slots: `playGradientTop`/`playGradientBot` weichen zwischen Light/Dark ab. `divider` weicht zwischen Light/Dark ab und ist nicht clear. `settingsDivider` zeigt nun auf `divider` (Alias-Test). |

---

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `UITabBarAppearance.backgroundEffect: UIBlurEffect?` | iOS 13+ | UIKit | Setzt den Blur-Effekt; in Kombination mit `backgroundColor` als Tint funktioniert das wie Material. |
| `UITabBarAppearance.selectionIndicatorImage: UIImage?` | iOS 13+ | UIKit | Bild fuer das aktive Tab-Highlight. Render via `UIGraphicsImageRenderer` zur Laufzeit (runde Pille mit `accentBackground`). |
| `UIBlurEffect(style: .systemUltraThinMaterial)` | iOS 13+ | UIKit | Materialstil, der Hintergrund durchscheinen laesst. Adaptiv zu Light/Dark, passt zur warmen Tint-Schicht. |
| `LinearGradient(colors:startPoint:endPoint:)` | iOS 13+ | SwiftUI | Fuer Karten-/Button-/Fade-Gradients. |
| `.allowsHitTesting(_:)` | iOS 13+ | SwiftUI | Soft-Fade darf keine Taps schlucken. |
| `.overlay(alignment:content:)` | iOS 15.4+ | SwiftUI | Erfuellt iOS 16 Minimum. |
| `Color(red:green:blue:opacity:)` | iOS 13+ | SwiftUI | Bestehende Konvention in `ThemeColors+Palettes.swift`. |

---

## Design-Entscheidungen

### 1. Shadow-Werte hardcoded vs. neue Theme-Tokens

**Trade-off:** Tokens machen Werte zentral aenderbar; hardcoded ViewModifier ist einfacher und folgt dem bestehenden `CardRowBackground`-Pattern.
**Entscheidung:** Hardcoded im Modifier (mit ColorScheme-Switch). Nach shared-093 ist nur ein Theme aktiv, und die Werte sind Teil des "Shadow-Mechanismus" — nicht der Farbe. Wenn das zweite Theme zurueckkommt, kann man das nachziehen.

### 2. PlayButtonCircle als eigene View vs. inline in Library

**Trade-off:** Inline ist weniger Datei-Overhead; eigene View vermeidet Code-Duplikation zwischen Library-List und Search-Results und ermoeglicht spaeter andere Stellen (Player o.ae.) den gleichen Look zu uebernehmen.
**Entscheidung:** Eigene View. Library und Search-Results haben heute schon getrennte `playButton(for:)`-Methoden; die zentralisieren wir.

### 3. textOnInteractive Light: weiss vs. warmes Cream

**Trade-off:** Weiss ist der heutige Stand und maximaler Kontrast; das warme Cream zieht den Akzent-Bereich farblich zusammen und wirkt waermer.
**Entscheidung:** Warmes Cream (`#FFF6E6`, gleich `cardBackground` Light). WCAG bleibt > 4.5 auf dem Gradient (gemessen am Mittel-Stop ~ `#9B4D3A`). Konsistenter mit der "Lifted Warm"-Logik des Handovers.

### 4. Soft-Fade pro Screen vs. global

**Trade-off:** Global ist eine Stelle; pro Screen erlaubt unabhaengige Z-Order und respektiert NavigationStack/Toolbar-Topologie.
**Entscheidung:** Pro Screen. Library und Timer haben unterschiedliche NavigationStacks, ein App-Level-Overlay wuerde Sheets und Toolbar-Geometrie irritieren.

---

## Refactorings

1. **CardRowBackground neu strukturieren** — Light bekommt warmen Doppelschatten (statt einfachem grauen), Dark bekommt warmen Border (statt neutralem). Risiko: niedrig — wird in `.insetGrouped`-Lists und in `HowToImportStepCard` benutzt; Lift soll dort genauso wirken. 2 Tests betreffen die Methode (`testLightModeCardBorderIsClear` muss umgeschrieben werden).
2. **WarmPrimary umbauen** — von `RoundedRectangle.fill(interactive)` auf `Capsule.fill(LinearGradient(...))` + Overlay-Highlight. Risiko: niedrig — derselbe Button wird mehrfach im Empty-State, Timer-Idle, MeditationCompletion, AppSettings benutzt; Geometrie bleibt gleich, nur die Fuellung aendert sich.
3. **TabBar-Appearance erweitern** — der bestehende `applyTabBarAppearance(_:)`-Hook in `ThemeRootView` bekommt drei zusaetzliche Konfigurationen (Blur, Tint, Indicator). Risiko: mittel — `UIAppearance` wirkt nur auf neue TabBar-Instanzen; `.id(self.resolvedColors)` in `ThemeRootView` erzwingt bei Theme-/Mode-Wechsel einen Neuaufbau, was wir bereits wegen Slider/Picker brauchen — sollte hier auch greifen.

---

## Fachliche Szenarien

### AK-1: Karten-Lift gegen Gradient

- Gegeben: Library-Tab geoeffnet, Light Mode
  Wenn: Karten am oberen Rand sichtbar (gegen `backgroundPrimary`)
  Dann: Karte hebt sich durch warmen Doppelschatten klar ab

- Gegeben: Library-Tab geoeffnet, Light Mode
  Wenn: Bis zum unteren Rand gescrollt (Karte liegt ueber `accentBackground`)
  Dann: Karte ist immer noch klar als gehobenes Element lesbar (kein Verschwimmen)

- Gegeben: Library-Tab geoeffnet, Dark Mode
  Wenn: Karten an beiden Enden der Scroll-Region sichtbar
  Dann: Karte hebt sich durch hellere Card-Farbe (Lift) und warmen Border ab; kein grauer/kuehler Eindruck

### AK-2: Hauptknopf "Beginnen"

- Gegeben: Timer-Idle, Light Mode
  Wenn: "Beginnen"-Knopf gerendert
  Dann: Sichtbarer vertikaler Verlauf (heller oben, tiefer unten), weicher warmer Schlagschatten unter dem Knopf, 1pt warmes Inner-Highlight am oberen Rand

- Gegeben: Timer-Idle, Dark Mode
  Wenn: "Beginnen"-Knopf gerendert
  Dann: Analoger Eindruck mit Dark-Werten; Play-Glyph und Text gut lesbar in `textOnInteractive`

### AK-3: Soft Fade unten

- Gegeben: Library mit vielen Eintraegen, Scroll-Bereich endet ueber der Tabbar
  Wenn: Bis zum unteren Rand gescrollt
  Dann: Letzte Karten laufen sichtbar in den Akzent-Stop des Hintergrunds aus, kein harter Schnitt zwischen Content und Tabbar

- Gegeben: Library-Tab geoeffnet
  Wenn: User tippt auf eine Stelle innerhalb des Fade-Bereichs, an der eine Karte sichtbar ist
  Dann: Karte reagiert weiterhin auf Tap (Fade blockiert keine Interaktion)

### AK-4: Tabbar

- Gegeben: App-Start auf Library, Light Mode
  Wenn: Tabbar sichtbar
  Dann: Inhalt scheint durch den Blur durch, warmer Tint ueberlagert; aktiver Tab traegt eine deutlich sichtbare Akzent-Pille; ein dezenter warmer Border trennt die Tabbar von der Scroll-Region

- Gegeben: Mode-Wechsel von Light auf Dark im laufenden Betrieb
  Wenn: Tabbar nach dem Wechsel angezeigt wird
  Dann: Tint, Blur und Pille verwenden die Dark-Werte (UIAppearance-Refresh greift)

### AK-7: Track-Divider in Library

- Gegeben: Library mit mehreren Titeln derselben Lehrerin
  Wenn: Zwei Titel uebereinander gerendert sind
  Dann: Zwischen den beiden Rows ist eine feine, warm-getoente Linie sichtbar — klar erkennbar, aber nicht hart

- Gegeben: Light und Dark Mode
  Wenn: Track-Divider gerendert
  Dann: Linie liegt farblich in der warmen Akzent-Familie, nicht in System-Grau

### AK-5: Light-Mode-Palette gesaettigt

- Gegeben: Library im Light Mode
  Wenn: Hintergrund-Gradient sichtbar
  Dann: Visuell deutlich gesaettigter Sunrise-Eindruck (kein pastelliges Cream-zu-Apricot mehr)

- Gegeben: Text-Elemente im Light Mode
  Wenn: Body- und Caption-Text gerendert
  Dann: Tinte wirkt warm-erdbraun, nicht graubraun

### AK-6: Dark-Mode-Palette konsistent

- Gegeben: Library im Dark Mode
  Wenn: Karten ueber dem Hintergrund-Gradient sichtbar
  Dann: Karten heben sich gegen `backgroundSecondary` (heller als Card) und gegen `accentBackground` (dunkler als Card) gleichermassen ab — Lift trifft den mittleren Bereich

### AK-Tests: WCAG bleibt erfuellt

- Gegeben: Neue Light/Dark-Palette
  Wenn: WCAG-Kontrast-Tests laufen
  Dann: Alle Text-on-Background-Kombinationen erreichen 4.5:1, controlTrack-on-cardBackground erreicht 3:1

- Gegeben: Neuer cardBorder im Light
  Wenn: Border-Visibility-Test laeuft
  Dann: Border ist nicht clear, hat aber niedrige Opacity (~0.11) und warmen Hue

---

## Reihenfolge der Akzeptanzkriterien

TDD-orientiert; Tokens bilden die Grundlage, alle UI-Aenderungen bauen darauf auf.

1. **AK-Tests + AK-5/6 (Palette)** — Tokens und Werte zuerst. Failing Test fuer `cardBorder` Light (warm-getoent statt clear), Werte in `ThemeColors+Palettes.swift` aktualisieren, WCAG-Tests laufen lassen. Neue Slots `playGradientTop`/`playGradientBot`/`divider` einfuehren mit Test-Coverage (Light != Dark, alle nicht `.clear`). `settingsDivider` auf `divider` umstellen.
2. **AK-1 (Karten-Lift)** — `CardRowBackground` refactoren. Validierung visuell an Library oben + unten.
3. **AK-7 (Track-Divider)** — `.listRowSeparatorTint(theme.divider)` in Library-List. Validierung an zwei Tracks derselben Lehrerin.
4. **AK-2 (Hauptknopf)** — `WarmPrimary` mit Gradient + Highlight-Rim. Validierung an Timer-Idle "Beginnen".
5. **Library Play-Button** — `PlayButtonCircle` neu, Library + Search-Results umstellen.
6. **AK-3 (Soft Fade)** — `SoftFadeOverlay` neu, in Library + Timer-Idle einbauen.
7. **AK-4 (Tabbar)** — `applyTabBarAppearance(_:)` erweitern um Blur + Tint + Border + Indicator-Pille.

---

## Vorbereitung

Keine externen Schritte noetig (kein Provisioning, keine neuen Pakete, keine Entitlements).

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Snapshot-/Screenshot-Tests gehen rot durch geaenderte Farben | Nach Token-Aenderung Screenshots durchschauen und Referenzen aktualisieren; nicht ausblenden. Fastlane-Screenshots werden in einem separaten Sweep nach Abschluss neu aufgenommen. |
| UITabBar-Refresh bei Mode-Wechsel | `.id(self.resolvedColors)` im `ThemeRootView` erzwingt bereits den Neuaufbau bei Wechsel — bei Bedarf zusaetzlicher `applyTabBarAppearance` aus `onChange(of: resolvedColors)` reicht. Manueller Test pro Modus. |
| Light-Mode Border 0.11 Alpha grenzwertig sichtbar | Test `testLightModeCardBorderIsWarmTinted` prueft Hue + Alpha; visueller Smoketest gegen Handover-HTML. |
| Soft-Fade verdeckt unterste Library-Row | Liste bekommt unten zusaetzliches Padding (etwa 80pt), damit die letzte Karte oberhalb des Fade-Beginns sichtbar bleibt. |
| Play-Gradient Light gegen sehr helle Hintergrundzonen zu kontrastarm | WCAG-Test fuer `textOnInteractive`-on-`playGradient`-Mittelpunkt im Light validiert das vor dem Mergen. |

---

## Offene Fragen

Keine — beide vor Plan-Erstellung geklaert: Library-Play-Button wird plastisch (Gradient + Highlight wie CTA, nur Circle statt Capsule), Tabbar wird via `UITabBarAppearance` mit Blur + Tint + Aktiv-Pille umgesetzt.

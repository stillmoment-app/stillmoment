# Implementierungsplan: shared-086 (iOS)

Ticket: [shared-086](../shared/shared-086-atemkreis-picker-timer-konfig.md)
Erstellt: 2026-05-03
Plattform: iOS (Android folgt sequenziell)

## Ueberblick

Wheel-Picker fuer die Sitzungsdauer wird durch einen **Atemkreis-Picker** ersetzt:
Drag im Ring + zwei radial platzierte +/-Buttons mit Long-Press-Beschleunigung.
Idle-Screen bekommt Headline + Section-Trenner, Cards werden auf Sentence-Case umgestellt
und das Layout skaliert vertikal von iPhone SE bis iPhone 15 Pro Max ohne Scrollen.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/Views/Timer/Components/BreathDial.swift` *(neu)* | Presentation | Anlegen | Atemkreis-Picker als eigene `View` (Canvas + DragGesture, +/-Buttons als Subviews). |
| `Presentation/Views/Timer/Components/BreathDialGeometry.swift` *(neu)* | Presentation | Anlegen | Pure Helper fuer Geste-Mathe: `valueFromAngle`, `clampValue`, `arcEndPoint`, `buttonOffset`. Keine SwiftUI-Imports → unit-testbar ohne Renderer. |
| `Presentation/Views/Timer/Components/BreathDialAcceleration.swift` *(neu)* | Presentation | Anlegen | `LongPressAccelerator` (Combine-Timer / `Task` mit Sleep), kapselt 320 ms Initial-Delay + 80 ms Tick + Cleanup. Unit-testbar via injected `Scheduler` / Clock. |
| `Presentation/Views/Timer/TimerView.swift` | Presentation | Anpassen | `durationWheel(...)` durch `BreathDial(...)` ersetzen. `idleScreen(geometry:)` um Headline (oben), Atemkreis (Mitte), Untertitel (Trenner), Cards umbauen. Spacings responsiv aus `geometry.size.height` ableiten. |
| `Presentation/Views/Timer/Components/SettingCard.swift` | Presentation | Anpassen | `.uppercased()` und `.tracking(1.3)` aus dem Label entfernen — Sentence-Case kommt direkt aus `Localizable.strings`. Zusaetzlich neue Typo-Rolle `.cardLabel` einsetzen (statt `.system`). |
| `Presentation/Views/Timer/Components/SettingCardsGrid.swift` | Presentation | Anpassen | Hinweis-Text "Tippen, um anzupassen" (`settings.card.hint`) entfernen — der neue Section-Trenner "Passe den Timer an" uebernimmt diese Affordance. Key in `Localizable.strings` ebenfalls entfernen (de + en). |
| `Presentation/Views/Shared/Font+Theme.swift` | Presentation | Erweitern | Zwei neue `TypographyRole`s: `.dialValue` (62–76 px, light, leicht negatives tracking, `textPrimary`), `.dialUnit` (~10 px, regular, weites tracking, `textSecondary`). Optional: `.idleHeadline`, `.idleSectionLabel` (oder bestehende `.screenTitle` / `.sectionTitle` wiederverwenden). |
| `Presentation/Theme/ThemeColors.swift` | Presentation | Erweitern | Neue semantische Tokens: `dialActiveArcGradient` (LinearGradient, von `interactive` zu `interactive.opacity(0.7)`), `dialDropletHalo` (`interactive.opacity(0.18)`), `dialDropletCore` (= `interactive`), `dialDropletOuterFill` (= `backgroundPrimary` als Mitte-Tropfen), `dialButtonBackground` (`textPrimary.opacity(0.04)`), `dialButtonBorder` (`textPrimary.opacity(0.10)`). Opacities kommen aus dem Handoff. |
| `Presentation/Theme/ThemeColors+Palettes.swift` | Presentation | (keine Aenderung) | Tokens werden ableitend aus `interactive` / `textPrimary` definiert → keine Palette-Anpassungen noetig. |
| `Resources/de.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys: `timer.idle.headline`, `timer.idle.sectionTitle`, `timer.dial.unit`, `accessibility.dial.label`, `accessibility.dial.decrement`, `accessibility.dial.increment`, `accessibility.dial.hint`. |
| `Resources/en.lproj/Localizable.strings` | Resources | Erweitern | Englische Pendants. |
| `StillMomentTests/Timer/BreathDialGeometryTests.swift` *(neu)* | Tests | Anlegen | Punkt → Winkel → Wert; Wraparound an 12-Uhr; Clamping `[minimum, 60]`. |
| `StillMomentTests/Timer/BreathDialAccelerationTests.swift` *(neu)* | Tests | Anlegen | Initial-Bump bei `start`; nach Initial-Delay Tick alle 80 ms; `stop` raeumt sauber auf (kein Tick nach Release). Mit injizierter `TestScheduler`-Clock. |
| `StillMomentTests/Timer/SettingCardLabelCasingTests.swift` *(neu, optional)* | Tests | Anlegen | Card-Labels werden Sentence-Case gerendert (kein `.uppercased()`). |
| `StillMomentUITests/TimerFlowUITests.swift` | UITests | Pruefen/Anpassen | Bestehender Test nutzt `timer.picker.minutes` als Identifier — der entfaellt. Test auf neuen Identifier `timer.dial.value` (Big Number) umstellen. |
| `dev-docs/reference/color-system.md` | Docs | Erweitern | Neue Dial-Tokens dokumentieren. |
| `CHANGELOG.md` | Docs | Eintrag | User-sichtbar: "Neuer Atemkreis-Picker statt Wheel-Picker". |

## API-Recherche

- **`SwiftUI.Path` / `SwiftUI.Canvas`** — beide ab iOS 15 verfuegbar; Deployment-Target des Projekts ist iOS 16. **Empfehlung:** `Canvas` fuer den Ring (clean, performance-arm) ODER zwei `Circle().trim(...)` (einfacher, unterstuetzt `.shadow()` direkt). Gradient-Stroke: `Circle().trim(from: 0, to: progress).stroke(LinearGradient(...), style: StrokeStyle(lineWidth: 16, lineCap: .round)).rotationEffect(-90°)` — schon im Codebase vorhanden (`progressCircle`).
- **`DragGesture(minimumDistance: 0)`** — startet sofort bei Touch-Down (entscheidend, damit `onMouseDown`-Aequivalent triggert). `coordinateSpace: .local` reicht — Origin liegt dann in der oberen linken Ecke der Drag-Hit-Area; `(x - size/2, y - size/2)` ergibt den Vektor zur Mitte. `atan2(dy, dx)` → Winkel.
- **`onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)`** — `onPressingChanged` liefert `Bool` (down/up). **Wichtig:** Combine-Timer fuer das eigentliche Auto-Repeat, weil `onLongPressGesture` keinen Tick-Mechanismus hat. Mit `simultaneousGesture` kombinierbar, falls noetig.
- **`accessibilityAdjustableAction { direction in ... }`** + `.accessibilityValue(...)` + `.accessibilityRepresentation { Slider(...) }` — empfohlene Kombination um VoiceOver Slider-Rolle zu geben (ab iOS 15). Ohne `.accessibilityRepresentation` reicht `accessibilityAdjustableAction` mit `.accessibilityValue`. Wir nehmen die einfachere Variante.
- **`@Environment(\.accessibilityReduceMotion) var reduceMotion: Bool`** — Standard-iOS-API. Bei `true`: Halo-Pulse als statisches Mittel-Glas (`r = 22`, `opacity = 0.20`).
- **`AudioServicesPlaySystemSound`** — nicht relevant fuer dieses Ticket (kein Vibrations-Feedback bei Drag/Tap). Falls spaeter gewuenscht, separates Ticket.
- **Newsreader-Font:** Im aktuellen Repo **nicht gebuendelt** (`find ios -iname "*newsreader*"` leer). Das Ticket / Handoff sagt "Newsreader (gebuendelt)" — das ist falsch fuer den iOS-Stand. **Entscheidung:** Bestehende App-Fonts (`.system(... .rounded ...)`) verwenden, denselben "weichen, leichten" Look wie heute (`screenTitle`, `timerCountdown`). Newsreader-Bundling ist out-of-scope dieses Tickets.

## Design-Entscheidungen

### 1. Geste-Mathe als Pure Helper, nicht im View

**Trade-off:** Mathe-Code im `BreathDial`-View einbetten waere kuerzer, ist aber nur ueber Snapshot-Tests / UI-Tests pruefbar. Auslagern in einen pure Helper kostet eine Zusatzdatei, macht jeden Edge Case (12-Uhr-Wraparound, Clamp gegen `minimumDurationMinutes`, Bogen-Skala fest 1..60) per `XCTest` direkt testbar.

**Entscheidung:** Auslagern. Helper `BreathDialGeometry` enthaelt nur reine Funktionen, keine SwiftUI-Imports. Spiegelt das DDD-Prinzip "Side effects sind explizit" auch im Presentation-Layer wider.

### 2. Theme-Tokens als computed properties auf `ThemeColors`

**Trade-off:** Sechs neue Felder in `ThemeColors` (Equatable + Hashable + Palette-Tabelle) waeren explizit, blaehen aber den Init in 6 Palettes auf. Computed properties (wie `accentBannerBackground`, `settingCardBackground` schon vormachen) halten die Palette-Tabelle schmal.

**Entscheidung:** Computed properties auf `ThemeColors` ergaenzen — ableitend aus `interactive` / `textPrimary` / `backgroundPrimary`. Falls spaeter pro Palette feinjustiert werden muss, ist eine Migration in das gespeicherte Schema einfach moeglich.

### 3. Drag- und Tap-Geste auf demselben SwiftUI-View

**Trade-off:** `DragGesture` an die ganze Dial-Hit-Area zu binden frisst Touches der zentralen Zahl — die ist aber rein dekorativ (Wert wird ueber Drag/Buttons geaendert), also unproblematisch. Die +/-Buttons liegen *ausserhalb* der 220 px Dial-Box (Radius 168 px → Buttons sitzen bei y ≈ 110 + 119 = 229 px), also keine Geste-Konflikte.

**Entscheidung:** `DragGesture(minimumDistance: 0)` direkt auf das Dial. Buttons sind eigene `Button`s mit `.simultaneousGesture(LongPressGesture(...))` fuer Auto-Repeat-Trigger.

### 4. Long-Press-Acceleration via Combine-Timer

**Trade-off:** `Task { try await Task.sleep(...) }` ist ergonomisch, laesst sich aber schwerer mit synchronen Tests pruefen. Combine-`Timer.publish(...)` mit injizierter `Scheduler` (`DispatchQueue` in Prod, `TestScheduler` im Test) ist gut testbar und passt zum Rest des ViewModels (`receive(on: DispatchQueue.main)`).

**Entscheidung:** `LongPressAccelerator` als kleiner Klassentyp, der einen `Cancellable` haelt und einen Closure `(Int) -> Void` ruft. Bei `start(direction:)` sofort 1× rufen, dann nach 320 ms eine Subscription auf `Timer.publish(every: 0.080, on: .main, in: .common)` aufsetzen. `stop()` cancel't beides.

## Refactorings

1. **`SettingCard.swift` Label-Styling vereinheitlichen.** Aktuelles `.uppercased()` + `.tracking(1.3)` ist ein Direkt-Styling unter dem Typography-System. Refactoring: `Text(label).themeFont(.cardLabel)` (neue Rolle, Sentence-Case-konform). **Risiko:** Niedrig — der Card-View ist isoliert, hat ein Preview, keine bestehenden Snapshot-Tests.

2. **`TimerView.idleScreen` Layout-Logik.** Aktuell ein simpler `VStack(spacing: 22)`. Neu: 4 Sektionen (Headline, Dial, Section-Trenner, Cards) plus Spacer mit `minLength`/`maxHeight` fuer responsive Verteilung. **Risiko:** Mittel — Layout muss auf SE und 15 Pro Max ohne Scroll passen. Verifikation via Previews aller drei `traits`.

3. **`durationWheel(isCompact:)` ersatzlos entfernen.** Picker mit `accessibilityIdentifier "timer.picker.minutes"` faellt weg. UITest `TimerFlowUITests` muss umgestellt werden. **Risiko:** Niedrig — der Identifier wird nur an einer Stelle in den UITests benutzt.

## Fachliche Szenarien

### AK-1: Drag setzt Wert kontinuierlich

- **Gegeben:** Idle-Screen, Atemkreis steht auf 18 Min.
  **Wenn:** User legt den Finger auf 3-Uhr-Position des Rings und zieht zur 6-Uhr-Position.
  **Dann:** Wert steigt kontinuierlich von 15 auf 30, Bogen waechst proportional, Tropfen folgt der Fingerposition auf dem Ring-Mittelradius.

- **Gegeben:** Atemkreis steht auf 5 Min.
  **Wenn:** User zieht ueber die 12-Uhr-Position hinweg (von 11-Uhr zu 1-Uhr).
  **Dann:** Wert wechselt sauber von 55 auf 5 (Wraparound-Mathe greift).

### AK-2: Drag clamp't gegen Minimum und 60

- **Gegeben:** Einstimmung "Atem-Anker" (4:30) ist aktiv → `minimumDurationMinutes = 5`.
  **Wenn:** User versucht durch Drag auf 2 Min zu gehen.
  **Dann:** Wert klemmt auf 5 Min, Tropfen springt nicht ueber die 12-Uhr-Position hinaus, "-"-Button bleibt disabled.

- **Gegeben:** Wert steht auf 60 Min.
  **Wenn:** User zieht weiter im Uhrzeigersinn.
  **Dann:** Wert bleibt auf 60, Bogen ist voll, "+"-Button disabled.

### AK-3: +/-Tap erhoeht/erniedrigt um 1

- **Gegeben:** Wert 18 Min.
  **Wenn:** User tippt einmal "-".
  **Dann:** Wert ist 17 Min, Bogen schrumpft, Tropfen bewegt sich entgegen dem Uhrzeigersinn.

### AK-4: Long-Press beschleunigt

- **Gegeben:** Wert 18 Min.
  **Wenn:** User haelt "-" gedrueckt.
  **Dann:** Erstes Tick sofort (Wert 17), nach 320 ms beginnt Auto-Repeat alle 80 ms (16, 15, 14, ...).
  **Bis:** User loslaesst — Auto-Repeat stoppt sofort, kein weiterer Tick.

- **Gegeben:** Wert 2 Min, `minimumDurationMinutes = 1`.
  **Wenn:** User haelt "-" gedrueckt.
  **Dann:** Wert sinkt auf 1 und stoppt dort, "-"-Button geht in Disabled-State, Auto-Repeat haelt an.

### AK-5: Bogen-Skala bleibt 1..60, nicht Min..60

- **Gegeben:** Einstimmung "Body-Scan" (10 Min) ist aktiv → `minimumDurationMinutes = 10`, Wert 30.
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Bogen fuellt 30/60 = 50 % des Rings, nicht (30-10)/(60-10) = 40 %. Tropfen sitzt bei 6-Uhr-Position.

### AK-6: Big Number + "Minuten"-Label

- **Gegeben:** Wert 18.
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Mittig im Dial steht "18" in Typo-Rolle `.dialValue`, darunter "Minuten" / "Minutes" in `.dialUnit`. Beide nutzen Theme-Farben (Light + Dark).

- **Gegeben:** Locale = en.
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Unit-Label zeigt "Minutes" (uppercase, weites Tracking).

### AK-7: Headline + Section-Trenner

- **Gegeben:** Idle-Screen.
  **Wenn:** Screen wird gerendert.
  **Dann:** "Wie viel Zeit schenkst du dir?" steht ueber dem Atemkreis. "Passe den Timer an" steht zwischen Atemkreis und der ersten Card-Reihe. Spacing zwischen Atemkreis und Untertitel ~44 px auf Standardhoehe.

### AK-8: Card-Labels Sentence-Case

- **Gegeben:** Idle-Screen.
  **Wenn:** Cards werden gerendert.
  **Dann:** Labels lauten "Vorbereitung", "Einstimmung", "Hintergrund", "Gong", "Intervall" — kein UPPERCASE, kein zusaetzliches Letter-Spacing. Reihenfolge unveraendert (3+2 aus shared-083).

### AK-9: Responsive Vertikale

- **Gegeben:** iPhone SE (375 × 667).
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Headline, Dial (Durchmesser ~180 px, Big Number ~62 px), Untertitel, alle 5 Cards und der "Beginnen"-Button sind ohne Scroll sichtbar.

- **Gegeben:** iPhone 15 Pro Max (430 × 932).
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Dial-Durchmesser ~220 px, Big Number ~76 px, Sektionen sind aesthetisch verteilt, kein doppelt so grosser Atemkreis.

### AK-10: Reduced Motion

- **Gegeben:** System-Setting "Bewegung reduzieren" ist aktiv.
  **Wenn:** Atemkreis wird gerendert.
  **Dann:** Halo um den Tropfen ist statisch sichtbar (mittlerer Radius, mittlere Opazitaet). Kein Pulse-Loop. Drag und +/-Tap funktionieren weiterhin.

### AK-11: VoiceOver Slider-Rolle

- **Gegeben:** VoiceOver aktiv, Atemkreis fokussiert.
  **Wenn:** User fuehrt 1-Finger-Swipe-Up aus.
  **Dann:** VoiceOver kuendigt "19 Minuten" an, Wert erhoeht sich um 1 (clamp gegen 60). Bei Swipe-Down sinkt der Wert um 1 (clamp gegen `minimumDurationMinutes`). Disabled-State der +/-Buttons wird korrekt ausgewiesen.

### AK-12: +/-Accessibility-Labels

- **Gegeben:** VoiceOver aktiv, "-"-Button fokussiert.
  **Wenn:** User triggert Doppeltap.
  **Dann:** VoiceOver kuendigt zuerst "Eine Minute weniger" / "One minute less" an, dann den neuen Wert ueber den Slider-Trait. Bei Disabled-State: VoiceOver liest "abgeblendet".

### AK-13: Theme-Konsistenz

- **Gegeben:** Theme-Wechsel zwischen Candlelight (warm) → Forest (sage) → Moon (dusk) im Light- und Dark-Mode.
  **Wenn:** Idle-Screen wird gerendert.
  **Dann:** Track-Ring, Aktiv-Bogen, Tropfen-Halo, Tropfen-Core, +/-Buttons nutzen ausschliesslich Theme-Tokens. Keine direkten Hex-Werte. Bogen-Farbe = `interactive` der jeweiligen Palette.

### AK-14: Beginnen-Button unveraendert

- **Gegeben:** Idle-Screen.
  **Wenn:** "Beginnen"-Button gerendert.
  **Dann:** Button verwendet weiterhin `.warmPrimaryButton()` — kein copper-Pill-Glow aus dem Design, kein Override.

## Reihenfolge der Akzeptanzkriterien (TDD)

Optimale Implementierungs-Reihenfolge (Abhaengigkeiten beruecksichtigen):

1. **AK-1 + AK-2 + AK-5 (Geste-Mathe)** — `BreathDialGeometry` + Tests. Pure Function, keine UI-Abhaengigkeit. Decken Wraparound, Clamping, feste Bogen-Skala ab.
2. **AK-4 (Long-Press)** — `LongPressAccelerator` + Tests. Reine Logik, keine View.
3. **AK-3 + AK-11 + AK-12 (Buttons + A11y)** — `BreathDial` View baut +/-Buttons und Accessibility ein.
4. **AK-6 + AK-13 (Big Number + Theme-Tokens)** — Neue Typo-Rollen, neue Theme-Tokens, im Dial einsetzen.
5. **AK-10 (Reduced Motion)** — Halo-Animation hinter `accessibilityReduceMotion`-Check.
6. **AK-8 (Card-Labels)** — `SettingCard.swift` Label-Styling anpassen.
7. **AK-7 + AK-9 (Layout)** — `idleScreen(geometry:)` umbauen, responsive Verteilung. UI-Tests / Previews.
8. **AK-14 (Beginnen-Button)** — Verifikation: nichts geaendert.
9. **Bestehende Tests fuer Setting-Cards aus shared-083** — bleiben gruen verifizieren.

## Vorbereitung

Keine manuellen Schritte noetig. Xcode FileSystemSynchronized-Group nimmt neue Dateien automatisch auf.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Drag-Geste am Ring konkurriert mit Scroll-Gesten der umgebenden View | Idle-Screen ist kein ScrollView. Falls spaeter eingefuehrt: `simultaneousGesture` oder `highPriorityGesture` pruefen. |
| Long-Press-Timer leakt nach `onTouchUp` | Cleanup im `LongPressAccelerator.stop()` und im `onPressingChanged: false`-Branch. Test deckt Tick-Anzahl nach Release ab. |
| Layout passt nicht auf iPhone SE | Drei Preview-Traits (375x667, 393x852, 430x932) muessen alle ohne Scroll passen. Wenn n.s.: `Spacer(minLength:)` + Dial-Durchmesser-Skala anpassen, NICHT Cards verkleinern. |
| Newsreader-Font fehlt → Big Number sieht anders aus als Mockup | Pragmatisch mit `.system(.rounded, weight: .light)` umsetzen, optisch nahe am Mockup. Optional Newsreader-Bundling in separatem Polish-Ticket. |
| `.accessibilityAdjustableAction` mit Dial liefert keinen Slider-Trait per Default | Explizit `.accessibilityAddTraits(.isAdjustable)` setzen, in VoiceOver-Test verifizieren. |
| UI-Tests greifen auf `timer.picker.minutes` zu | Sofort auf neuen Identifier umstellen; vermeidet rotes CI nach Merge. |

## Geklaerte Fragen

- **`settings.card.hint` entfernen:** Der neue Section-Trenner "Passe den Timer an" ersetzt den Hinweis. Key wird aus `Localizable.strings` (de + en) und aus `SettingCardsGrid.swift` entfernt.
- **Fonts:** App-eigene `.system(... .rounded ...)`-Fonts werden weiterverwendet. Newsreader-Bundling ist out-of-scope.
- **Default-Minutenwert:** Bleibt bei 10 Min. Persistierte Auswahl ueberschreibt sowieso den Default — das Mockup zeigt 18 nur als Beispielwert.

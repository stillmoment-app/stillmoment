# Implementierungsplan: shared-097 (iOS)

Ticket: [shared-097](../shared/shared-097-danke-screen-kerzenschein.md)
Erstellt: 2026-05-16

---

## Annahmen

Bewusst getroffene Annahmen, die in den Plan eingeflossen sind.

- **Mandala wird nativ in Swift gebaut** (`Path` + `Canvas` oder ein `Shape`), nicht als SVG-Asset importiert. Begruendung: die App hat keine SVG-Render-Pipeline; alle bisherigen Symbole sind SF Symbols oder native `Shape`s. Die Petal-Geometrie ist eine triviale kubische Bézier-Schleife, 16-fach rotiert — der Aufwand ist vergleichbar mit dem Asset-Import.
- **Headline-Schrift bleibt im Theme-Typography-System.** Der Handoff nennt „Newsreader 23/300 light, line-height 1.35". Wir nutzen den bestehenden `.themeFont(.screenTitle)` (28pt light rounded). Das hat denselben ruhigen Charakter wie der Newsreader-Vorschlag — eine neue Schriftfamilie wuerde nur eine View betreffen und das System brechen.
- **Glas-Pille wird als wiederverwendbarer `ButtonStyle`** in `ButtonStyles.swift` ergaenzt — analog zu `WarmPrimary`/`WarmSecondary`. Spaeter potentiell auch fuer andere KS-2.0-Stellen wiederverwendbar; konsistent mit dem vorhandenen Muster (Style + ViewModifier + `.warmGlassButton()`-Extension).
- **EN-Headline:** `"Thank you for giving yourself this time."` — aktiv, parallel zum geschenkhaften DE-Ton (mit User abgestimmt).
- **Hintergrund kommt von den Aufrufern.** Player (`GuidedMeditationPlayerView`), `TimerView` und `RootContainerView` setzen bereits `self.theme.backgroundGradient.ignoresSafeArea()` hinter den `MeditationCompletionView`-Overlay. Die Shared-View bekommt **keinen** eigenen Hintergrund — das vermeidet doppelte Gradienten beim Cross-Fade und respektiert das bestehende Layer-Pattern.
- **`CompletionGlow.swift` wird geloescht.** Einziger Aufrufer ist `MeditationCompletionView` (mit `grep` bestaetigt). Mit dem Umbau ist die Komponente obsolet.
- **Close-X bewusst weggelassen** — entspricht dem Ticket. Im Plan keine Vorbereitung dafuer.
- **Keine Cross-Fade-Spezialeffekte zwischen Player und Danke-Screen.** Der Ticket-Akzeptanzkriterium sagt „der Wechsel darf auch hart sein" — vorhandene Transitions in `TimerView.swift:98` und der Player-Overlay-Logik bleiben unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Presentation/Views/Shared/MeditationCompletionView.swift` | Presentation | Umbau | `CompletionGlow` durch `DankeLotusMandala` ersetzen, Button-Style auf neue Glas-Pille, Layout-Spacing an Mandala anpassen, Mandala+Text vertikal zentriert als Gruppe und Button als Bottom-Anchor (separat) |
| `Presentation/Views/Shared/CompletionGlow.swift` | Presentation | Loeschen | Nach Umbau obsolet, kein weiterer Aufrufer |
| `Presentation/Views/Shared/DankeLotusMandala.swift` | Presentation | Neu | Statische Doppel-Lotus-Mandala-View (Canvas oder Shape), 16 Petals, theme-getrieben |
| `Presentation/Views/Shared/ButtonStyles.swift` | Presentation | Erweitern | Neuer `WarmGlass`-`ButtonStyle` + `WarmGlassButtonModifier` + `.warmGlassButton()`-Extension. Pattern analog zu `WarmPrimary`/`WarmSecondary` |
| `Resources/de.lproj/Localizable.strings` | Resources | Edit | Wert von `guided_meditations.player.completion.headline` auf „Danke, dass du dir diese Zeit geschenkt hast." aktualisieren |
| `Resources/en.lproj/Localizable.strings` | Resources | Edit | Wert auf „Thank you for giving yourself this time." aktualisieren |
| `StillMomentTests/Presentation/MeditationCompletionViewTests.swift` | Tests | Erweitern | Die bestehenden drei Tests (onBack, accessibilityLabel) bleiben — keine Aenderung am Verhalten der Shared-View-API |
| `StillMomentTests/Presentation/DankeLotusMandalaTests.swift` | Tests | Neu | Strukturelle Tests fuer Mandala: Petal-Anzahl, Inner-Ring-Offset, Stroke-Width-Werte |

**Aufrufer (unveraendert):**
- `Presentation/Views/Timer/TimerView.swift:93` — uebergibt eigenen `onBack` + `backAccessibilityLabel`. API der `MeditationCompletionView` bleibt gleich, kein Eingriff noetig.
- `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift:43` — uebergibt nur `onBack`. Kein Eingriff.
- `Presentation/Views/Shared/RootContainerView.swift:54` — uebergibt nur `onBack`. Kein Eingriff.

---

## API-Recherche

Alles SwiftUI-Standard, Min-Target ist iOS 16 — keine Verfuegbarkeitsrisiken.

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Canvas` | iOS 15+ | Apple Docs | Erlaubt direktes Zeichnen + `drawLayer { ctx in ... }` fuer per-Petal-Rotation. Alternativ: `ZStack` aus mehreren `Path`-`Shape`s, einfacher zu testen, aber mehr Boilerplate. |
| `Path` + `addCurve` | iOS 13+ | Apple Docs | Kubische Bezier — die Petal-Form vom Handoff (M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z) ist 1:1 in `Path` umsetzbar. |
| `.ultraThinMaterial` (`Material`) | iOS 15+ | Apple Docs | Backdrop-Blur fuer Glas-Pille. Identisch zu `GlassPauseButton` im Player. |
| `Capsule()` | iOS 13+ | Apple Docs | Pillen-Form fuer Glas-Button. |

---

## Design-Entscheidungen

### 1. Mandala: `Shape`-Struct statt `Canvas`

**Trade-off:** `Canvas` ist kompakt, aber schwer zu testen (kein Snapshot der gezeichneten Pfade). Ein eigenes `LotusMandala: View` mit `ZStack { ForEach(angles) { rotation in PetalShape().rotationEffect(...) } }` ist verboser, aber strukturell testbar und in Previews einfacher zu inspizieren.

**Entscheidung:** **`Shape`-basierter Aufbau** mit `LotusPetal: Shape` (deklarative Petal-Geometrie via `Path` in `path(in rect:)`) und einer `LotusMandala: View` die zwei `ForEach(0..<8)` mit `.rotationEffect(.degrees(Double(idx) * 45))` rendert. Innerer Ring mit `+ 22.5` Offset und `.opacity(0.6)`. Zentrum als zwei `Circle()`-Layer (gefuellt + outline).

Begruendung:
- Petal-Anzahl und Offsets sind in Tests asserierbar (`view.petals.count == 8`, `innerRingOffsetDegrees == 22.5`).
- Performance ist irrelevant (statisch, 16 kleine Pfade — Compose-Equivalent macht das genauso).
- Konsistent mit dem vorhandenen `PlayerCenterDisc` / `PlayerRingView`-Stil.

### 2. Glas-Pille als wiederverwendbarer `ButtonStyle`

**Trade-off:** Inline im `MeditationCompletionView` reicht fuer den ersten Use Case. Aber: KS-2.0 wird wahrscheinlich an weiteren Stellen Glas-Pillen brauchen (Empty-States, Bestaetigungs-Dialoge, …). `ButtonStyles.swift` ist bereits die zentrale Stelle fuer Theme-Buttons.

**Entscheidung:** Glas-Pille als `WarmGlass: ButtonStyle` in `ButtonStyles.swift`, exponiert via `.warmGlassButton()`-Extension. Liest `theme.interactive` via `WarmGlassButtonModifier` (gleicher Bridge wie `WarmPrimary` — die Memory-Note „ButtonStyle kann kein `@Environment` lesen" bleibt unangetastet).

Visuelle Spezifikation (aus Handoff):
- Hintergrund: `.ultraThinMaterial` + getoenter Overlay (dark: warm-dunkel @ 0.55, light: cream @ 0.55)
- Border: 1 px Capsule-Stroke in `theme.interactive` @ ~0.5
- Text: `theme.interactive`, `.themeFont(.bodyAccent)` oder Inline `.system(size: 14, weight: .medium)` mit `.tracking(0.56)`
- Padding: 14 V / 44 H
- Cornerradius: Capsule (auto)

### 3. Headline-Frame: `.frame(maxWidth: 240)` statt fester Newsreader-Spezifikation

**Trade-off:** Der Handoff sagt `max-width 240 px`. Wir koennten mit dynamischer Type-Size-Skalierung hinter `.dynamicTypeSize(...DynamicTypeSize.xxLarge)` arbeiten, oder einen festen `maxWidth` setzen.

**Entscheidung:** Fester `maxWidth: 240` als oberer Anker, kombiniert mit `multilineTextAlignment(.center)` und `text-wrap: balance`-Effekt durch SwiftUI's `Text` (Auto-Balancing kommt mit `text-wrap: balance`-aequivalentem Verhalten ab iOS 16 ueber `Text` automatisch). Dynamic Type bleibt aktiv — wenn der Text zu lang wird, wirft SwiftUI ihn um, was akzeptabel ist (kein Truncation).

---

## Refactorings

Keine groesseren Refactorings. Der Umbau der `MeditationCompletionView` ist additiv (Komponenten austauschen, gleiche Aufrufer-API).

**Loeschungen:**
1. **`CompletionGlow.swift` entfernen** — kein weiterer Aufrufer in der gesamten Codebase. Risiko: gering. Wenn ein neuer Aufrufer in `RootContainerView` o.ae. dazukommt, fliegt der Compile-Fehler sofort auf.

---

## Fachliche Szenarien

### AK „Mandala statt Glow": statisches Doppel-Lotus-Mandala

- Gegeben: eine Meditation ist gerade zu Ende gegangen
  Wenn: der Danke-Screen erscheint
  Dann: zentral auf dem Screen sitzt ein Mandala mit 8 aeusseren Lang-Petals und 8 inneren Kurz-Petals
  Und: die inneren Petals sitzen jeweils in der Luecke zwischen zwei aeusseren (22.5°-Offset)
  Und: das Mandala-Bounding ist 160 × 160 pt

- Gegeben: der Danke-Screen ist sichtbar
  Wenn: 5 Sekunden vergehen, ohne dass der User tippt
  Dann: nichts auf dem Bildschirm hat sich bewegt — Mandala bleibt statisch, kein Pulsieren, kein Atem-Effekt

- Gegeben: die App laeuft im Light Mode
  Wenn: der Danke-Screen erscheint
  Dann: die Mandala-Strokes sind in der hellen Akzent-Variante (warmes Kupfer) sichtbar

- Gegeben: die App laeuft im Dark Mode
  Wenn: der Danke-Screen erscheint
  Dann: die Mandala-Strokes sind in der dunklen Akzent-Variante (helleres Mahagoni-Apricot) sichtbar

### AK „Headline-Text": neuer, aktiver Satz in DE + EN

- Gegeben: System-Sprache ist Deutsch
  Wenn: der Danke-Screen erscheint
  Dann: unter dem Mandala steht „Danke, dass du dir diese Zeit geschenkt hast." (nicht mehr „...diesen Moment genommen hast.")

- Gegeben: System-Sprache ist Englisch
  Wenn: der Danke-Screen erscheint
  Dann: unter dem Mandala steht „Thank you for giving yourself this time."

- Gegeben: der Headline-Text wird gerendert
  Wenn: das Geraet eine schmale Breite hat (z. B. iPhone SE)
  Dann: der Text umbricht natuerlich in mehrere Zeilen, ohne zu truncaten

### AK „Glas-Pille statt Gradient-CTA"

- Gegeben: der Danke-Screen ist sichtbar
  Wenn: der User auf den unteren Bildschirmrand schaut
  Dann: dort sitzt eine Pillen-foermige Glas-Schaltflaeche mit der Beschriftung „Fertig" / „Done", in der warmen Akzent-Schrift
  Und: hinter der Pille schimmert der Hintergrund-Gradient durch (halbtransparent, leicht weichgezeichnet)
  Und: der Border der Pille ist eine duenne warme Akzent-Linie

- Gegeben: die Glas-Pille ist sichtbar
  Wenn: der User auf den Button tippt
  Dann: der Danke-Screen wird dismissed wie vorher (Player wird geschlossen / Timer wird zurueckgesetzt / Recovery-Overlay verschwindet — je nach Aufrufer)

- Gegeben: die App laeuft im Light Mode
  Wenn: die Glas-Pille gerendert wird
  Dann: der Glas-Hintergrund hat einen hellen Cream-Tint (nicht den dunklen Dark-Tint)

- Gegeben: die App laeuft im Dark Mode
  Wenn: die Glas-Pille gerendert wird
  Dann: der Glas-Hintergrund hat einen dunkel-warmen Tint

### AK „Geltung an allen drei Aufrufern"

- Gegeben: eine Guided Meditation laeuft bis zum Ende
  Wenn: die Audio-Wiedergabe endet
  Dann: der neue Danke-Screen erscheint (Mandala, neuer Satz, Glas-Pille)

- Gegeben: ein Stillen-Meditations-Timer laeuft bis zum Ende
  Wenn: der Schluss-Gong ertoent und der Timer auf 0:00 steht
  Dann: derselbe neue Danke-Screen erscheint im Timer-Overlay

- Gegeben: ein Timer laeuft im Hintergrund, iOS killt die App
  Wenn: der User die App neu oeffnet (nach Sitzungsende)
  Dann: derselbe neue Danke-Screen erscheint im `RootContainerView`-Overlay

### AK „Nicht-Aenderungen": kein Close-X, keine Stats, keine Animation

- Gegeben: der Danke-Screen ist sichtbar
  Wenn: der User die obere linke Bildschirmecke betrachtet
  Dann: dort befindet sich **kein** Schliessen-X — die Pille „Fertig" ist der einzige sichtbare Dismiss-Pfad

- Gegeben: der Danke-Screen ist sichtbar
  Wenn: der User den Screen scannt
  Dann: keine Zahlen, keine Streak-Anzeige, keine Statistik — nur Mandala + Satz + Pille

### Strukturelle Tests fuer `DankeLotusMandala`

- Test 1: `LotusMandala` rendert genau 8 aeussere Petals (assertierbar ueber `view.outerPetalCount`).
- Test 2: `LotusMandala` rendert genau 8 innere Petals.
- Test 3: Inner-Ring-Petals sind um 22.5° gegenueber den Outer-Ring-Petals versetzt.
- Test 4: Innere Petals haben `opacity = 0.6`.
- Test 5: `LotusPetal.path(in:)` produziert einen geschlossenen Pfad (Petals sind keine offenen Linien).

### Strukturelle Tests fuer `MeditationCompletionView`

Die bestehenden 3 Tests (`onBackClosureIsExposedAndCallable`, `testDefaultAccessibilityLabelResolvesFromLocalization`, `testCustomAccessibilityLabelIsForwarded`) bleiben unveraendert — die API der View aendert sich nicht.

---

## Reihenfolge der Akzeptanzkriterien

Optimale TDD-Reihenfolge — von unten nach oben durch die Component-Hierarchie:

1. **Headline-Strings** (DE + EN aktualisieren) — kleinste isolierte Aenderung; bestehende Tests laufen weiter, weil sie nur die Existenz / Localization pruefen, nicht den exakten Text.
2. **`DankeLotusMandala` neu (mit Tests)** — eigenstaendige Komponente, isoliert testbar. Red: Tests fuer Petal-Anzahl + Offset → Green: Mandala-Implementierung.
3. **`WarmGlass`-`ButtonStyle` in `ButtonStyles.swift`** — eigenstaendige Komponente, kann ueber Preview validiert werden. Folgt dem `WarmPrimary`-Muster, kein eigener Test noetig (Konvention der Codebase: keine Unit-Tests fuer reine Style-Structs).
4. **`MeditationCompletionView` umbauen** — `CompletionGlow` durch `DankeLotusMandala` ersetzen, `.warmPrimaryButton()` durch `.warmGlassButton()` ersetzen, Layout an den Bottom-Anchor-Vorgaben des Handoffs ausrichten.
5. **`CompletionGlow.swift` loeschen** — nach erfolgreichem Umbau und Build.
6. **Visual-Check in Previews** (Light + Dark) — keine Snapshot-Pixel-Tests im Projekt; visuelle Validierung erfolgt manuell + ueber `#Preview`s.
7. **Manueller Test der drei Aufrufer** im Simulator: Timer-Ende, Guided-Meditation-Ende, Pending-Recovery-Pfad.

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Mandala wirkt im Light Mode zu blass | `theme.interactive` ist im Light Mode `#A2503E` (Mahagoni) — kontrastreich genug. Wenn nicht, in Preview justieren bevor commitiert |
| Glas-Pille verschwimmt in heller Region des Gradienten | `.ultraThinMaterial`-Pille mit warm-getoentem Overlay + Border behaelt Lesbarkeit auch ueber dem hellen Bottom-Stop. Visuell pruefen in Preview |
| Pending-Recovery-Pfad wird beim Refactor uebersehen | `RootContainerView` ruft `MeditationCompletionView` mit derselben API auf — nichts zu aendern. Trotzdem manuell testen (Schritte 7/8 im Manuellen Test des Tickets) |
| `CompletionGlow.swift`-Loeschung bricht Compile in Tests | `find` hat keinen Aufrufer ausser `MeditationCompletionView.swift` gefunden. Falls doch: Test wird beim ersten Build sichtbar |

---

## Offene Fragen

Keine.

---

## Manuelle Validierung nach Implementierung

1. App im Dark Mode starten, Timer 60 s laufen lassen → Mandala + neuer Satz + Glas-Pille
2. „Fertig" tippen → Timer-Screen wieder sichtbar
3. Guided Meditation 30 s laufen lassen → derselbe Screen
4. App in den Light Mode wechseln, Schritte 1–3 wiederholen → warme Variante korrekt
5. Timer starten, App vom Multitasking-Bildschirm gewaltsam beenden, neu oeffnen → Recovery-Screen zeigt das neue Mandala

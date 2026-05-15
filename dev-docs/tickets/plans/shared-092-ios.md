# Implementierungsplan: shared-092 (iOS)

Ticket: [shared-092-danke-screen-redesign](../shared/shared-092-danke-screen-redesign.md)
Erstellt: 2026-05-15

---

## Mentales Modell

`MeditationCompletionView` wird zum statischen Nachklang-Screen umgebaut. Drei sichtbare Elemente, vertikal zentriert: ein nicht-animierter Glow (zwei konzentrische Radial-Gradient-Kreise), eine einzige warme Botschaft, ein "Fertig"-Button. Hintergrund und Akzent kommen ueber `@Environment(\.themeColors)` aus dem aktiven Theme — keine Hex-Werte aus dem Handoff. Es gibt keinen `onAppear`-Effekt, kein `withAnimation`, keinen Stagger; der Screen erscheint als direkter Schnitt aus der Sitzung.

Der Glow ist als eigene, parameter-freie SwiftUI-Komponente (`CompletionGlow`) modelliert — keine Aenderung an `BreathingCircleView` oder `MeditationPhase`. Bestehende Aufrufer (`TimerView`, `GuidedMeditationPlayerView`, `RootContainerView`) erhalten den neuen Look automatisch, weil die View-Signatur unveraendert bleibt.

---

## Annahmen

Bewusst getroffene Annahmen, die in den Plan eingeflossen sind:

- **Headline-Key**: Bestehender Key `guided_meditations.player.completion.headline` wird wiederverwendet, nur der Wert aendert sich (DE: "Danke, dass du dir diesen Moment genommen hast.", EN: "Thank you for taking this moment for yourself."). Kein zusaetzlicher Key-Churn; alle drei Aufrufer (Timer/Player/Recovery) sehen automatisch den neuen Text. Der historische Namespace ist semantisch nicht praezise (Timer nutzt den Key auch), aber das Umbenennen ist nicht im Scope.
- **`button.back` bleibt im iOS-Repo erhalten**, obwohl er nach dem Redesign auf iOS keinen Aufrufer mehr hat. Ticket-Wortlaut "Bestehender `button.back` bleibt im Repo" wird befolgt. Localization-Review-Skill wird das u. U. als "ungenutzt" melden — dann bewusst belassen.
- **Accessibility-Identifier des Buttons** wird auf `completion.button.done` umgestellt (analog zum neuen Localization-Key). Aktuell ist es `completion.button.back` und kein UI-Test referenziert ihn (gepruefte Suche in `StillMomentUITests/`).
- **Glow-Bounding-Box**: 180 pt im Standard-Layout, 144 pt auf `compactHeight` (< 700 pt). Innerer Kern jeweils 96 pt / 80 pt. Das ist proportional zur bisherigen Icon-Skalierung in der View (80 pt → 72 pt bei compact).
- **Glow-Farbe nutzt `theme.interactive`** mit gestaffelten Opacities (analog zu shared-087, AK "Theming"). Werte siehe Design-Entscheidungen.
- **Headline-Typografie-Rolle**: bestehende `.screenTitle`-Rolle (mit `size: 32` bei compact, analog zu heute). Keine neue Display-Rolle — der Handoff nennt Newsreader/Geist, die nicht integriert werden.
- **Auftritts-Animation**: aktuelle View hat ohnehin keinen `onAppear`-Effekt und kein `withAnimation` — die AK "Auftritt ohne Stagger" ist mit dem aktuellen Code-Style ohne Eingriff erfuellt. Wir verifizieren das aber explizit.
- **Unit-Test fuer `onBack`**: strukturell — `onBack`-Property von `private` auf `let` ohne Access-Modifier (default `internal`) anheben, Test ruft `view.onBack()` direkt auf. Kein ViewInspector, kein UI-Test.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Views/Shared/MeditationCompletionView.swift` | Presentation | Umbauen | Herz-Icon entfernen, `CompletionGlow` einbinden, Subtitle-`Text` entfernen, Button-Key auf `completion.button.done` setzen, `accessibilityIdentifier` umbenennen, `onBack` auf `internal` anheben fuer Tests |
| `Presentation/Views/Shared/CompletionGlow.swift` | Presentation | **Neu** | Statische SwiftUI-View, zwei konzentrische Kreise mit `RadialGradient`; `size`-Parameter; nutzt `@Environment(\.themeColors)` fuer Akzent |
| `Resources/de.lproj/Localizable.strings` | Resources | Aendern | Wert von `guided_meditations.player.completion.headline` ueberschreiben; Zeile `guided_meditations.player.completion.subtitle` entfernen; neuer Key `completion.button.done` = "Fertig" |
| `Resources/en.lproj/Localizable.strings` | Resources | Aendern | Wert von `guided_meditations.player.completion.headline` ueberschreiben; Zeile `guided_meditations.player.completion.subtitle` entfernen; neuer Key `completion.button.done` = "Done" |
| `StillMomentTests/Presentation/MeditationCompletionViewTests.swift` | Tests | **Neu** | Strukturelle Tests: `onBack`-Closure wird gespeichert/ist aufrufbar; Default-Accessibility-Label wird ueber `accessibility.backToLibrary` aufgeloest; benutzerdefiniertes Label wird durchgereicht |
| `CHANGELOG.md` | Docs | Eintrag | "Danke-Screen ueberarbeitet — ruhiger Glow statt Herz-Icon, waermere Botschaft, Button 'Fertig'" |

### Codestellen, die explizit unveraendert bleiben

- `Presentation/Views/Timer/TimerView.swift` — Aufrufer (`MeditationCompletionView(onBack: ...)`) signatur-kompatibel.
- `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` — Aufrufer signatur-kompatibel.
- `Presentation/Views/Shared/RootContainerView.swift` — Aufrufer (Pending-Termination-Recovery aus shared-080) signatur-kompatibel.
- `Presentation/Views/GuidedMeditations/BreathingCircleView.swift` — bleibt unangefasst (AK explizit).
- `Domain/Models/MeditationPhase.swift` — kein neuer Case (AK explizit).
- `Presentation/Theme/ThemeColors.swift` + Palettes — keine neuen Tokens; `theme.interactive` reicht.
- `Presentation/Views/Shared/ButtonStyles.swift` — `warmPrimaryButton()` wird wiederverwendet.
- iOS-Localization-Key `button.back` bleibt in `Localizable.strings` — Annahme oben.

---

## API-Recherche

| API | Verfuegbarkeit | Verwendung |
|---|---|---|
| `RadialGradient(gradient:center:startRadius:endRadius:)` | iOS 13+ | Beide Glow-Kreise (Halo + Kern) |
| `Gradient(stops:)` mit `Gradient.Stop` | iOS 13+ | Mehrstufige Opacity-Verlaeufe (0%, 38%, 68%, 88% etc.) |
| `Circle().fill(_:)` | iOS 13+ | Form fuer Glow-Kreise |
| `@Environment(\.themeColors)` | iOS 16 (Projekt-Deployment) | Akzentfarbe `theme.interactive` |
| `Text(_:bundle:)` mit Localization-Key | iOS 13+ | Bereits in der View etabliert |
| `accessibilityAddTraits(.isHeader)` | iOS 13+ | Headline als Screen-Reader-Heading |
| `GeometryReader` | iOS 13+ | `compactHeight`-Detection (bestehendes Pattern in der View) |

Keine neuen Frameworks, kein Material, keine besonderen Availability-Checks noetig. Apple-Docs gepruefte Signaturen sind seit iOS 13 stabil.

---

## Designentscheidungen

### 1. Glow-Farben — `theme.interactive` mit gestaffelten Opacities

**Trade-off:** Hardcode-Mahagoni aus dem Handoff (`#e8b294`, `#d99a7e`, `#c47a5e`) gibt exakte Designer-Vorstellung wieder, bricht aber alle anderen Themes (Forest, Moon). Theme-Token bedeuten ein leicht anderes Farbgefuehl, aber Konsistenz mit dem Rest der App.

**Entscheidung:** `theme.interactive` mit gestaffelten Opacities, analog zu shared-087:

- **Aeusserer Halo** (Bounding 180 pt, fill via `RadialGradient`):
  - center: `theme.interactive.opacity(0.22)`
  - 55%: `theme.interactive.opacity(0.05)`
  - 78%: `Color.clear`
- **Innerer Kern** (96 pt, fill via `RadialGradient`):
  - center: `theme.interactive.opacity(0.90)`
  - 38%: `theme.interactive.opacity(0.55)`
  - 68%: `theme.interactive.opacity(0.18)`
  - 88%: `Color.clear`

Die Hierarchie "heisser Punkt → diffuses Licht" bleibt: peak 0.90 (Kern) > 0.22 (Halo).

### 2. Hintergrund — `theme.backgroundGradient` ueber den Container der Aufrufer

`MeditationCompletionView` setzt aktuell selbst keinen Hintergrund — der wird von den Containern (`TimerView`, `GuidedMeditationPlayerView`, `RootContainerView`) gesetzt. Die heutige Praxis ist also schon AK-konform. Wir verifizieren in den Aufrufern, dass dort `theme.backgroundGradient` oder ein Theme-konformer Hintergrund liegt.

### 3. `CompletionGlow` als eigene View

**Trade-off:** Inline im `MeditationCompletionView` vs. eigene Datei.

**Entscheidung:** Eigene Datei `CompletionGlow.swift` in `Presentation/Views/Shared/`. Begruendung: (a) Single Responsibility, (b) Wiederverwendbarkeit ist nicht das Hauptziel, aber die Komponente hat genug visuelle Komplexitaet (zwei `RadialGradient`-Setups), dass sie eine eigene Adresse verdient, (c) erleichtert SwiftUI `#Preview` ohne die ganze Completion-Logik. **Kein** `phase`-Parameter, kein State — die View ist parameter-arm: `size` (CGFloat, optional mit Default 180) und implizit Theme aus dem Environment.

### 4. Layout-Abstaende — proportional zum Handoff, kompakt auf iPhone SE

**Trade-off:** Exakte 44 pt / 92 pt aus dem Handoff vs. Anpassung an die heutige Spacer-basierte Struktur.

**Entscheidung:** Wir behalten die `VStack(spacing: 0) + Spacer`-Struktur und setzen explizite `padding(.bottom: ...)`-Werte zwischen den Bloecken. Werte:

| Abstand | Standard | Compact (< 700 pt) |
|---|---|---|
| Glow → Headline | 44 | 32 |
| Headline → Button | 92 | 56 |

Die `Spacer` oben/unten zentrieren das Stack im Restraum (bestehendes Pattern, vermeidet die Spacer-Verteilungs-Fallen aus dem Memory).

### 5. `onBack`-Property fuer Tests zugaenglich

**Trade-off:** Privacy-Sicherheit vs. Testbarkeit. SwiftUI bietet keinen direkten Weg, Button-Taps in XCTest zu simulieren ohne ViewInspector.

**Entscheidung:** `private let onBack: () -> Void` → `let onBack: () -> Void` (default-internal). Damit kann der Test die Closure direkt aufrufen. Verlustrisiko: keiner — die View ist `struct`, externer Code kann die Closure ohnehin nur via Init setzen. Gleiches gilt fuer `backAccessibilityLabel` (wenn Test es lesen will).

### 6. Auftritts-Animation — kein Eingriff noetig

**Trade-off:** Verifizieren oder nichts tun?

**Entscheidung:** Aktive Verifikation in der View: keine `onAppear`-Effekte, keine `withAnimation`-Blocks, kein `.transition(...)`. Die aktuelle View hat das schon — die AK ist quasi-automatisch erfuellt. Im Plan-Review wird das nochmal gegen den finalen Code geprueft.

---

## Refactorings

Keine. Nur Umbau der `MeditationCompletionView` und ein neuer Glow-Component-File. Die ViewModels (`TimerViewModel`, `GuidedMeditationPlayerViewModel`), `MeditationPhase`, `BreathingCircleView` und die Aufrufer-Container bleiben unberuehrt.

Risiko: niedrig.

---

## Fachliche Szenarien

### AK Glow statt Herz

- **Gegeben**: Eine Meditation ist gerade zu Ende
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Statt eines Herz-Icons steht in der oberen Bildhaelfte ein warmer, runder Glow — zwei konzentrische Kreise, keine Bewegung, kein Pulsieren

- **Gegeben**: Reduzierte Bewegung ist im System eingeschaltet
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Der Glow ist identisch zur Normalansicht (er ist ohnehin statisch)

- **Gegeben**: Der Atem-Vokabular der App (BreathingCircle) ist im Player aktiv
  **Wenn**: Die Sitzung endet und der Danke-Screen erscheint
  **Dann**: `BreathingCircleView` und `MeditationPhase` sind unveraendert; die Glow-Komponente ist ein eigenstaendiges View ohne Bezug zur Atem-Animation

### AK Botschaft

- **Gegeben**: System-Locale ist DE
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Es steht genau ein Text in der Mitte: "Danke, dass du dir diesen Moment genommen hast." — kein Subtitle-Text mehr

- **Gegeben**: System-Locale ist EN
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Text lautet "Thank you for taking this moment for yourself."

- **Gegeben**: VoiceOver ist aktiv
  **Wenn**: Der Screen-Reader fokussiert die Headline
  **Dann**: Sie wird als Heading angesagt (`isHeader`-Trait)

- **Gegeben**: Standard-iPhone-Breite (≥ 375 pt)
  **Wenn**: Der Text rendert
  **Dann**: Er bricht in mehrere Zeilen, horizontal zentriert, ohne Abschneiden

### AK Button "Fertig"

- **Gegeben**: Der Danke-Screen ist sichtbar (DE)
  **Wenn**: User schaut auf den Button
  **Dann**: Der Button-Text lautet "Fertig" (EN: "Done"), Style ist `warmPrimaryButton`

- **Gegeben**: VoiceOver ist aktiv
  **Wenn**: Der Button-Fokus
  **Dann**: VoiceOver sagt "Zurueck zur Bibliothek" (das Accessibility-Label beschreibt die Konsequenz, nicht das Label)

- **Gegeben**: Tap auf "Fertig"
  **Wenn**: Die Action triggert
  **Dann**: Die `onBack`-Closure wird aufgerufen — die Navigation ist identisch zur heutigen "Zurueck"-Action (Verantwortung des Aufrufers, bleibt unveraendert)

- **Gegeben**: Touch-Target wird gemessen
  **Wenn**: VoiceOver oder iOS Accessibility-Inspector pruefen
  **Dann**: ≥ 44 × 44 pt (`warmPrimaryButton` erfuellt das bereits)

### AK Auftritt

- **Gegeben**: Eine Sitzung endet
  **Wenn**: Der Aufrufer-Container den Danke-Screen mountet
  **Dann**: Der Screen ist sofort vollstaendig sichtbar — kein Fade-In, kein Y-Versatz, kein Stagger-Pop pro Element

- **Gegeben**: App wird nach Termination im Pending-Termination-Recovery-Pfad (shared-080) gestartet
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Identische statische Darstellung — keine Lifecycle-Unterscheidung

### AK Theming

- **Gegeben**: Theme = Candlelight, Dark Mode
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Hintergrund nutzt Candlelight-Dark-Gradient (Mahagoni-Toene des Themes), Glow ist warm-orange (Theme-Akzent)

- **Gegeben**: Theme = Forest, Light Mode
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Hintergrund Forest-Light, Glow gedaempftes Gruen — kein Mahagoni-Rest

- **Gegeben**: Theme = Moon, Dark Mode
  **Wenn**: Der Danke-Screen erscheint
  **Dann**: Hintergrund Moon-Dark, Glow kuehler Blau-Akzent

### AK Konsistenz

- **Gegeben**: Timer mit 1 Minute laeuft ab
  **Wenn**: Der Timer auf 0 trifft
  **Dann**: `TimerView` zeigt den neuen Danke-Screen mit Glow, neuer Botschaft, "Fertig"-Button — kein zusaetzlicher Code-Eingriff in `TimerView`

- **Gegeben**: Geleitete Meditation spielt zu Ende
  **Wenn**: Die Audio-Datei endet
  **Dann**: `GuidedMeditationPlayerView` zeigt den identischen Danke-Screen

- **Gegeben**: User killt App waehrend Sitzung, Sitzung laeuft im Hintergrund zu Ende
  **Wenn**: User startet App erneut (shared-080-Pfad)
  **Dann**: `RootContainerView` zeigt den identischen Danke-Screen als Overlay

### AK Aufraeumen

- **Gegeben**: Lokalisations-Linter (`make check` → Localization-Linter im Projekt) laeuft
  **Wenn**: Pruefung auf ungenutzte Keys
  **Dann**: `guided_meditations.player.completion.subtitle` ist nicht mehr in DE/EN `Localizable.strings`, kein Aufrufer im Code

### AK Tests

- **Gegeben**: Eine `MeditationCompletionView` wird mit einem `onBack`-Closure konstruiert, die ein Flag setzt
  **Wenn**: Test ruft die `onBack`-Property direkt auf
  **Dann**: Das Flag wird `true`

- **Gegeben**: Eine `MeditationCompletionView` wird ohne `backAccessibilityLabel` konstruiert
  **Wenn**: Test liest die Property
  **Dann**: Sie enthaelt den Default-Wert (lokalisiert via `accessibility.backToLibrary`)

- **Gegeben**: Eine `MeditationCompletionView` wird mit explizitem `backAccessibilityLabel: "Mein Label"` konstruiert
  **Wenn**: Test liest die Property
  **Dann**: Sie enthaelt "Mein Label"

---

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Localization-Updates** (DE + EN) — Headline-Wert ueberschreiben, Subtitle-Zeile loeschen, `completion.button.done` einfuegen. `make check` (Localization-Linter) muss gruen sein.
2. **`CompletionGlow.swift`** — neue View, statisch, parametriert via `size`. `#Preview` mit drei Theme-Varianten. Kein Test (visuelle Komponente, theme-getrieben — Snapshot waere nice-to-have, ist aber nicht in den AKs).
3. **`MeditationCompletionViewTests.swift`** — drei strukturelle Tests (onBack ruft, Default-Label, Custom-Label). RED-Phase: `onBack` ist noch `private` → Test schlaegt fehl, weil unsichtbar.
4. **`MeditationCompletionView`-Umbau**:
   - `onBack` und `backAccessibilityLabel` auf `internal` (default) anheben → Tests gruen.
   - Herz-Icon-`ZStack` ersetzen durch `CompletionGlow(size: ...)`.
   - Subtitle-`Text` entfernen.
   - Button-Key auf `completion.button.done`.
   - `accessibilityIdentifier` → `completion.button.done`.
   - Layout-Abstaende auf 44/92 (Standard) bzw. 32/56 (compact) setzen.
   - Vergewissern: kein `onAppear`, kein `withAnimation`, keine `.transition()`.
5. **Manueller Test im Simulator** — Timer 1 Min ablaufen, Player durchspielen, Recovery-Pfad simulieren (kann nur durch shared-080-Setup geprueft werden; falls aufwendig, dann Pendel-Aufruf in `RootContainerView` reicht).
6. **Theme-Wechsel-Test** — Candlelight → Forest → Moon, jeweils Light + Dark; Glow und Hintergrund passen sich an.
7. **iPhone SE Simulator** — kein Scrollen, Glow nicht abgeschnitten, Button-Padding okay.
8. **CHANGELOG-Eintrag** — User-sichtbare Aenderung dokumentieren.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Glow-Opacities sehen in einem Theme (Moon) zu blass / kaum sichtbar aus | Manueller Test in allen drei Themes + Light/Dark; falls Moon zu blass: Peak-Opacity auf 0.95/0.30 anheben |
| Header-Wert wird nicht aktualisiert, weil `make check` die String-Aenderung nicht prueft | Wert manuell in DE+EN setzen; Snapshot-Vergleich oder visueller Sim-Test |
| `onBack`-Sichtbarkeitsaenderung bricht Caller-Aufrufe | `let` ohne Modifier ist default-`internal`, externe Module sehen es nicht; Aufrufer im selben Modul (`TimerView` etc.) waren davon nie abhaengig (sie setzen die Closure via Init) |
| Subtitle-Key wird in Tests oder UI-Tests referenziert | Bereits geprueft (`grep` in `StillMomentTests/` und `StillMomentUITests/`) — keine Referenzen, sicher zu loeschen |
| Render-Performance: zwei `RadialGradient`-Kreise im Hauptthread | `RadialGradient` ist Standard-SwiftUI-Rendering; in der Praxis < 1 ms, keine Frame-Drops zu erwarten |

---

## Vorbereitung

Nichts manuell. Kein neues Xcode-Target, keine Provisioning-Profiles, keine externen Assets, keine Font-Integration (Newsreader/Geist werden bewusst nicht uebernommen).

---

## Offene Fragen

Keine — alle Klaerungen sind in den Annahmen abgebildet (`button.back` bleibt, Headline-Key wiederverwenden, strukturelle Tests). Bereit fuer `/implement-ticket shared-092 ios`.

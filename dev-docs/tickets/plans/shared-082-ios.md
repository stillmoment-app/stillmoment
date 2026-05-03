# Implementierungsplan: shared-082 (iOS)

Ticket: [shared-082](../shared/shared-082-download-konstellations-animation.md)
Plattform: **iOS**
Erstellt: 2026-05-03

---

## Scope

iOS-Teil von shared-082: Konstellations-Animation als Download-Modal. Ersetzt den `DownloadOverlayView` mit Default-`ProgressView()` in `StillMomentApp.swift:295`.

Cancel-API existiert auf iOS bereits (`AudioDownloadServiceProtocol.cancelDownload()` → `InboxHandler.cancelDownload()`). Der Cancel-Test (`testCancelDownloadForwardsToDownloadService`) existiert bereits in `InboxHandlerTests.swift:369` und bleibt unveraendert. Reines UI-Replacement plus Typography-Erweiterung.

Der Android-Teil ist [separat geplant](shared-082-android.md) und fertig implementiert (Commit `b986a4f`).

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Views/Shared/Font+Theme.swift` | Presentation | Erweitern | Neue `TypographyRole.dialogTitle` (18pt light, textPrimary) und `.dialogBody` (12pt regular, textSecondary). Halation-Kompensation wirkt automatisch. |
| `Presentation/Views/Shared/ConstellationLoader.swift` | Presentation | **NEU** | Atmender Kern + 5 orbital Punkte, scenePhase-aware Pause. |
| `Presentation/Views/Shared/DownloadOverlayView.swift` | Presentation | **NEU** | Modal-Card extrahiert aus `StillMomentApp.swift`. Backdrop + Card + ConstellationLoader + Title + Body + Cancel-Button. |
| `StillMomentApp.swift` | Presentation | Refactoring | Private `DownloadOverlayView` entfernen (extrahiert). `.overlay { ... }`-Aufruf bleibt; `.transition(.opacity)` + `.animation(.easeInOut(duration: 0.2), value: isDownloading)` ergaenzen fuer 200ms Fade. |
| `Resources/de.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys: `share.download.body`, `share.download.cancel.accessibility`. |
| `Resources/en.lproj/Localizable.strings` | Resources | Erweitern | dito |
| `CHANGELOG.md` | Docs | Erweitern | Polish-Eintrag (iOS: "Download-Modal mit Konstellations-Animation"). |

**Bestehende Strings, die wiederverwendet werden:**
- `share.download.loading` ("Meditation wird geladen…" / "Loading meditation…") als Title.
- `share.download.cancel` ("Abbrechen" / "Cancel") als Cancel-Button-Text.

**Nicht betroffen:**
- `AudioDownloadService` und `InboxHandler` — Cancel-API existiert bereits.
- `InboxHandlerTests` — `testCancelDownloadForwardsToDownloadService` deckt das AK ab.

---

## API-Recherche

### SwiftUI Animation auf iOS 16

- **`TimelineView(.animation(paused:))`** — verfuegbar ab iOS 15, Pause-Parameter ebenfalls. Frame-genaue Updates beim Rendern, kein eigener `Timer`. Wenn `paused: true`: keine weiteren Schedule-Eintraege, View bleibt eingefroren. Beim Unpause wird die Wallclock weiterverwendet — wuerde ohne Korrektur einen "Sprung" verursachen.
- **`@Environment(\.scenePhase)`** — gibt `.active | .inactive | .background` zurueck. Bekanntermassen werden Sheets unter iOS 16.0–16.3 nicht mit Environment-Werten versorgt — das `DownloadOverlayView` ist ein `.overlay`, kein Sheet, daher unkritisch.
- **`@Environment(\.themeColors)`** + **Halation-Kompensation** — bestehendes Pattern in `Font+Theme.swift`, weiter nutzen.
- **`.shadow(color:radius:)`** — Standard-API, funktioniert auf `Circle()`-Shapes.
- **`.lineSpacing()`** — fuer Body-Line-Height 1.5: 12pt × (1.5 – 1.2) ≈ 3.6pt zusaetzlicher Spacing.
- **Fonts**: Newsreader/Geist sind HTML-Designreferenz-Fonts, sind im iOS-Bundle nicht eingebunden. App nutzt durchgaengig `.system(... design: .rounded)`. Wir bleiben dabei (siehe Design-Entscheidung 1).

### Accessibility

- **`.accessibilityAddTraits(.isModal)`** — markiert die Card als modaler Bereich; VoiceOver fokussiert beim Erscheinen auf den ersten lesbaren Inhalt im Modal.
- **`.accessibilityHidden(true)`** — versteckt die Konstellation vor VoiceOver.
- **`.accessibilityLabel("Download abbrechen")`** — ueberschreibt den Button-Text fuer Screenreader.

### Deployment

- iOS Deployment Target: **16.0** (`IPHONEOS_DEPLOYMENT_TARGET`).
- Alle benoetigten APIs verfuegbar; keine Compatibility-Wrapper noetig.

---

## Design-Entscheidungen

### 1. Font-Design: System-Rounded statt Newsreader/Geist

**Trade-off:** Der Design-Handoff spezifiziert Newsreader (Serif) fuer den Title und Geist (Sans) fuer Body. Diese Fonts sind aber HTML/CSS-Designreferenz, nicht im iOS-Bundle. Sie ueber `.otf` einbinden waere ein eigenes Architektur-Ticket (App nutzt aktuell ausschliesslich System-Rounded).

**Entscheidung:** `.system(size: 18, weight: .light, design: .rounded)` fuer DialogTitle, `.system(size: 12, weight: .regular, design: .rounded)` fuer DialogBody. Gleiche Groessen wie Spec, Design konsistent zu allen anderen TypographyRoles. Android-Pendant nutzt aequivalent Nunito Light/Normal — gleiche Anmutung.

### 2. Animation: TimelineView mit Elapsed-Akkumulator

**Trade-off:** Reines `withAnimation(.linear.repeatForever)` (siehe Handoff-Skizze) ist deklarativ aber kann nicht sauber pausiert werden. `TimelineView(.animation(paused:))` pausiert sauber, aber rechnet beim Resume mit Wallclock — produziert einen sichtbaren Sprung.

**Entscheidung:** `TimelineView(.animation(paused: scenePhase != .active))` mit manuellem **Elapsed-Akkumulator** (`startDate` + `pausedElapsed`). Beim Wechsel auf inaktiv: `pausedElapsed = now - startDate` festhalten. Beim Wechsel auf aktiv: `startDate = now - pausedElapsed`. Damit: nahtloser Resume ohne Phasensprung — passt zum Android-Verhalten und wirkt ruhiger.

**Konsequenz:** Body-Closure des `TimelineView` rechnet alle Positionen rein deterministisch aus `elapsed: TimeInterval` (kein `@State`-Mutate im Body).

### 3. Glow auf Punkten und Kern

**Entscheidung:** Direkter `.shadow(color:radius:)`-Modifier auf `Circle()`. Spec gibt 9pt fuer Kern, 3pt fuer Punkte. Anders als auf Android (Canvas → Glow als zweiter Circle) kann SwiftUI `.shadow` nativ — keine Workarounds.

### 4. Modal-Verschluss-Animation: 200ms Fade in beiden Faellen

**Trade-off:** Das Ticket sagt "Bei Abschluss: fade-out 200ms" und "Cancel: schliesst Modal sofort". Wirklich differenzierte Animationen je nach Trigger sind in SwiftUI mit einer `if`-bedingten `.overlay` umstaendlich — beide Pfade fuehren zu `isDownloading = false`.

**Entscheidung:** Konsistent **200ms easeInOut Fade** fuer beide Pfade, identisch zum Android-Plan (Entscheidung dort: "konsistent zum Erfolgsfall"). Cancel-Logik ruft sofort `inboxHandler.cancelDownload()` — der Download bricht 0ms ab, nur die visuelle Huelle verblasst noch. Funktional indistinguierbar.

**Mechanik:** `.animation(.easeInOut(duration: 0.2), value: isDownloading)` auf der `.overlay`-Ebene; `.transition(.opacity)` auf dem `DownloadOverlayView`.

### 5. Card-Background: Theme-Token statt fixer Farbe

**Trade-off:** Der Handoff spec nennt explizit `linear-gradient(180deg, #2e1a14 0%, #211210 100%)` (statisch dunkel, kupfer-tint). Das wirkt nur im Kupfer-Dark-Theme korrekt — in Light Modes oder in den Themes Salbei/Daemmerung wuerde es auffallen.

**Entscheidung:** Wie im Vorgespraech festgehalten (Punkt 2): `theme.cardBackground` als Fill, `theme.cardBorder` als Stroke. Funktioniert in 3 Themes × Light/Dark = 6 Kombinationen out-of-the-box, ohne neue Theme-Tokens. Kein Gradient.

### 6. Card-Layout: VStack mit expliziten Spacings

**Entscheidung:** `VStack(spacing: 0)` mit `.padding(.bottom: 22 / 6 / 22)` an Animation/Title/Body. Cancel-Button ohne Bottom-Padding. Gibt visuelle Kontrolle pro Element entsprechend Spec.

---

## Refactorings

### 1. `DownloadOverlayView` aus `StillMomentApp.swift` extrahieren

**Warum:** Die alte `DownloadOverlayView` ist 25 Zeilen und privat im App-File. Mit Konstellation, Title, Body, Cancel und Modal-Layout wird sie deutlich groesser (~80–100 Zeilen). Eigene Datei macht sie wiederverwendbar testbar (Preview) und haelt `StillMomentApp.swift` schlank (aktuell ~320 Zeilen, file_length warning bei 400).

**Plan:**
- Neue Datei `Presentation/Views/Shared/DownloadOverlayView.swift`, internal struct (kein `private`).
- Im Body: Backdrop + Card mit ConstellationLoader, Title (themeFont .dialogTitle), Body (themeFont .dialogBody, lineSpacing), Cancel-Pill-Button.
- Konstruktor: `let onCancel: () -> Void`.
- `StillMomentApp.swift`: alte private `DownloadOverlayView` loeschen, Aufruf bleibt unveraendert.

**Risiko:** Niedrig. Reine Datei-Bewegung; Aufruf-Site identisch.

### 2. `Font+Theme.swift` Typography-Rollen ergaenzen

**Warum:** Zwei neue semantische Rollen fuer Modal-Texte. Das Pattern existiert bereits — additive Aenderung.

**Plan:**
- `case dialogTitle` und `case dialogBody` in `TypographyRole`-Enum (vor `editLabel`).
- `fontSpec`: `.fixed(size: 18, weight: .light, design: .rounded)` und `.fixed(size: 12, weight: .regular, design: .rounded)`.
- `textColor`: `\.textPrimary` bzw. `\.textSecondary`.

**Risiko:** Niedrig. Enum-Erweiterung, kein Test fuer Pattern noetig (bestehende Tests des TypographyRole-Systems decken Halation-Kompensation generisch ab — sofern vorhanden).

---

## Fachliche Szenarien

### AK: Modal-Layout

- **Gegeben:** URL aus Browser ueber Share-Sheet geteilt, Download startet.
  **Wenn:** Modal erscheint.
  **Dann:** Sichtbar sind: Backdrop (`Color.black.opacity(0.55)`, fullscreen), zentrierte Card (max 320pt breit, theme.cardBackground, theme.cardBorder, 28pt Radius), darin Konstellations-Animation (110×110) → Title → Body → Cancel-Pill.

- **Gegeben:** Modal ist sichtbar.
  **Wenn:** User tippt auf Backdrop ausserhalb der Card.
  **Dann:** Nichts passiert. Modal bleibt offen. Card faengt Tap, Backdrop ignoriert ihn.

### AK: Konstellations-Animation

- **Gegeben:** Modal erscheint frisch.
  **Wenn:** Animation startet.
  **Dann:** Atmender Kern (8pt) pulsiert (Scale 0.9↔1.15, Opacity 0.7↔1.0, 4.2s Zyklus easeInOut autoreverse). 5 Punkte rotieren auf 30pt/42pt-Orbits mit Umlaufzeiten 6.5s/9.0s und den Phasenversaetzen aus der Tabelle.

- **Gegeben:** Modal sichtbar, Animation laeuft.
  **Wenn:** App wechselt in den Hintergrund (`scenePhase != .active`).
  **Dann:** TimelineView pausiert, Punkte halten Position, kein CPU-Verbrauch durch Animation.

- **Gegeben:** Animation pausiert (App im Hintergrund).
  **Wenn:** App kehrt zurueck (`scenePhase == .active`).
  **Dann:** Animation laeuft aus letzter Position weiter — kein sichtbarer Sprung dank Elapsed-Akkumulator.

### AK: Theme-Verhalten

- **Gegeben:** Aktuelles Theme = Kupfer.
  **Wenn:** Modal erscheint.
  **Dann:** Konstellation und Cancel-Button-Text in kupfer-warmem Ton (`theme.interactive`).

- **Gegeben:** Modal sichtbar im Kupfer-Theme.
  **Wenn:** User wechselt zu Salbei.
  **Dann:** Konstellation und Cancel-Text wechseln auf gruen-glow.

- **Gegeben:** Theme = Daemmerung, Light Mode.
  **Wenn:** Modal erscheint.
  **Dann:** Card hell, Konstellation gut sichtbar, Texte lesbar.

- **Gegeben:** Theme = Daemmerung, Dark Mode.
  **Wenn:** Modal erscheint.
  **Dann:** Card dunkel, Glow gut sichtbar.

### AK: Cancel-Verhalten

- **Gegeben:** Modal sichtbar, Download laeuft.
  **Wenn:** User tippt auf "Abbrechen".
  **Dann:** `inboxHandler.cancelDownload()` wird sofort aufgerufen. `isDownloading` wechselt auf `false`. Modal verblasst mit 200ms Fade. Kein Type-Selection-Sheet erscheint, kein Eintrag in der Library.

- **Gegeben:** Cancel wurde geklickt.
  **Wenn:** Download wirft `CancellationError` / `AudioDownloadError.downloadCancelled`.
  **Dann:** `InboxHandler.processURLReference` faengt Cancel im `catch`-Pfad, gibt `.empty` zurueck, `downloadError` bleibt `nil` — kein Error-Alert.

### AK: Texte (DE + EN)

- **Gegeben:** Geraete-Locale = Deutsch.
  **Wenn:** Modal erscheint.
  **Dann:** Title "Meditation wird geladen…", Body "Einen Moment, wir holen die Aufnahme zu dir.", Cancel "Abbrechen".

- **Gegeben:** Geraete-Locale = Englisch.
  **Wenn:** Modal erscheint.
  **Dann:** Title "Loading meditation…", Body "One moment, we're fetching the recording for you.", Cancel "Cancel".

### AK: Accessibility

- **Gegeben:** VoiceOver aktiv, Modal erscheint.
  **Wenn:** Card ist `.isModal` markiert.
  **Dann:** VoiceOver-Fokus springt automatisch in das Modal, liest Title und Body in Reihenfolge.

- **Gegeben:** VoiceOver aktiv, Cancel-Button hat Fokus.
  **Wenn:** VoiceOver liest das Element.
  **Dann:** "Download abbrechen" (DE) / "Cancel download" (EN) wird gelesen, nicht nur "Abbrechen"/"Cancel".

- **Gegeben:** VoiceOver aktiv.
  **Wenn:** User navigiert durch das Modal.
  **Dann:** Konstellations-Animation wird uebersprungen (`.accessibilityHidden(true)`).

### AK: Abschluss-Uebergang

- **Gegeben:** Modal sichtbar, Download laeuft.
  **Wenn:** Download abgeschlossen → `isDownloading = false`.
  **Dann:** Modal verblasst mit 200ms Fade. Direkt darauf erscheint das Type-Selection-Sheet (`fileOpenHandler.showImportTypeSelection`).

---

## Reihenfolge der Akzeptanzkriterien (TDD-Reihenfolge)

1. **Typography-Rollen** `.dialogTitle` / `.dialogBody` — additive Erweiterung in `Font+Theme.swift`, kein Test (Pattern existiert).
2. **Strings ergaenzen** — `share.download.body` und `share.download.cancel.accessibility` in DE + EN.
3. **`ConstellationLoader`-View** — isoliertes Composable. Manuelle Verifikation in `#Preview`. Kein Unit-Test (Animation = visuell).
4. **`DownloadOverlayView`** — Modal-Card mit Backdrop + Loader + Texte + Cancel. Manuelle Verifikation in `#Preview` (Theme-Matrix).
5. **`StillMomentApp.swift`** — alte private View entfernen, neuer Aufruf bleibt; `.transition` + `.animation` fuer 200ms Fade ergaenzen.
6. **Manueller End-to-End-Test:** URL-Share → Modal → Cancel-Pfad und Erfolgs-Pfad in allen 3 Themes × Light/Dark.

---

## Vorbereitung

Keine. Alle benoetigten APIs (TimelineView, scenePhase, Theme-Tokens) verfuegbar ab iOS 16.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `TimelineView(.animation(paused:))` rendert auch bei `paused: true` einen finalen Frame; ein State-Mismatch koennte zu visuellem Springen fuehren. | Elapsed-Akkumulator entkoppelt `elapsed` von `context.date`. Body-Closure liest `pausedElapsed`, wenn `scenePhase != .active`. Manuell verifizieren: Hintergrund 5s, zurueckkommen — keine Sprungbewegung. |
| `withAnimation(.linear.repeatForever)` wuerde sich nicht sauber pausieren lassen — wir nutzen sie aber NICHT. | TimelineView berechnet Positionen aus `elapsed`, kein `withAnimation`. Kein Risiko. |
| Card-Tap leakt durch Backdrop und triggert darunterliegende Buttons. | Backdrop als eigene `Color.black.opacity(0.55)` mit `.contentShape(Rectangle())` und `.onTapGesture { /* empty */ }` — Backdrop schluckt Taps explizit. Card hat eigenen Hit-Test ueber `.background`. |
| 110×110-Konstellation auf kleinen Geraeten zu gross fuer Modal mit max 320pt | Modal-Card hat 28pt seitlichen Padding; verfuegbare Inner-Breite = 320 − 56 = 264pt. 110pt Animation passt locker. |
| Halation-Kompensation in Light Mode ueberkompensiert (Light Mode nimmt Original-Weight) | `darkModeCompensated()` greift nur bei `.dark`. Light Mode bleibt bei `.light`/`.regular` — wie spezifiziert. |
| Fade-Out kollidiert mit Type-Selection-Sheet-Erscheinen (Modal noch da, Sheet schon offen) | `.sheet` und `.overlay` sind unabhaengig im View-Tree. Sheet-Praesentation passiert via `fileOpenHandler.showImportTypeSelection`-State, ist nicht an `isDownloading` gekoppelt. Modal verblasst, Sheet erscheint — keine Konflikte. |
| Body-Text in DE laenger als 320pt-Card-Innenbreite (264pt) → Umbruch auf >2 Zeilen | Body ist deutsch ~46 Zeichen, bei 12pt rounded passen ca. 35 Zeichen pro Zeile → 2 Zeilen, akzeptabel. lineSpacing(3.6) sorgt fuer Lesbarkeit. |

---

## Offene Fragen

Keine. Alle Design-Entscheidungen sind im Vorgespraech geklaert (siehe Ticket "Entscheidungen aus dem Vorgespraech").

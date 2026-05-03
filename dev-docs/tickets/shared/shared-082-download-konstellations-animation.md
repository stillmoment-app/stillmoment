# Ticket shared-082: Download-Modal mit Konstellations-Animation

**Status**: [~] IN PROGRESS (Android)
**Plan**: [Implementierungsplan Android](../plans/shared-082-android.md)
**Prioritaet**: NIEDRIG (Polish)
**Aufwand**: iOS ~M | Android ~M (inkl. Cancel-API)
**Phase**: 4-Polish

---

## Was

Waehrend des URL-Downloads (Share-Sheet vom Browser oder URL-Import) wird ein modales Overlay angezeigt mit einer ruhigen, atmosphaerischen Animation: einem pulsierenden Kupfer-Kern in der Mitte, umkreist von 5 kleinen Lichtpunkten auf zwei Orbitalbahnen ("Konstellation").

Ersetzt:
- iOS: Den Default-`ProgressView()` in `DownloadOverlayView` (`StillMomentApp.swift:295`)
- Android: Den `AlertDialog` mit `CircularProgressIndicator` in `DownloadProgressDialog` (`NavGraph.kt:686`)

## Warum

Der aktuelle Default-Spinner ist visuell generisch und passt nicht zum meditativen Charakter der App. Die Konstellation ist eine eigene visuelle Sprache (kein Spinner-/Ring-Klischee), korrespondiert mit der Idle-Screen-H2-Variante und schafft App-weite visuelle Kohaerenz.

Beilaeufig: Android hat aktuell **keinen** Cancel-Button — der Download laesst sich dort nicht abbrechen, User muss die App verlassen. Auf iOS existiert Cancel bereits (`AudioDownloadServiceProtocol.cancelDownload()` + `InboxHandler.cancelDownload()`). Das Ticket bringt Android auf denselben Stand.

---

## Design-Handoff

`handoffs/design_handoff_download_animation/` — High-Fidelity. Final colors, typography, spacing, copy, animation timings.

Wichtig:
- **Konstellation ist `BreathingLoader`** in `import-flow.jsx:566` (historischer Name).
- **HTML/React ist Designreferenz**, nicht 1:1 zu kopieren — in nativen UI-Frameworks nachbauen.
- **Keine Lottie/Rive** — Animation ist klein und geometrisch, native Implementierung ist sauberer.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | Cancel-API existiert bereits, nur UI-Austausch |
| Android   | [ ]    | Cancel-API in `UrlAudioDownloaderProtocol` muss ergaenzt werden (Teil des Tickets) |

---

## Entscheidungen aus dem Vorgespraech

1. **Theme-Adaption Konstellation**: Kern + Punkte nutzen `theme.interactive` (Akzentfarbe). Salbei → gruen-glow, Daemmerung → blau-violett. Glow via Shadow mit `theme.interactive.opacity(0.6)`.
2. **Modal-Card**: Theme-aware. `theme.cardBackground` als Background, `theme.cardBorder` als Border. Funktioniert in Light + Dark in allen 3 Themes.
3. **Backdrop**: Bleibt der Designwert `Color.black.opacity(0.55)` — neutrale Modal-Dimming, theme-unabhaengig.
4. **Android Cancel-API**: Wird im selben Ticket ergaenzt (`UrlAudioDownloaderProtocol.cancel()` + Coroutine-Job-Hold in Impl).
5. **Tests**: Smoke-Tests (Cancel-Callback) + manuelle Verifikation aller Theme-Varianten. **Keine** Snapshot-Test-Infrastruktur einfuehren.
6. **Animation pausiert** wenn App nicht im Vordergrund (iOS `scenePhase`, Android `Lifecycle.Event.ON_PAUSE`).
7. **Typography**: Neue Rollen `dialogTitle` (Newsreader 18) + `dialogBody` (Geist 12) im Typography-System.

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders markiert -->

### Modal-Layout
- [ ] Backdrop: Volle Bildschirmflaeche, `Color.black.opacity(0.55)`, ueber dem darunterliegenden Screen
- [ ] Tap auf Backdrop: keine Aktion (Modal nur via "Abbrechen" schliessbar)
- [ ] Card zentriert, max. 320pt breit, 36pt horizontaler Padding zum Bildschirmrand
- [ ] Card-Background: `theme.cardBackground`, Border: `theme.cardBorder`, Border-Radius: 28pt
- [ ] Card-Padding: 32pt oben, 28pt seitlich, 24pt unten
- [ ] Inhalt vertikal gestackt, zentriert: Animation → Title → Body → Cancel-Button

### Konstellations-Animation
- [ ] Container 110×110pt
- [ ] Atmender Kern: 8pt Durchmesser, `theme.interactive`, mit Glow (Shadow radius 9, color = theme.interactive)
- [ ] Kern-Animation: Scale 0.9 ↔ 1.15, Opacity 0.7 ↔ 1.0, Zyklus 4.2s, easeInOut, autoreverse, endlos
- [ ] 5 orbitale Punkte gemaess Spec:

| # | Orbit-Radius | Umlaufzeit | Phasenversatz | Punkt-Groesse |
|---|--------------|------------|----------------|---------------|
| 1 | 30pt         | 6.5s       | 0.0s           | 5pt           |
| 2 | 30pt         | 6.5s       | 1.3s           | 4pt           |
| 3 | 42pt         | 9.0s       | 0.4s           | 3.5pt         |
| 4 | 42pt         | 9.0s       | 3.0s           | 3pt           |
| 5 | 42pt         | 9.0s       | 5.6s           | 3.5pt         |

- [ ] Jeder Punkt: `theme.interactive.opacity(0.7)` mit Glow (Shadow radius 3, color = theme.interactive.opacity(0.6))
- [ ] Orbitalbewegung: linear, endlos, Phasenversatz via initialer Winkel
- [ ] Animation laeuft fluessig (~60fps auf Referenzgeraeten)

### Texte (lokalisiert DE + EN)
- [ ] Title: Newsreader 18, `theme.textPrimary`, zentriert, 6pt margin-bottom
  - DE: "Meditation wird geladen…"
  - EN: "Loading meditation…"
- [ ] Body: Geist 12, `theme.textSecondary`, line-height 1.5, 22pt margin-bottom, zentriert
  - DE: "Einen Moment, wir holen die Aufnahme zu dir."
  - EN: "One moment, we're fetching the recording for you."
- [ ] Title und Body nutzen neue `TypographyRole.dialogTitle` / `.dialogBody`

### Cancel-Button (Ghost-Pill)
- [ ] Background: `theme.textPrimary.opacity(0.04)`, Border: 1pt `theme.textPrimary.opacity(0.08)`
- [ ] Text-Color: `theme.interactive`
- [ ] Geist 14, padding 10×22pt, border-radius 999 (pill)
- [ ] DE: "Abbrechen" / EN: "Cancel"
- [ ] Aktion: bricht Download ab, schliesst Modal sofort, User landet auf darunterliegendem Screen

### Verhalten
- [ ] Modal erscheint sobald Download startet (URL-Import oder Share-Sheet-Empfang)
- [ ] Modal bleibt sichtbar bis Download abgeschlossen oder abgebrochen
- [ ] Bei Abschluss: fade-out 200ms, dann Uebergang in den naechsten Step (Type-Selection-Sheet)
- [ ] Bei Fehler: Modal wird durch Error-Dialog ersetzt (Error-Variante NICHT in diesem Ticket — bleibt aktueller Stand)
- [ ] Animation pausiert wenn App nicht im Vordergrund (iOS `scenePhase != .active`, Android `Lifecycle.Event.ON_PAUSE`) — CPU-Schutz
- [ ] Keine Fortschrittsanzeige (kein Prozent, keine Bytes — bewusst zurueckgenommen)

### Android Cancel-API (NEU)
- [ ] `UrlAudioDownloaderProtocol.cancel()` ergaenzt
- [ ] `UrlAudioDownloaderImpl` haelt Coroutine-Job, Cancel bricht ihn ab
- [ ] Existierender `download()`-Test gruen, neuer Test: `cancel()` waehrend laufendem Download → Result.failure mit CancellationException
- [ ] `DownloadUrlEffect` in `NavGraph.kt` ruft `cancel()` beim Cancel-Klick

### Typography-System
- [ ] Neue `TypographyRole.dialogTitle` (Newsreader 18, theme.textPrimary, Dark-Mode-Halation-Kompensation +1 weight)
- [ ] Neue `TypographyRole.dialogBody` (Geist 12, theme.textSecondary, line-height 1.5)
- [ ] Auf Android Pendant in der bestehenden Typography-Struktur

### Accessibility
- [ ] Modal markiert als Alert/Modal:
  - iOS: `.accessibilityAddTraits(.isModal)` auf Card-Root
  - Android: `Modifier.semantics { role = Role.Alert; isTraversalGroup = true }`
- [ ] VoiceOver/TalkBack liest Titel + Body bei Erscheinen
- [ ] Cancel-Button hat `accessibilityLabel` (DE: "Download abbrechen" / EN: "Cancel download")
- [ ] Animation ohne `accessibilityElement` (rein dekorativ)

### Tests
- [ ] Unit-Test iOS: Cancel-Callback ruft `inboxHandler.cancelDownload()` auf
- [ ] Unit-Test Android: Cancel-Callback ruft `urlAudioDownloader.cancel()` auf
- [ ] Unit-Test Android: `UrlAudioDownloaderImpl.cancel()` bricht laufenden Download ab

### Dokumentation
- [ ] CHANGELOG.md (Polish, beide Plattformen)

---

## Fachliche Testszenarien

### Modal-Erscheinen
1. URL aus Browser ueber Share-Sheet teilen → Modal erscheint mit Konstellation, Title, Body, Cancel
2. Download abgeschlossen → Modal fade-out 200ms → Type-Selection-Sheet erscheint
3. Tap auf Backdrop waehrend Download → keine Reaktion, Modal bleibt
4. Tap auf Cancel waehrend Download → Modal schliesst, kein Type-Selection-Sheet, User landet auf vorherigem Screen

### Theme-Verhalten
5. In Kupfer-Theme: Konstellation kupfer-warm
6. In Salbei-Theme: Konstellation gruen-glow
7. In Daemmerung-Theme: Konstellation blau-violett
8. In Light Mode (alle Themes): Card hell, Konstellation und Texte lesbar
9. In Dark Mode (alle Themes): Card dunkel, Glow gut sichtbar

### Sprachen
10. DE: "Meditation wird geladen…" / "Einen Moment, wir holen die Aufnahme zu dir." / "Abbrechen"
11. EN: "Loading meditation…" / "One moment, we're fetching the recording for you." / "Cancel"

### Animation
12. Animation laeuft endlos, ruhig, ohne sichtbares Ruckeln
13. App in den Hintergrund (Home-Button / App-Switcher) → Animation pausiert
14. App zurueck in den Vordergrund → Animation laeuft weiter

### Cancel-Verhalten Android (NEU)
15. Cancel waehrend laufendem Download → Download bricht ab, kein Type-Selection-Sheet, keine importierte Datei in der Bibliothek
16. Erneuter Share derselben URL nach Cancel → Download startet sauber neu

### Accessibility
17. VoiceOver/TalkBack: Title + Body werden bei Modal-Erscheinen vorgelesen
18. Cancel-Button hat sprechendes Accessibility-Label

---

## Manueller Test

1. **Vorbereitung**: 3 Themes verfuegbar, Light + Dark wechselbar in den Settings
2. **Trigger**: Browser → MP3-URL teilen → Still Moment
3. **Standard-Flow**: Modal erscheint, Animation laeuft, Download-Abschluss → Type-Selection-Sheet erscheint
4. **Cancel-Flow** (iOS + Android): Modal erscheint → Cancel tippen → Modal schliesst sofort, kein Type-Selection-Sheet
5. **Theme-Matrix** (manuell durchklicken):
   - Kupfer Light, Kupfer Dark
   - Salbei Light, Salbei Dark
   - Daemmerung Light, Daemmerung Dark
6. **i18n**: Geraet auf DE → Texte deutsch. Geraet auf EN → Texte englisch.
7. **Hintergrund-Pause**: Modal erscheint, App in den Hintergrund schicken (Home), nach 3s zurueck → Animation laeuft fluessig weiter (kein Springen)
8. **VoiceOver/TalkBack**: Aktivieren, Modal triggern, Texte werden gelesen, Cancel-Button erreichbar

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Modal-Praesentation | `.overlay { … }` auf Root-View | Custom `Box`-Overlay (kein `Dialog`) damit Theme + Backdrop konsistent |
| Backdrop-Tap-Block | `.allowsHitTesting(false)` auf Backdrop, Card faengt Taps | `Modifier.pointerInput(Unit) {}` auf Backdrop |
| Animation | SwiftUI `withAnimation(.linear.repeatForever)` | Compose `rememberInfiniteTransition` |
| Lifecycle-Pause | `@Environment(\.scenePhase)` | `LocalLifecycleOwner` + `lifecycle.eventFlow` |

---

## Referenz

- **Design-Handoff**: `handoffs/design_handoff_download_animation/README.md`
- **iOS aktueller Stand**: `DownloadOverlayView` in `ios/StillMoment/StillMomentApp.swift:295`
- **Android aktueller Stand**: `DownloadProgressDialog` in `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt:686`
- **iOS Cancel-Pfad existiert**: `InboxHandler.cancelDownload()` ruft `AudioDownloadService.cancelDownload()`
- **Android Cancel-Pfad fehlt**: `UrlAudioDownloaderProtocol.kt:20` hat nur `download()`, muss um `cancel()` ergaenzt werden
- **Theme-Tokens**: `ThemeColors.swift` (iOS) / `Theme.kt` (Android) — `interactive`, `cardBackground`, `cardBorder`, `textPrimary`, `textSecondary`
- **Typography-System**: `Font+Theme.swift` (`TypographyRole`-Enum) auf iOS

---

## Hinweise

- **Performance-Caveat aus dem Handoff**: "Wenn die Animation auf aelteren Geraeten ruckelt, ist es OK, die Anzahl der orbitalen Punkte auf 3 zu reduzieren." → **Erst messen, dann optimieren**. Nicht vorab einbauen.
- **Konstellation greift visuell die H2-Idle-Screen-Variante auf** (Atemkreis-Ruhig) — bewusst gewollt, schafft App-weite visuelle Kohaerenz.
- **Fehler-Modal NICHT im Scope** dieses Tickets. Bestehender Error-Dialog (`share.download.error.*`) bleibt unveraendert. Eigenes Folge-Ticket fuer die Fehler-Variante des Konstellations-Modals.
- **Snapshot-Tests bewusst nicht** — siehe Vorgespraech (C: Smoke-Tests + manuelle Verifikation). Snapshot-Infrastruktur waere ein eigenes Architektur-Ticket.

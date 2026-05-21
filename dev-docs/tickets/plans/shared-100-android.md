# Implementierungsplan: shared-100 (Android)

Ticket: [shared-100](../shared/shared-100-idle-ring-duenn-android.md)
iOS-Pendant: [ios-045](../ios/ios-045-idle-ring-thin.md) — bereits umgesetzt
iOS-Plan-Vorbild: [ios-045 Plan](ios-045.md)
Erstellt: 2026-05-21
Branch: `feature/shared-100-android`

---

## Ziel in einem Satz

Der Idle-Ring (`BreathDial`) wird visuell auf die Running-Sprache des `PlayerRing` aus shared-096 angeglichen — 1 dp Track + 1.5 dp Bogen + kleine gefuellte Akzent-Perle, ohne die Drag-/Geometrie-/Accessibility-Logik anzufassen.

---

## Annahmen

Bewusste Festlegungen, die in den Plan eingeflossen sind. Bitte beim Review pruefen.

- **Visuelle Werte = `PlayerRing` aus shared-096.** Track 1 dp @ `primary @ 0.32`, Bogen 1.5 dp @ `primary @ 0.72` mit `StrokeCap.Round`, Bead 12 dp gefuellt in `primary` mit weichem Halo (22 dp / 18 dp Radius `* 1.8`, Alpha 0.35) als Doppel-Disc-Surrogat fuer Shadow.
- **Bead-Halo bleibt — auch im Idle.** Der `PlayerRing` hat einen leichten Halo (`BEAD_HALO_MULTIPLIER = 1.8`, `BEAD_HALO_ALPHA = 0.35`). Das Ticket sagt "kein Halo" — gemeint ist der bisherige *animierte* pulsierende Halo des Tropfens (`HALO_PULSE_DURATION_MS = 1300`). Der weiche statische Halo des `PlayerRing`-Beads erzeugt das warme Lichtperlen-Gefuehl, das fuer die Ring-Sprache konstitutiv ist. Identische Werte zu Running sind explizit gefordert. iOS verwendet aequivalent einen `shadow(color: theme.interactive.opacity(0.6), radius: 4)` am Bead — ebenfalls Soft-Glow ohne Pulsation. Wenn das Review den Halo als zu lebendig empfindet, ziehen wir die Werte zentral ueber `RingMetrics` zurueck und beide Komponenten aendern sich gemeinsam.
- **Bead-Ruhegroesse: 12 dp Durchmesser** — wie `PlayerRing.BEAD_DIAMETER_DP`.
- **Bead-Drag-Groesse: 18 dp Durchmesser** (~50 % groesser als Ruhe). Begruendung: iOS-Pendant ist 9 → 14 pt (~55 %). Unsere Baseline ist 12 dp, der gleiche Prozentwert ergibt ca. 18 dp. Wachstum mit `animateFloatAsState` und `tween(durationMillis = 150, easing = EaseOut)` — analog zum iOS-`.easeOut(duration: 0.15)`.
- **Hit-Area-Padding: 24 dp radial nach aussen** — direkt aus dem iOS-Plan und dem Handoff (`Circle().inset(by: -24)`). Auf Android setzen wir das ueber den `pointerInput`-Hit-Test um (siehe Design-Entscheidung 3) — kein Layout-Wachstum, kein Eingriff in `TimerScreen.kt`.
- **Bead-Farbe**: `MaterialTheme.colorScheme.primary` — identisch zu `PlayerRing`. Das aequivalent zur iOS-`theme.interactive`-Token-Familie ist auf Android `primary`; `dialActiveArc`/`dialDropletCore` loesen heute auch beide auf `interactive` auf.
- **Reduce Motion: kein Sonderfall noetig**. Es bleibt keine kontinuierliche Animation uebrig (Halo-Pulsation entfaellt vollstaendig). Der Bead-Grow ist Direct-Touch-Reaktion (vergleichbar mit einem Button-Press) und wird auch bei Reduced Motion belassen. Die `rememberIsReducedMotion()`-Abfrage in `BreathDial` faellt komplett weg.
- **Theme-Token-Cleanup: `dialDropletCore` und `dialDropletHalo` werden entfernt**, sobald `BreathDial` sie nicht mehr nutzt. Beide werden ausschliesslich in `BreathDial.kt` und in `Theme.kt` referenziert (Stand: heutige Recherche, `grep`). Risiko gering. `dialActiveArc` bleibt als semantischer Token — Idle und Running koennten in Zukunft unterschiedlich tonen wollen.
- **`controlTrack` vs. `primary @ 0.32`**: Der bestehende Idle-Ring verwendet `colors.controlTrack` als Track-Farbe; `PlayerRing` verwendet `primary.copy(alpha = 0.32f)`. Wir uebernehmen die Player-Sprache (Akzent-getoenter Track) — sonst sehen Idle und Running am Track unterschiedlich aus. Ist im Ticket explizit gefordert ("identische Track-Farbe").
- **Diameter aus `TimerScreen` bleibt unveraendert.** Der Idle-Ring nutzt weiterhin den uebergebenen `dialDiameter`. Nur die Strichstaerke aendert sich. `ringWidthFor(diameter)`-Helper entfaellt. Die Bead-Bahn verschiebt sich minimal nach aussen, weil `ringWidthPx` von ~16 dp auf 1.5 dp schrumpft — `BreathDialGeometryTest.dropletPosition`-Werte bleiben identisch, weil sie auf `radius` parametrisiert sind und die Call-Site `radius = (size - ringWidthPx) / 2` weiterhin sauber rechnet.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/components/BreathDial.kt` | Presentation | Aendern | Ring-Werte, Bead, Hit-Area, Halo-Pulsation entfernen, Drag-State fuer Bead-Grow |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/common/RingMetrics.kt` | Presentation | **Neu** | Geteilte Konstanten (`TRACK_STROKE_DP`, `ARC_STROKE_DP`, `BEAD_DIAMETER_DP`, Alpha-Werte) fuer Idle + Running |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/components/PlayerRing.kt` | Presentation | Aendern | Liest Werte aus `RingMetrics` statt aus eigenen `private const`-Bloecken |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Theme.kt` | Presentation | Aufraeumen | Tokens `dialDropletCore`, `dialDropletHalo` aus `StillMomentColors`-Datenklasse + `buildStillMomentColors`-Builder entfernen (nicht mehr referenziert) |
| `android/app/src/test/kotlin/com/stillmoment/presentation/ui/timer/components/BreathDialGeometryTest.kt` | Tests | Unveraendert | Geometrie/Mathematik der Drag-Berechnung — bleibt 1:1 |
| `android/app/src/test/kotlin/com/stillmoment/presentation/ui/meditations/components/PlayerRingGeometryTest.kt` | Tests | Unveraendert | Bead-Position bleibt funktional identisch |
| `CHANGELOG.md` | Doc | Aendern | User-sichtbarer Eintrag unter `Unreleased` → `Changed (Android)` |

`BreathDialGeometry.kt`, `TimerScreen.kt`, `IdleSettingsList.kt`, alle anderen Screens und Tests bleiben unangefasst. Test-Tags `timer.dial` und `timer.dial.value` werden NICHT umbenannt.

Geschaetzte Anzahl betroffener Produktiv-Dateien: **4** (`BreathDial.kt`, `RingMetrics.kt` neu, `PlayerRing.kt`, `Theme.kt`) + CHANGELOG.md.

---

## API-Recherche

Keine neuen Framework-APIs. Alles bereits vorhanden:

| API | Min. Version | Quelle | Hinweis |
|---|---|---|---|
| `Canvas` + `DrawScope.drawCircle`/`drawArc` mit `Stroke(width, cap)` | Compose 1.0+ | Compose Docs | Bereits in `PlayerRing` und `BreathDial` genutzt. |
| `animateFloatAsState` mit `tween(durationMillis, easing = EaseOut)` | Compose 1.0+ | Compose Docs | Fuer Bead-Grow auf Drag. |
| `pointerInput` + `awaitEachGesture` + `awaitFirstDown` | Compose 1.6+ | Compose Docs | Bereits in `BreathDial.dialDragModifier` — wir erweitern es um Hit-Area-Check und Drag-State-Flag. |
| `mutableStateOf(false)` + `remember` | Compose 1.0+ | Compose Docs | Lokaler Drag-State fuer Bead-Grow. |

Kein Bedarf, externe Compose-APIs nachzuschlagen — alle verwendeten Funktionen sind bereits im Projekt im Einsatz.

---

## Design-Entscheidungen

### 1. Zentrale Konstanten in `RingMetrics`

**Trade-off:** Eine separate Datei vergroessert den Diff, garantiert aber, dass Idle ↔ Running synchron bleiben. Das Ticket sagt explizit: *"Werte zentralisieren, wenn die Running-Komponente diese bereits exponiert — dann ziehen Idle und Running automatisch zusammen, wenn der Spec sich aendert."*

**Entscheidung:** Neue Datei `android/app/src/main/kotlin/com/stillmoment/presentation/ui/common/RingMetrics.kt` mit:

```kotlin
internal object RingMetrics {
    const val TRACK_STROKE_DP = 1
    const val ARC_STROKE_DP = 1.5f
    const val BEAD_DIAMETER_DP = 12
    const val BEAD_HALO_MULTIPLIER = 1.8f
    const val BEAD_HALO_ALPHA = 0.35f
    const val TRACK_ALPHA = 0.32f
    const val ARC_ALPHA = 0.72f
}
```

`BreathDial` und `PlayerRing` lesen daraus. Damit ist die visuelle Einheit erzwungen. Lage: `presentation/ui/common/` weil das Pendant `BreathingCircle.kt` ebenfalls dort liegt (geteilte UI-Bausteine).

### 2. Bead-Grow auf Drag — eigenes `mutableStateOf`

**Trade-off:** Wert-basiert (Bead waechst, wenn `value` sich aendert) ist unzuverlaessig — Drag bleibt auch ohne Wertaenderung moeglich, wenn der Finger innerhalb desselben Minuten-Buckets bewegt wird.

**Entscheidung:** Lokaler State in `BreathDial`:

```kotlin
var isDragging by remember { mutableStateOf(false) }
val beadDiameter by animateFloatAsState(
    targetValue = if (isDragging) BEAD_DRAG_DIAMETER_DP else RingMetrics.BEAD_DIAMETER_DP.toFloat(),
    animationSpec = tween(durationMillis = 150, easing = EaseOut),
    label = "breathDialBeadDiameter",
)
```

`isDragging` wird in `awaitFirstDown` auf `true` gesetzt, in der `while (pressed)`-Schleife geprueft (Loslassen oder Pointer-Cancel → `false`). Beim Cancel via `event.changes.any { it.pressed }` ist die bestehende Logik bereits korrekt — wir setzen `isDragging = false` einfach am Ende des Gesture-Blocks.

### 3. Hit-Area-Erweiterung — Hit-Test im `pointerInput`

**Trade-off:** Auf iOS reicht `contentShape(Circle().inset(by: -24))`, weil SwiftUI Hit-Testing strikt am `contentShape` haengt. Auf Compose haengt das Hit-Testing am Layout-Frame des Modifiers — der `pointerInput` greift sowieso auf dem gesamten `Box.size(diameter)`. Eine groessere Box wuerde das `TimerScreen`-Layout (Spacer-Verteilung) aendern.

**Entscheidung:** Wir lassen die Box-Groesse unveraendert auf `diameter` und nutzen aus, dass `BreathDialGeometry.valueFromPoint` mathematisch fuer *jeden* Punkt eine gueltige Minute liefert (atan2-Winkel und Klemmung). Der bestehende `sqrt > ringRadius * 0.5f`-Gate verhindert die Zentral-Tap-Zone. Das gibt uns die "knapp neben dem Ring"-Hit-Area implizit — solange der Touch innerhalb der `diameter`-Box ist (typische dialDiameter sind 180–220 dp; Ring sitzt bei 1.5 dp Stroke fast direkt am Rand, also bleibt zwischen sichtbarem Ring und Box-Rand effektiv ca. 0–1 dp Spielraum).

Um die im Ticket geforderte "spuerbare" Hit-Area-Erweiterung *nach aussen* zu erreichen, vergroessern wir den `pointerInput`-Modifier-Bereich gezielt mit einem auessern `Modifier.padding(-24.dp)` oder besser durch ein Wrapper-`Box` mit `Modifier.size(diameter + 48.dp)`. Compose erlaubt negatives Padding nicht direkt; sauberer Weg:

```kotlin
Box(
    modifier = modifier
        .size(diameter + HIT_AREA_PADDING_DP.dp * 2)       // groessere Hit-Box
        .dialDragModifier(...)
        .dialAccessibilityModifier(...),
    contentAlignment = Alignment.Center,
) {
    Box(modifier = Modifier.size(diameter).testTag("timer.dial")) {
        DialRingsAndBead(...)
        DialCenterText(...)
    }
}
```

Der `testTag` und die sichtbaren Kinder bleiben im inneren `diameter`-Box — die `TimerScreen`-Layout-Berechnung haengt am `BreathDial`-Composable-Frame, der jetzt 48 dp groesser ist. **Konsequenz:** Wir muessen pruefen, ob die Spacer in `TimerScreen.kt` darauf empfindlich reagieren (`Spacer.weight(1f)` fangen das in der Regel ab). Falls ein Re-Layout-Problem auftritt, fallen wir auf die *implizite* Hit-Area zurueck (siehe oben — die mathematische Bedeutung jedes Touches innerhalb der Box ist die natuerliche Vergroesserung). Der manuelle Test-Schritt 4 deckt das ab.

Konstante: `private const val HIT_AREA_PADDING_DP = 24` direkt in `BreathDial.kt` (kein `RingMetrics`-Token, weil nur Idle die Hit-Area-Erweiterung braucht — der `PlayerRing` ist nicht interaktiv).

---

## Refactorings

1. **`RingMetrics.kt` als neue geteilte Konstanten-Datei.** Keine Logik, nur sieben Konstanten. Risiko: minimal.
2. **`PlayerRing.kt` auf `RingMetrics` umstellen.** Werte sind 1:1 identisch — keine Verhaltensaenderung. Bestehende `PlayerRingGeometryTest` und Screenshots bleiben gruen.
3. **Theme-Token-Cleanup (`dialDropletCore`, `dialDropletHalo`).** Beide werden ausschliesslich in `BreathDial.kt` (entfaellt nach Migration) und in `Theme.kt` (Definition) referenziert. Wir entfernen Parameter aus der `StillMomentColors`-Datenklasse, aus `buildStillMomentColors` und aus dem `LocalStillMomentColors`-Default. Risiko: minimal. Pre-Commit-Check: `grep -r "dialDropletCore\|dialDropletHalo" android/` muss leer sein.
4. **`rememberIsReducedMotion()`-Aufruf aus `BreathDial.kt` entfernen.** Import bleibt frei (Datei wird sauberer).

Kein anderes Refactoring noetig. `BreathDialGeometry` bleibt unveraendert.

---

## Fachliche Szenarien

### AK-1: Idle-Ring sieht aus wie der laufende Ring

- **Gegeben** Timer-Tab im Idle-Modus geoeffnet
  **Wenn** User sieht den Dauer-Picker
  **Dann** Track-Stroke 1 dp in `primary @ 0.32`, Bogen-Stroke 1.5 dp in `primary @ 0.72` mit `StrokeCap.Round` — exakt die `PlayerRing`-Werte.

- **Gegeben** Timer mit "Beginnen" gestartet, Player-Ring (oder Mond — Idle-Ring referenziert die Familien-Sprache, nicht den Mond) wird gezeigt
  **Wenn** Visueller Vergleich Idle-Ring vs. `PlayerRing`
  **Dann** Beide Ringe wirken aus derselben Familie — identische Strichstaerke, identische Farb-Alpha-Werte.

### AK-2: Bead ist klein und in Akzent-Farbe

- **Gegeben** Idle-Ring im Ruhezustand
  **Wenn** User schaut auf die Bead-Position (entspricht aktuellem Minuten-Wert auf der Ring-Bahn)
  **Dann** Bead ist ein 12-dp-Kreis in `primary` mit weichem statischen Halo (22 dp Radius @ 0.35 Alpha) — kein umrahmter Tropfen, keine Pulsation.

### AK-3: Bead vergroessert sich beim aktiven Drag

- **Gegeben** Bead in Ruhegroesse (12 dp)
  **Wenn** User legt Finger auf den Ring und beginnt zu ziehen
  **Dann** Bead waechst sichtbar auf ~18 dp, Wachstum mit `EaseOut`/150 ms.

- **Gegeben** Bead in vergroessertem Zustand
  **Wenn** User hebt den Finger
  **Dann** Bead schrumpft zurueck auf 12 dp mit derselben Animation.

### AK-4: Touch-Area reicht ueber den Ring hinaus

- **Gegeben** Idle-Ring mit duennem 1.5-dp-Bogen und kleinem 12-dp-Bead
  **Wenn** User tippt 20 dp ausserhalb des sichtbaren Rings (oberhalb der Zentrum-Glyphe)
  **Dann** Drag-Geste startet trotzdem, Wert aendert sich.

- **Gegeben** User tippt im Zentrum der Dial (in der Naehe der Zahl)
  **Wenn** User beginnt Drag-Geste
  **Dann** Geste wird ignoriert (bestehender `sqrt > ringRadius * 0.5f`-Gate greift weiterhin).

### AK-5: Idle-Ring atmet nicht

- **Gegeben** Timer-Tab im Idle, User wartet ohne Interaktion
  **Wenn** User schaut auf den Ring ueber 8 s
  **Dann** Keine sichtbare Bewegung — kein pulsierender Halo, kein Glow, keine Skalierung. Auch keine `rememberInfiniteTransition` mehr im Code-Pfad.

### AK-6: Drag/Klemmung/Mittel-Anzeige unveraendert

- **Gegeben** BreathDial mit value=18
  **Wenn** User dragt zur 3-Uhr-Position
  **Dann** Wert springt auf 15, Mittel-Text zeigt "15 Minuten".

- **Gegeben** BreathDial mit value=1
  **Wenn** User dragt auf die 12-Uhr-Position
  **Dann** Wert bleibt 1 (Klemmung greift).

### AK-7: TalkBack-Slider unveraendert

- **Gegeben** TalkBack aktiv, Fokus auf dem Dial
  **Wenn** User wischt nach oben (Adjustable-Up)
  **Dann** Wert erhoeht sich um 1, TalkBack liest "X Minuten" vor (kommt aus `stateDescription`).

- **Gegeben** Wert bei 60
  **Wenn** User wischt weiter nach oben
  **Dann** Wert bleibt 60 (`clampValue`-Klemmung im `setProgress`-Callback).

### AK-8: Reduce Motion ohne Auswirkung

- **Gegeben** System-Einstellung "Animationen entfernen" aktiv (`TRANSITION_ANIMATION_SCALE = 0`)
  **Wenn** User oeffnet Timer-Tab im Idle
  **Dann** Idle-Ring sieht identisch aus wie mit Reduce Motion aus — kein sichtbarer Unterschied, weil ohnehin keine kontinuierliche Animation existiert.

---

## Reihenfolge der Akzeptanzkriterien (TDD-Fahrplan)

1. **Vorbereitung — `RingMetrics.kt` anlegen** + `PlayerRing.kt` darauf umstellen. `make test-unit-agent` und Player-Preview-Smoketest verifizieren — keine Verhaltensaenderung im Running.
2. **AK-1 + AK-2 + AK-5: Ring-Optik und Halo umstellen** in `BreathDial.kt`. Track-Farbe + Stroke-Werte aus `RingMetrics`, Bead als statischer Bogen-Vorderkanten-Punkt mit Halo, `rememberIsReducedMotion` + `haloAnimatedRadiusPx` + Tropfen-Body komplett entfernen. Existierende `BreathDialGeometryTest` bleibt gruen (Mathematik unveraendert).
3. **AK-3: Bead-Grow auf Drag** — `isDragging`-State + `animateFloatAsState`, gesetzt in `awaitFirstDown` und am Ende der `awaitEachGesture`-Loop.
4. **AK-4: Hit-Area erweitern** — Outer-Wrapper-Box mit `diameter + 2 * HIT_AREA_PADDING_DP.dp`, innen `Modifier.size(diameter)` mit `testTag("timer.dial")` (Test-Tag bleibt auf der visuellen Kachel).
5. **Cleanup: Theme-Tokens `dialDropletCore` + `dialDropletHalo` entfernen** (`Theme.kt`).
6. **AK-6 / AK-7 / AK-8 verifizieren** — bestehende Tests + manueller Smoke-Test (Ticket-Schritte 1–7) im Emulator.
7. **CHANGELOG.md** ergaenzen (Eintrag unter `### Changed (Android)` mit Verweis auf Ticket).
8. **Quality Gate** — `make -C android check`, `make -C android test-unit-agent`, dann manueller Smoke-Test im Emulator.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `Modifier.size(diameter + 48.dp)`-Wrapper verschiebt das Layout in `TimerScreen.kt` (Headline-zu-Dial-Spacer oder Dial-zu-Liste-Spacer reagieren empfindlich) | Manueller Smoke-Test auf Standard- und Compact-Geraet (Screen-Hoehe < 700 dp). Falls ein Re-Layout sichtbar wird: Fallback auf die *implizite* Hit-Area (Box bleibt bei `diameter`) — die mathematische Bedeutung jedes Touches innerhalb der Box deckt "knapp neben dem Ring" bereits ab. |
| `mutableStateOf(false)` fuer `isDragging` wird in `pointerInput`-Lambda nicht korrekt durch Recomposition aktualisiert | `pointerInput(Unit)` mit `awaitEachGesture` und expliziten `rememberUpdatedState`-Bindings — analog zum bestehenden `currentValue`/`currentOnChange`-Pattern. Falls Stale-Lambda-Probleme auftreten ([feedback_compose_stale_lambda](../../memory/feedback_compose_stale_lambda.md)): `rememberUpdatedState(::setIsDragging)` einziehen. |
| Theme-Token-Cleanup uebersieht Verwendung in einer Test-Datei oder einem Preview | Pre-Commit-Check: `grep -rn "dialDropletCore\|dialDropletHalo" android/` muss nach dem Cleanup 0 Treffer liefern. |
| Screenshot-/UI-Tests, die das BreathDial visuell pixeln, schlagen fehl | Aktueller Stand: keine pixelbasierten UI-Tests fuer den BreathDial (`grep -r "BreathDial" android/app/src/androidTest`). Risiko damit minimal. |
| `controlTrack` vs. `primary @ 0.32` als Track-Farbe — bestehende Designer-Erwartung am Idle-Ring koennte ein neutraler Track sein | Ticket fordert *identische* Track-Farbe zum Running-Ring → `PlayerRing` verwendet `primary @ 0.32`. Wir folgen dem Ticket strikt. Wenn der Review das anders sieht, ist es eine einzeilige Aenderung in `RingMetrics` (oder ein zweiter Token `IDLE_TRACK_ALPHA`). |

---

## Offene Fragen

- [ ] **Bead-Drag-Groesse 18 dp** — passt das visuell, oder lieber dezenter (z.B. 16 dp)? Wert kann beim Review im Emulator final justiert werden.
- [ ] **Hit-Area-Padding 24 dp** — koennte ungewollt in die `timer_idle_headline`-Tap-Zone reichen, falls die Spacer in `TimerScreen.kt` knapp sind. Falls ja: 16 dp als Kompromiss.
- [ ] **Halo am Idle-Bead beibehalten?** Ticket sagt "kein Halo" — wir interpretieren das als "kein *pulsierender* Halo" und behalten den statischen 22-dp-Glow des `PlayerRing`-Beads, weil Idle und Running sonst sichtbar unterschiedlich wirken. Beim Review final entscheiden.

---

## Was NICHT im Scope

- Settings-Liste, Pre-Roll, +/−-Buttons, Sheet-Picker, Tab-Bar, alle anderen Screens.
- Aenderung der Drag-Geste, Winkelberechnung oder Klemmung 1–60 Min.
- Aenderung des Zentral-Texts (Zahl + "Minuten").
- Aenderung der TalkBack-Slider-Rolle oder Increment/Decrement-Actions.
- Aenderung des `dialDiameter`-Werts in `TimerScreen.kt` (nur die Strichstaerke aendert sich).

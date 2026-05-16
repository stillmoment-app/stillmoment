# Implementierungsplan: shared-095 (iOS)

Ticket: [shared-095](../shared/shared-095-running-timer-mondphase.md)
Erstellt: 2026-05-16
Scope: nur iOS (Android folgt spaeter)

---

## Mentales Modell

Die heutige Hauptphasen-Visualisierung ist die Sanduhr-Vessel (ios-046): `RunningTimerDisplay` legt `VesselView` links neben einen Restzeit-Textblock. Der Mondphasen-Handoff dreht das Layout um — Zeit-Block oben, Mond im unteren Drittel — und ersetzt das Vessel komplett durch eine Komposition aus drei Kreislagen:

1. **Halo** (unten, statische Geometrie, smoothstep-Alpha)
2. **Mond-Disc** (statisch, radialer Verlauf "Beleuchtung oben-links")
3. **Schatten-Disc** (driftet linear nach links: `offset = -progress × 2 × moonRadius`, am Ende komplett aus dem Bildausschnitt)

Sitzungs-Progress (0 → 1) treibt sowohl Schatten-Offset (linear) als auch Halo-Alpha (smoothstep). Bewegung erfolgt sekuendlich — `TimerViewModel.progress` tickt einmal pro Sekunde; die View glaettet die Schatten-Bewegung ueber `.animation(.linear(duration: 1.0))`. Reduce-Motion deaktiviert die Glaettung; der Schatten springt dann sichtbar, aber unauffaellig in Sekunden-Schritten.

Damit aendert sich rein an der Mondphase nichts am Domain- oder ViewModel-Layer. Die existierenden Computed Properties `progress`, `formattedRemainingMMSS`, `runningSubLabel`, `accessibilityRemainingTimeValue` werden weiter konsumiert.

---

## Annahmen

- **Voraussetzung shared-094 ist gemerged.** Plan baut auf der finalen Kerzenschein-2.0-Palette (textSecondary/textPrimary, backgroundGradient mit Akzent-Stop) auf. Falls shared-094 nicht steht, blockiert dieses Ticket — die Halo-Farbe ist auf den Akzent-Stop abgestimmt.
- **Mond-Farben hardcoded in der View, nicht als Theme-Tokens** — analog zum bestehenden Pattern in `VesselView` und `CardRowBackground` (siehe shared-094 Plan, Annahme 1). Single-Theme-System, Werte sind aus dem Handoff "final und pixelgenau", werden nirgends ausserhalb der Mond-Komponente verwendet. Mond-Disc-Verlauf, Schatten-Farbe und Halo-Stops werden via `@Environment(\.colorScheme)` zwischen Light und Dark gewechselt.
- **"Snapshot-Tests" werden pragmatisch interpretiert** — das Projekt setzt keine Unit-Snapshot-Library ein (`pointfreeco/swift-snapshot-testing` nicht vorhanden); Visualisierungen werden durch `#Preview`-Coverage + Fastlane-Screenshots verifiziert. Das ist auch das Pattern von ios-046 (Sanduhr-Vessel hat keine Snapshot-Tests). Stattdessen: drei `#Preview`-Faelle (Start/Halbzeit/Ende) × Light + Dark in der neuen `MoonPhaseView`, plus Fastlane-Running-Screenshot wird aktualisiert.
- **Close-Button bleibt oben links** (`.navigationBarLeading`) — entspricht heutigem App-Stand und Handoff-Wortlaut "bleibt unveraendert vom aktuellen Running Timer". Der Handoff-HTML zeigt ihn oben rechts; das ist mit dem aktuellen iOS-Stand inkonsistent und wird zugunsten der App entschieden.
- **Layout proportional statt absoluten Pixeln.** Handoff misst auf 340 × 736 (alt-iPhone), wir nutzen `GeometryReader` und verteilen vertikal: Toolbar-Slot oben, Spacer, Zeit-Block, Spacer, Mond, Spacer (etwas groesser unten, damit Mond im unteren Drittel sitzt). Mond-Durchmesser: 220 pt Standard, 180 pt auf compact height (`< 700 pt`).
- **Existing Typography-Rollen werden wiederverwendet** — Eyebrow = `.cardLabel` mit `.tracking(2.4)` (heutiger `timer.running.remaining`-Stil), Zeit = `.timerRunning`, Sub = `.bodySecondary` mit `.italic()`. Diese Drei werden heute schon in `RunningTimerDisplay.textColumn` so verwendet.
- **VesselView wird geloescht.** Kein anderer Aufrufer existiert (`grep` bestaetigt). Nicht "auf Halde" lassen; im Bedarfsfall ist sie in der Git-Historie.
- **Schatten ist eine einfache schwarze Kreis-Scheibe gleicher Groesse wie der Mond, kein Maskieren.** Das genuegt, weil der Mond selbst ein Circle ist und Schatten + Mond geometrisch deckungsgleich sind, solange `offset < moonRadius`. Bei `offset > moonRadius` ueberlappt der Schatten den Mond nicht mehr — der Schatten ist dann zum Teil ausserhalb des Mondes, sichtbar als dunkle Form. Loesung: Schatten als Sibling-Layer **mit dem Mond-Container clip-maskiert** (z.B. `.mask(Circle())` auf einen ZStack aus Disc + Schatten). Das clipt den Schatten exakt auf die Mondform und gibt automatisch den richtigen Look fuer alle Progress-Werte.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Views/Timer/Components/MoonPhaseView.swift` | Presentation | NEU | Komposition Halo + Mond-Disc + Schatten. Liest `progress: Double`, `reduceMotion: Bool`, optional `outerSize: CGFloat = 220`. ColorScheme-aware Hardcode-Farben. Keine Theme-Tokens. |
| `Presentation/Views/Timer/Components/RunningTimerDisplay.swift` | Presentation | Refactor | Layout-Wechsel von HStack (Vessel + Text) zu VStack (TimeBlock + MoonPhase mit Spacer-Verhaeltnissen, sodass Mond unteres Drittel und Text oberes Drittel trifft). Konsumiert `MoonPhaseView`. Public API bleibt (`progress`, `remainingTimeText`, `durationLabel`, `accessibilityTimeValue`, `reduceMotion`, `isCompactHeight`). |
| `Presentation/Views/Timer/Components/VesselView.swift` | Presentation | Loeschen | Kein anderer Aufrufer. Datei + Previews entfernen. |
| `CHANGELOG.md` | Docs | Aendern | Eintrag unter "Unreleased": Running-Timer-Visualisierung von Sanduhr auf Mondphase umgestellt. |

### Codestellen, die explizit unveraendert bleiben

- `Application/ViewModels/TimerViewModel.swift` — `progress`, `formattedRemainingMMSS`, `runningSubLabel`, `accessibilityRemainingTimeValue` bleiben.
- `Domain/Models/MeditationTimer.swift` — `progress`-Berechnung bleibt.
- `Presentation/Views/Timer/TimerView.swift` — `timerDisplay` ruft weiterhin `RunningTimerDisplay` mit identischer Parameter-Signatur auf.
- `Presentation/Views/Shared/BreathingCircleView.swift` — Pre-Roll-Phase bleibt; Mondphase ersetzt nur die Hauptphasen-Visualisierung.
- Theme-Dateien (`ThemeColors.swift`, `ThemeColors+Palettes.swift`) — keine neuen Slots, hardcode in der View.

---

## API-Recherche

| API | Verfuegbarkeit | Verwendung |
|---|---|---|
| `RadialGradient(stops:center:startRadius:endRadius:)` | iOS 13+ | Mond-Disc-Verlauf (`center: UnitPoint(x: 0.35, y: 0.35)`, drei Stops Cream→Mid→Ocker) |
| `RadialGradient(colors:center:startRadius:endRadius:)` | iOS 13+ | Halo-Schein, Center im Mond-Mittelpunkt, `endRadius` ca. doppelter Mond-Radius |
| `.mask(Circle())` auf ZStack | iOS 13+ | Schatten-Disc auf Mondform clippen, sodass der nach links driftende Schatten an der Mondkante endet |
| `.offset(x:)` mit linearer Animation | iOS 13+ | Schatten-Bewegung — `Animation.linear(duration: 1.0)` glaettet sekuendliche progress-Updates |
| `@Environment(\.accessibilityReduceMotion)` | iOS 13+ | Glaettung abschalten — Schatten springt in Sekunden-Schritten |
| `@Environment(\.colorScheme)` | iOS 13+ | Light/Dark-Switch fuer Disc-, Schatten- und Halo-Farben |

Alle APIs werden bereits projektweit eingesetzt (z.B. `VesselView`, `BreathingCircleView`). Kein Drittanbieter-Package noetig. iOS 16 Deployment-Target ist mehr als erfuellt.

---

## Designentscheidungen

### 1. Mond-Farben hardcoded vs. Theme-Tokens

**Trade-off:** Tokens machen Werte zentral aenderbar; hardcoded in der View folgt dem etablierten Pattern (VesselView, CardRowBackground, SoftFadeOverlay nach shared-094) und vermeidet sechs bis acht neue Slots, die nirgends sonst verwendet werden.
**Entscheidung:** Hardcoded mit ColorScheme-Switch. Bei Bedarf spaeter nachziehbar; Werte sind aus dem Handoff "final und pixelgenau".

### 2. Schatten als Sibling vs. Clip-Maske vs. Crescent-Geometrie

**Trade-off:** Echte Mondsichel-Geometrie (Bezier-Pfad mit zwei Kreisboegen, der ueber `progress` mor­phed) waere "korrekter", aber Bezier-Animation ist heikel und shape-morphing-anfaellig. Sibling-Schatten ohne Clip wuerde bei `offset > moonRadius` als dunkle Form ausserhalb des Mondes sichtbar — falsch. Clip-Maske (`ZStack { Disc; Shadow }.mask(Circle())`) gibt die einfachste korrekte Loesung: Schatten ist immer nur dort sichtbar, wo der Mond ist; sobald der Schatten den Mond verlaesst, ist nichts mehr zu sehen.
**Entscheidung:** Clip-Maske. Exakt das Verhalten aus dem HTML-Handoff (`-200 cx`-Rand-Strecke raeumt den Bildausschnitt automatisch).

### 3. Reduce-Motion-Verhalten: Bewegung weglassen vs. diskret aktualisieren

**Trade-off:** Bewegung komplett wegfallen lassen (Mond bleibt Schwarz bis zum Ende) ist die einfachste Reduce-Motion-Implementation, hat aber den Nachteil, dass der visuelle Sitzungs-Fortschritt fehlt. Diskret aktualisieren (sekuendliche Spruenge) erhaelt die Information und ist die Akzeptanz-Anforderung.
**Entscheidung:** Diskret aktualisieren — bei `reduceMotion = true` keine `.animation(...)` auf den Schatten-Offset; `progress` springt sekuendlich (das ist die nativ vorliegende Tick-Rate des ViewModels). Das ergibt einen sichtbaren, aber subtilen Sprung pro Sekunde. Halo-Alpha-Aktualisierung verhaelt sich analog.

### 4. Snapshot-Tests vs. Preview-Coverage + Fastlane

**Trade-off:** Echte Snapshot-Tests (z.B. `pointfreeco/swift-snapshot-testing`) wuerden Regressionen automatisiert fangen; bedeuten aber neue SPM-Dependency, Setup im Test-Target, Image-Diffing-Infrastruktur und Maintenance der Reference-Images. Preview + Fastlane (Pattern von ios-046 und shared-090) ist das etablierte Verfahren in diesem Repo.
**Entscheidung:** Preview-Coverage + Fastlane. Sechs `#Preview`-Faelle (progress 0.0, 0.5, 1.0 × Light + Dark) im neuen `MoonPhaseView`, plus eine Preview auf compact height. Fastlane-Running-Screenshot wird im Anschluss neu generiert; Drift wird damit beim naechsten Fastlane-Run sichtbar.

### 5. VesselView loeschen vs. behalten

**Trade-off:** Behalten haelt eine alternative Visualisierung in der Codebasis fuer eventuelle Theme-Varianten; loeschen reduziert toten Code und entspricht dem CLAUDE.md-Prinzip "delete unused code completely".
**Entscheidung:** Loeschen. Single-Theme-System, kein Aufrufer ausser dem RunningTimerDisplay (`grep` bestaetigt). Im Bedarfsfall in der Git-Historie verfuegbar.

### 6. Mond-Container-Groesse und Position

**Entscheidung:** `MoonPhaseView` nimmt einen `outerSize`-Parameter (default 220 pt, compact 180 pt) und rendert in `frame(width: outerSize + haloPadding, height: outerSize + haloPadding)`. Der Halo-Padding (~30 % zusaetzlich auf jeder Seite) sorgt dafuer, dass der weiche Halo nicht abgeschnitten wird. Im `RunningTimerDisplay` werden die VStack-Spacer-Verhaeltnisse so gesetzt, dass die Mond-Mitte ungefaehr auf 2/3 der Container-Hoehe sitzt:

```
Spacer (1× — vertikal kompakt, oberer Bereich)
TimeBlock (oberes Drittel)
Spacer (2× — fuellt den Mittelraum)
MoonPhaseView (gehoert ins untere Drittel)
Spacer (1× — kleiner Boden-Rand)
```

Konkrete Spacer-Verhaeltnisse werden im Code festgelegt; Validierung gegen die Handoff-HTML-Preview.

---

## Refactorings

1. **`RunningTimerDisplay` umkrempeln** — von HStack (Vessel links, Text rechts) zu VStack (Text oben, Mond unten). Public API bleibt; einzig die interne Komposition aendert sich.
   - Risiko: Niedrig. Einziger Aufrufer ist `TimerView.timerDisplay(...)`, dort wird `RunningTimerDisplay(progress:, remainingTimeText:, durationLabel:, accessibilityTimeValue:, reduceMotion:, isCompactHeight:)` aufgerufen — Signatur bleibt unveraendert.

2. **`VesselView` und seine vier Previews entfernen** — Datei loeschen, im Synchronisations-Group erkennt Xcode das automatisch.
   - Risiko: Niedrig. Kein Aufrufer ausser `RunningTimerDisplay`, der mit dem Refactor auf `MoonPhaseView` umgestellt wird.

---

## Fachliche Szenarien

### AK Visualisierung — Start

- **Gegeben:** Sitzung beginnt (`progress = 0.0`)
  **Wenn:** `MoonPhaseView` rendert
  **Dann:** Mond-Disc komplett vom Schatten ueberdeckt; visuell eine einheitlich schwarze Kreisflaeche. Kein sichtbarer Schattenrand (Schatten und Mond exakt deckungsgleich). Halo nahezu unsichtbar (Alpha ≈ 0.02).

### AK Visualisierung — Halbzeit

- **Gegeben:** Sitzung halb vorbei (`progress = 0.5`)
  **Wenn:** `MoonPhaseView` rendert
  **Dann:** Schattenkante steht senkrecht in der Mondmitte; rechte Mondhaelfte ist beleuchtet (Cream→Ocker), linke Mondhaelfte schwarz. Halo deutlich sichtbar, aber zurueckhaltend (smoothstep-Alpha ≈ 0.16).

### AK Visualisierung — Naehe Ende

- **Gegeben:** Sitzung ist 90 % vorbei (`progress = 0.9`)
  **Wenn:** `MoonPhaseView` rendert
  **Dann:** Mond ist fast vollstaendig erleuchtet; nur ein schmaler Schatten-Streifen am linken Mondrand verbleibt. Halo nahe Maximum (Alpha ≈ 0.45).

### AK Visualisierung — Ende

- **Gegeben:** Sitzung beendet (`progress = 1.0`)
  **Wenn:** `MoonPhaseView` rendert
  **Dann:** Voller Mond mit warmem Disc-Verlauf, **kein** Schatten-Rest sichtbar (Schatten liegt geometrisch ausserhalb des Mond-Clips). Halo maximal (Alpha = 0.5).

### AK Animation — Schatten linear, Halo smoothstep

- **Gegeben:** Sitzung laeuft, `progress` tickt einmal pro Sekunde
  **Wenn:** Eine Sekunde vergeht
  **Dann:** Schatten-Offset interpoliert linear ueber 1 s zum neuen Wert; sieht fliessend aus, kein Ruck. Halo-Alpha aktualisiert sich smoothstep-gewichtet — bleibt in der ersten Sitzungshaelfte unauffaellig, waechst spaeter beschleunigt.

### AK Pause / Einfrieren

- **Gegeben:** Sitzung ist pausiert oder die App wurde wieder aufgenommen und `progress` aendert sich nicht
  **Wenn:** `MoonPhaseView` rendert
  **Dann:** Schatten und Halo bleiben auf der letzten Position stehen (keine zusaetzliche Animation noetig — keine Aenderung des `progress`-Wertes triggert keine Re-Animation).

### AK Light Mode

- **Gegeben:** Geraet ist im Light Mode (Sunrise-Hintergrund nach shared-094)
  **Wenn:** Mondphase rendert
  **Dann:** Disc-Verlauf von `#FFF3DD` → `#E8C896` → `#9A6A42` (nahezu Weiss im Zentrum-oben-links → tiefer Ocker am Rand). Schatten ist `#3A2418` (warmes Tinten-Dunkel, nicht Reinschwarz). Halo-Farbe `#FCE8C8` aussen, `#B85F46` innen. Vollmond am Ende bleibt klar lesbar gegen den hellen Hintergrund.

### AK Dark Mode

- **Gegeben:** Geraet ist im Dark Mode
  **Wenn:** Mondphase rendert
  **Dann:** Disc-Verlauf `#F4E2C8` → `#E5C8A8` → `#B89478` (warmes Cream zu Ocker). Schatten ist `#1A100C` (= dark `backgroundPrimary`, verschmilzt mit Hintergrund). Halo-Farbe `#F2C8A8` aussen, `#C77D63` innen.

### AK Reduce Motion

- **Gegeben:** Reduce-Motion ist aktiviert (Bedienungshilfen → Bewegung)
  **Wenn:** Sitzung laeuft, eine Sekunde vergeht
  **Dann:** Schatten-Offset springt diskret zum neuen Wert (keine fliessende Interpolation), aber nur einmal pro Sekunde (Tick-Rate des ViewModels). Halo-Alpha aktualisiert sich analog diskret. Keine 60-fps-Animation, kein Ruckeln.

### AK Layout

- **Gegeben:** iPhone 15 (393 × 852)
  **Wenn:** `RunningTimerDisplay` rendert
  **Dann:** Zeit-Block (`VERBLEIBEND` / `07:23` / `von 10 Minuten`) sitzt im oberen Drittel des verfuegbaren Raumes, Mond (220 pt Durchmesser) sitzt im unteren Drittel mit weichem Halo. Close-Button erscheint oben links als Toolbar-Item.

- **Gegeben:** iPhone SE (375 × 667, compact height)
  **Wenn:** `RunningTimerDisplay` rendert mit `isCompactHeight: true`
  **Dann:** Mond-Durchmesser 180 pt statt 220 pt, Spacer-Verhaeltnisse bleiben. Kein Overflow, kein abgeschnittener Halo.

- **Gegeben:** iPhone 15 Pro Max (430 × 932)
  **Wenn:** View rendert
  **Dann:** Spacer skalieren proportional, Mond bleibt 220 pt; visuell entspannter Aufbau ohne riesige Leerflaechen.

### AK Accessibility

- **Gegeben:** Hauptphase laeuft
  **Wenn:** VoiceOver fokussiert auf den Restzeit-Block
  **Dann:** `accessibilityIdentifier = "timer.display.time"` auf der Zeit-Zeile, `accessibilityValue` liest die verbleibende Zeit ("X Minuten und Y Sekunden verbleibend"). Mond ist `accessibilityHidden(true)` — er ist Dekoration, keine Information.

- **Gegeben:** VoiceOver-Nutzer fokussiert auf Close-Button
  **Wenn:** Fokus liegt auf dem `xmark`-Button oben links
  **Dann:** Label `accessibility.endMeditation`, Hint `accessibility.endMeditation.hint` — unveraendert.

### AK Aufraeumen

- **Gegeben:** `VesselView.swift` wurde geloescht
  **Wenn:** `make test-unit` und Build laufen
  **Dann:** Alle Tests gruen, keine "type 'VesselView' has no member"-Fehler, kein toter Import. `grep -r VesselView` findet keine Treffer mehr.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Innen → aussen, Build bleibt bei jedem Commit gruen:

1. **`MoonPhaseView` neu anlegen** — mit `progress`, `reduceMotion`, `outerSize` als Parameter. Erstmal nur die drei Layer (Halo, Disc, Schatten) ohne Animation. Sechs `#Preview`-Faelle: Start/Halbzeit/Ende × Light + Dark.
   - Test ueber Preview: visueller Smoke gegen die Handoff-HTML.
   - Compilation: hardcoded Farben, ColorScheme-Switch, clip-mask greift.

2. **Animation einbauen** — `.animation(.linear(duration: 1.0), value: progress)` auf den Schatten-Offset (deaktiviert bei `reduceMotion`), `.animation(.easeInOut(duration: 1.0), value: progress)` auf den Halo-Alpha (smoothstep wird im computed value gemacht, nicht im Animation-Curve).
   - Preview "animierter Verlauf" (optional, falls SwiftUI-Preview es zulaesst): simuliert progress von 0 zu 1 ueber 10 s.

3. **`RunningTimerDisplay` refactorn** — vom HStack-Layout zum VStack-Layout. `MoonPhaseView` einbauen, Spacer-Verhaeltnisse so abstimmen, dass Mond im unteren Drittel sitzt. Bestehende Previews ("Running — Start (leer)", "Running — halb gefuellt", "Running — kompakt (SE)") an den neuen Look anpassen.
   - Aufruf in `TimerView.timerDisplay` bleibt unveraendert (Signatur-stabil).

4. **`VesselView.swift` loeschen** — Datei entfernen, sicherstellen dass kein Aufruf mehr existiert (`grep VesselView` leer).

5. **Manueller Smoke-Test im Simulator** — iPhone SE + iPhone 15 + iPhone 15 Pro Max, jeweils Light + Dark, jeweils mit und ohne Reduce Motion. Beobachten: Schatten wandert sanft, Halo waechst spaet, am Ende kein dunkler Rest.

6. **CHANGELOG.md** — Eintrag unter "Unreleased": Running-Timer-Visualisierung Mondphase ersetzt Sanduhr.

7. **Fastlane-Screenshots aktualisieren** — `make screenshots MODE=dark` und `MODE=light`. Die Running-Phase-Screenshots werden mit der neuen Visualisierung neu generiert.

---

## Vorbereitung

- shared-094 muss vor diesem Ticket gemerged sein (Voraussetzung).
- Keine neuen SPM-Pakete, keine Asset-Aenderungen, keine Provisioning-/Entitlement-Aenderungen.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Schatten-Drift bei sekundengenauen `progress`-Updates ruckelt sichtbar | `.animation(.linear(duration: 1.0))` glaettet die Bewegung. Bei Reduce-Motion ist der Sprung sichtbar — das ist die Akzeptanz-Anforderung, kein Bug. |
| Halo-Padding zu klein, weicher Halo wird abgeschnitten | `MoonPhaseView`-Container ist `outerSize × 1.6` pro Achse; Validierung gegen Handoff-Preview. |
| Auf iPhone SE rutscht der Zeit-Block in die Toolbar oder der Halo verschwindet hinter der Tabbar | Compact-Variante: Mond 180 pt, Spacer-Verhaeltnisse angepasst. Manueller Test auf SE Pflicht. |
| Light-Mode: Mond wirkt aufdringlich gegen den Sunrise-Hintergrund | Disc-Verlauf endet im tiefen Ocker `#9A6A42`; Schatten warm-dunkel statt Reinschwarz. Validierung gegen Handoff-Light-Preview im Browser. |
| Reduce-Motion deaktiviert irrtuemlich auch die Halo-Aktualisierung | Halo-Alpha wird ueber `value: progress` getriggert; bei Reduce-Motion kein `withAnimation`-Wrapper, aber der computed Wert aendert sich trotzdem sekuendlich. Diskreter Sprung, aber sichtbar. |
| Fastlane-Screenshots gehen rot wegen geaenderter Pixel | Im Anschluss neu generieren; das ist erwartetes Verhalten bei visuellen Aenderungen. |
| Clip-Maske auf ZStack hat Performance-Probleme | iOS rendert `Circle()`-Masken nativ effizient; bei 60 fps unkritisch. Bei Reduce-Motion sowieso nur 1 Hz. |

---

## Offene Fragen

- [ ] **Halo-Padding final festlegen.** Handoff sagt `width: 480px; height: 480px` Container um einen 220 px Mond — das ist Faktor 2.18. Bei `outerSize = 220` pt heisst das ein Container von ~480 pt, was iPhone SE (375 pt breit) sprengt. Empfehlung: Halo-Padding auf `outerSize × 0.6` cappen (Container = `outerSize × 1.6`); der Halo verliert dadurch minimal an aeusserer Weichheit, aber bleibt im Bildausschnitt. Visueller Vergleich gegen Handoff im Implementation-Schritt.
- [ ] **Disc-Hoehlung beim Endzustand.** Wenn `progress = 1.0`, ist der Schatten geometrisch komplett ausserhalb des Mond-Clips. Bei `progress` knapp unter 1.0 verbleibt ein hauchduenner Streifen. Akzeptanz-Anforderung "voller Mond am Ende, kein schwarzer Rest" ist erfuellt — aber die Strecke `0.9 → 1.0` (letzte 10 %) braucht visuelle Validierung, dass der Streifen nicht ploetzlich verschwindet, sondern weich nach links rauslaeuft. Sollte im Smoke-Test passen, da die linearen `cx`-Werte aus dem Handoff genau diesen "Rest raeumen"-Effekt liefern.

---

Bereit fuer `/implement-ticket shared-095` — sobald shared-094 gemerged ist und die zwei offenen Fragen im Implementation-Schritt visuell entschieden werden.

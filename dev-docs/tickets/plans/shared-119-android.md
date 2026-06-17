# Implementierungsplan shared-119 (Android): Vorbereitungszeit-Screen-Redesign

Redesign des Timer-Detail-Screens „Vorbereitungszeit" auf das gehobene Muster der
Schwester-Screens „Start & Ende" (shared-115) und „Intervall-Gongs" (shared-118):
Master-Schalter-Karte oben, darunter — nur wenn an — Eyebrow „DAUER", grosser Serif-Wert-Hero
und eine gerasterte Slider-Karte. Die diskrete Options-Liste mit Haekchen entfaellt.

---

## Annahmen

- **Scope ist nur der Timer-Pfad (`Praxis`).** Das Ticket nennt zwar „beide Domain-Modelle";
  auf Android sind die diskreten `VALID_PREPARATION_TIMES` aber in drei Modellen dupliziert:
  `Praxis` (Timer), `MeditationSettings` (Timer-Legacy/Reducer) und `GuidedMeditationSettings`
  (gefuehrte Meditationen, eigener Screen `GuidedMeditationSettingsSection`). Der Redesign-Screen
  bedient ausschliesslich `Praxis` (ueber `PraxisSettingsViewModel`). **Nur `Praxis` wird auf das
  5er-Raster 5–60 / Default 10 umgestellt.** `MeditationSettings` und `GuidedMeditationSettings`
  bleiben unveraendert — der iOS-Counterpart-Hinweis „MeditationSettings" entspricht auf Android
  `Praxis`. (Siehe Offene Frage 1 — falls der Reviewer Vereinheitlichung will, separat ziehen.)
- Save-on-Back und „gemerkte Dauer" sind bereits durch die Architektur abgedeckt: `NavGraph`
  ruft beim Zurueck `saveAndPop(...)` auf; `setPreparationEnabled(false)` flippt nur das Boolean
  und laesst `preparationTimeSeconds` unberuehrt → Wieder-Einschalten stellt die Dauer her. Kein
  zusaetzlicher Persistenz-Code noetig.
- Nur Nacht-Theme im Handoff aktiv; Umsetzung ueber semantische Tokens (`LocalStillMomentColors`,
  `TextStyle`, `MaterialTheme.colorScheme`), nicht ueber die CSS-Werte des Prototyps.
- Der bestehende Default `DEFAULT_PREPARATION_TIME_SECONDS = 15` wird auf `10` geaendert; bereits
  gespeicherte Werte (z.B. 45) bleiben gueltig (liegen im 5er-Raster) oder werden auf den
  naechsten 5er-Wert validiert.
- `material-icons-extended` ist als Dependency vorhanden (`libs.androidx.material.icons.extended`,
  1.7.6) → `Icons.Filled.HourglassEmpty` ist verfuegbar (kein neues Asset noetig).

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/Praxis.kt` | Domain | Aendern | `DEFAULT_PREPARATION_TIME_SECONDS` 15→10; `VALID_PREPARATION_TIMES` von `listOf(5,10,15,20,30,45)` auf 5er-Raster `(5..60 step 5).toList()`; `validatePreparationTime` auf den neuen Bereich/Raster anpassen (clamp + snap). KDoc-Kommentar zur `preparationTimeSeconds`-Property aktualisieren. |
| `presentation/ui/timer/PreparationTimeSelectionScreen.kt` | Presentation | Neu schreiben | Listen-Layout (`PreparationOptionsCard`/`PreparationOptionRow`) komplett ersetzen durch Master-Karte (Icon + Titel + Untertitel + Switch), Eyebrow „DAUER", Wert-Hero (Serif-Zahl + Einheit), Slider-Karte. Aufteilung in kleinere `@Composable`/`LazyListScope`-Funktionen (detekt). KDoc auf shared-119 aktualisieren. |
| `presentation/ui/timer/components/PreparationSliderCard.kt` | Presentation | Neu (optional) | Eigene gerasterte Slider-Karte mit End-Labels „5 Sek." / „1 Min." analog `GongVolumeCard`. Eigene Komponente, weil `GongVolumeCard` 0..1f ohne `steps`/End-Labels ist und nicht generisch genug zum Wiederverwenden (siehe Design-Entscheidungen). |
| `presentation/ui/timer/components/PreparationValueHero.kt` | Presentation | Neu (optional) | Wert-Hero: grosse Serif-Zahl (`TextStyle.display`, tabular-nums) + Einheit „Sekunden". Eigene Composable haelt `PreparationTimeSelectionScreen` unter detekt-LongMethod. |
| `res/values/strings.xml` + `res/values-de/strings.xml` | Resources | Aendern/Ergaenzen | Neue Keys (s. Lokalisierung unten); ungenutzt werdende Keys identifizieren (z.B. `accessibility_preparation_option`). |
| `app/src/test/.../domain/models/PraxisTest.kt` | Test | Aendern | `PreparationTimeValidation`-Nested-Class auf neues Raster/Default umschreiben; `VALID_PREPARATION_TIMES`-Erwartung anpassen; Default-Test (`preparationTimeSeconds == 10`). |
| `app/src/test/.../presentation/viewmodel/PraxisSettingsViewModelTest.kt` | Test | Aendern/Ergaenzen | Snap-Erwartung in `setPreparationSeconds snaps to nearest valid value` (12→10 bleibt gueltig); ggf. Test fuer „gemerkte Dauer" (enabled false→true behaelt seconds). |
| `CHANGELOG.md` | Doku | Ergaenzen | User-sichtbarer Eintrag (Redesign Vorbereitungszeit). |

**Nicht betroffen (bewusst):** `navigation/NavGraph.kt` (Route + saveAndPop bereits korrekt),
`PraxisSettingsViewModel` (Setter `setPreparationEnabled`/`setPreparationSeconds` bleiben unveraendert —
`setPreparationSeconds` delegiert an `Praxis.validatePreparationTime`, das mit dem neuen Raster automatisch korrekt snappt),
`MeditationSettings.kt`, `GuidedMeditationSettings.kt`.

---

## API-Recherche

Compose `Slider` mit Rasterung ist bekanntes API:
- `Slider(value, onValueChange, valueRange = 5f..60f, steps = 11, ...)`. Composes `steps` = Anzahl
  der diskreten Punkte **zwischen** den beiden Endpunkten. Werte 5,10,…,60 = **12 Stops** =
  2 Endpunkte + **11 Zwischenpunkte** → **`steps = 11`**. Compose rastet `value` automatisch auf
  diese Stops.
- Beim Lesen den Float auf Int runden (`value.roundToInt()`) und an den ViewModel geben; der
  Wert-Hero zeigt den Int. Bei aktivem `steps` liefert Compose bereits gerastete Floats, die
  `roundToInt()` exakt trifft.
- `colors = SliderDefaults.colors(thumbColor = colors.interactive, activeTrackColor = colors.interactive,
  inactiveTrackColor = colors.controlTrack)` wie in `GongVolumeCard`.

Material-Symbol `Icons.Filled.HourglassEmpty` (Sanduhr) ist in `material-icons-extended` 1.7.6
enthalten.

---

## Design-Entscheidungen

1. **Slider-Rasterung via `steps = 11`** (12 Stops 5..60). Kein manuelles Snapping im Composable;
   Compose erledigt es. Wert wird per `roundToInt()` zu Int und an `viewModel.setPreparationSeconds`
   gegeben. `Praxis.validatePreparationTime` ist die zweite (Domain-)Verteidigungslinie beim
   Speichern.
2. **Serif-Zahl-Token = `TextStyle.display`** (Newsreader Light, `baseSize 88.sp`). Das ist der
   einzige Serif-Numerik-Token (`Newsreader`, tabular-nums). Der Handoff nennt 72px; `display` ist
   container-relativ/gross gedacht (Timer-Countdown) — fuer den Hero genuegt `TextStyle.display`
   ggf. mit reduzierter Groesse ueber den Composable, ODER schlicht `display` uebernehmen
   (Dynamic-Type-treu). **Entscheidung:** `TextStyle.display` verwenden und Groesse nicht
   hart ueberschreiben (System-Konsistenz vor Pixel-Treue zum Prototyp); falls visuell zu gross,
   im Implement-Schritt via `toComposeTextStyle().copy(fontSize = ...)` justieren. Einheit „Sekunden"
   = `TextStyle.eyebrow` (tracked caps, `ink-3` → `onSurfaceVariant`), passend zum Handoff
   (uppercase, letter-spacing).
3. **Master-Karte als neue lokale `PreparationMasterCard`-Composable** (privat im Screen),
   analog `IntervalToggleRow`, aber mit fuehrendem Icon-Kreis (40dp, `surface-2`-Fuellung,
   1dp Border, Glyph in `accent`/`interactive`) + zweizeiligem Mitteltext (Titel `TextStyle.body`
   in `textPrimary`, Untertitel `TextStyle.caption` in `onSurfaceVariant`) + `Switch` rechts mit
   `stillMomentSwitchColors()`. Der Untertitel-String wechselt nach `enabled` (AN/AUS-Text).
4. **Wiederverwendung:** `GongCard` (Karten-Hintergrund 22dp + Border), `EyebrowLabel`,
   `WarmGradientBackground`, `StillMomentTopAppBar`, `stillMomentSwitchColors()`,
   `TextStyle`/`toComposeTextStyle`. Master-Karte und Slider-Karte werden **nicht** aus den
   Gong-Screens wiederverwendet, da deren Master-Toggle keinen Icon-Kreis hat und `GongVolumeCard`
   einen 0..1f-Slider ohne `steps`/End-Labels ist — neue, zugeschnittene Composables sind
   einfacher als generische Parametrisierung (Simplest-Solution-First).
5. **detekt-Aufteilung:** `PreparationContent` als `@Composable` mit `LazyColumn`; darin
   `item`-Bloecke fuer Master-Karte, Eyebrow+Hero, Slider-Karte bzw. Helper-Text. Jede
   Teil-Composable klein halten (LongMethod 60 Zeilen). Mehrere Top-Level-Emitter (Hero =
   `Text` Zahl + `Text` Einheit) in `Column{}` wrappen (MultipleEmitters).
6. **Accessibility:** Switch mit `contentDescription` (Vorbereitungszeit-Schalter, vorhandener Key
   `accessibility_praxis_editor_preparation_toggle`) + `stateDescription` (`common_on`/`common_off`),
   wie `IntervalToggleRow`. Slider mit `contentDescription` „Vorbereitungsdauer, N Sekunden"
   (vorhandener Key `accessibility_praxis_editor_preparation_duration` + Wert).

---

## Refactorings

- **Domain-Konstante zentralisieren:** Statt `listOf(5,10,15,20,30,45)` neu hart als
  `(5..60 step 5).toList()` schreiben. Optional zusaetzlich `MIN_PREPARATION_SECONDS = 5`,
  `MAX_PREPARATION_SECONDS = 60`, `PREPARATION_STEP_SECONDS = 5` als Konstanten, damit Slider
  (`valueRange`/`steps`) und Domain dieselbe Quelle teilen und nicht auseinanderdriften.
- **Keine** Aenderung an `setPreparationSeconds`/`setPreparationEnabled` noetig (delegieren bereits
  korrekt). Kein Refactoring an `NavGraph`/`saveAndPop`.
- Ungenutzte String-Keys nach dem Umbau pruefen und entfernen (z.B. `accessibility_preparation_option`
  „%d seconds preparation" war fuer die Listen-Zeilen; nach Wegfall der Liste ggf. obsolet —
  vor Loeschen per Grep verifizieren, andere Screens koennten ihn teilen).

---

## Fachliche Szenarien

1. **Default-Dauer**
   - Gegeben: eine frische `Praxis` (Werks-Defaults).
   - Wenn: die Vorbereitungszeit gelesen wird.
   - Dann: `preparationTimeEnabled == true` und `preparationTimeSeconds == 10`.

2. **Gueltiger Wertebereich (5er-Raster)**
   - Gegeben: das Raster der gueltigen Vorbereitungszeiten.
   - Wenn: es abgefragt wird.
   - Dann: es ist genau `5,10,15,20,25,30,35,40,45,50,55,60`.

3. **Validierung snapt auf naechsten 5er-Wert**
   - Gegeben: ein Roh-Wert von 12 (bzw. 13).
   - Wenn: validiert wird.
   - Dann: Ergebnis ist 10 (bzw. 15).

4. **Validierung clampt ausserhalb des Bereichs**
   - Gegeben: ein Roh-Wert von 3 bzw. 80.
   - Wenn: validiert wird.
   - Dann: Ergebnis ist 5 bzw. 60.

5. **Exakte Werte bleiben erhalten**
   - Gegeben: ein Wert von 25 (neu im Raster, vorher nicht in der Liste).
   - Wenn: validiert wird.
   - Dann: Ergebnis ist 25 (unveraendert).

6. **Gemerkte Dauer beim Aus/Wieder-An**
   - Gegeben: Vorbereitungszeit an, gewaehlte Dauer 35.
   - Wenn: der Schalter aus- und wieder eingeschaltet wird.
   - Dann: `preparationTimeSeconds` ist weiterhin 35 (kein Reset auf 10).

7. **Slider aktualisiert Dauer (UI)**
   - Gegeben: der Screen mit eingeschalteter Vorbereitungszeit.
   - Wenn: der Slider auf einen anderen 5er-Stop gezogen wird.
   - Dann: der Wert-Hero zeigt die neue Sekundenzahl, und der ViewModel-State traegt sie.

8. **Aus-Zustand zeigt Helper statt Auswahl (UI)**
   - Gegeben: der Screen.
   - Wenn: der Schalter ausgeschaltet wird.
   - Dann: Eyebrow „DAUER", Wert-Hero und Slider-Karte verschwinden, der einladende Hilfetext erscheint.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **AK „Default 10 / Raster 5–60"** (Domain, reines TDD).
   - RED: `PraxisTest` — Default `preparationTimeSeconds == 10`, `VALID_PREPARATION_TIMES`-Liste,
     Snap- und Clamp-Tests (Szenarien 1–5) auf neuen Bereich umschreiben → schlagen fehl.
   - GREEN: `Praxis.kt` (Default, Liste, optional Min/Max/Step-Konstanten) anpassen.
   - REFACTOR: `validatePreparationTime` ggf. ueber `coerceIn` + `step`-Rundung statt
     `minByOrNull{abs}` (gleiches Ergebnis, klarer).

2. **AK „gemerkte Dauer"** (ViewModel, TDD).
   - RED: `PraxisSettingsViewModelTest` — enabled false→true behaelt seconds; `setPreparationSeconds`
     snapt korrekt (Szenario 6 + 3).
   - GREEN: bereits erfuellt durch bestehende Setter — Test bestaetigt Verhalten; nur falls
     Snap-Erwartung sich aendert, Test anpassen.

3. **AK „Master-Karte + Untertitel"** (UI). Master-Karte mit Sanduhr-Icon, Titel, AN/AUS-Untertitel,
   Switch. (Manuell/visuell verifiziert; ggf. leichtgewichtiger Compose-UI-Test fuer testTag
   `preparation.toggle`.)

4. **AK „Eyebrow + Wert-Hero + Slider-Karte bei AN"** (UI). Eyebrow „DAUER", Serif-Hero, gerasterter
   Slider mit End-Labels; Hero aktualisiert live (Szenario 7).

5. **AK „Helper bei AUS"** (UI). Hilfetext statt Auswahl (Szenario 8).

6. **AK „Lokalisiert DE+EN"**. Neue Keys in beiden `strings.xml`; obsolet werdende Keys pruefen.

7. **AK „Cross-Platform-Konsistenz"**. Gegen iOS-Plan/-Umsetzung abgleichen (gleiche Texte, gleiches
   Verhalten, gleicher Wertebereich/Default).

8. **Doku**: CHANGELOG-Eintrag.

9. **Quality Gate**: `make -C android check` + `make -C android test-unit-agent` (Subagent), dann Commit.

---

## Lokalisierung — Keys

**Vorhanden, wiederverwendbar:**
- `settings_preparation_time_title` („Vorbereitung" / „Vorbereitung") — Screen-Titel.
  Hinweis: Handoff-Titel ist „Vorbereitungszeit" (Serif). Pruefen, ob Titel auf „Vorbereitungszeit"
  angehoben werden soll (DE) — siehe Offene Frage 2.
- `settings_preparation_time` („Preparation Time"/„Vorbereitungszeit") — Master-Karten-Titel.
- `common_on` / `common_off` — Switch-StateDescription.
- `accessibility_praxis_editor_preparation_toggle` — Switch contentDescription.
- `accessibility_praxis_editor_preparation_duration` — Slider contentDescription (Basis; ggf. mit
  Wert formatieren → neuen `%d`-Key oder vorhandenen `accessibility_preparation_enabled`
  „…, %d Sekunden" nutzen).
- `time_seconds` („%d seconds"/„%d Sekunden") — falls fuer Hero/AccessibilityWert gebraucht.

**Neu anzulegen (DE + EN):**
- `preparation_master_subtitle_on` — „Eine kurze Stille vor dem Start" / „A brief stillness before you begin".
- `preparation_master_subtitle_off` — „Aus — der Timer startet sofort" / „Off — the timer starts immediately".
- `preparation_duration_eyebrow` — „DAUER" / „DURATION" (oder vorhandenen `settings_preparation_duration`
  „Dauer"/„Duration" nutzen; Eyebrow uppercased den String selbst via `TextStyle.eyebrow.applyCase`).
- `preparation_unit_seconds` — „Sekunden" / „Seconds" (Hero-Einheit; eigener Key, da `time_seconds`
  eine Zahl erwartet).
- `preparation_slider_min_label` — „5 Sek." / „5 sec".
- `preparation_slider_max_label` — „1 Min." / „1 min".
- `preparation_off_helper` — „Schalte die Vorbereitungszeit ein, um vor dem Start kurz innezuhalten
  und anzukommen." / EN-Pendant.

(Exakte Wortlaute mit iOS abstimmen, damit beide Plattformen identisch sind.)

---

## Offene Fragen

1. **Scope der Domain-Aenderung:** Nur `Praxis` umstellen (mein Plan) oder auch `MeditationSettings`
   und `GuidedMeditationSettings`? Letztere bedienen andere Screens (Reducer/gefuehrte Meditation),
   die dieses Redesign nicht beruehrt. Empfehlung: nur `Praxis`; Vereinheitlichung separat. Bitte
   bestaetigen, da das Ticket „beide Domain-Modelle" sagt (gemeint ist vermutlich iOS+Android, nicht
   Praxis+MeditationSettings).
2. **Screen-Titel:** Aktueller DE-Titel ist „Vorbereitung" (`settings_preparation_time_title`),
   der Handoff zeigt „Vorbereitungszeit". Titel anheben oder belassen? (Cross-Platform mit iOS abstimmen.)
3. **Hero-Schriftgroesse:** `TextStyle.display` (88sp Basis) vs. Prototyp 72px. Token-treu lassen
   oder Groesse justieren? Empfehlung: Token verwenden, im Implement visuell pruefen.

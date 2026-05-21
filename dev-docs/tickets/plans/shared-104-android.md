# Implementierungsplan: shared-104 (Android)

Ticket: [shared-104 — Import-Anleitungen im Content Guide (Android-Sync)](../shared/shared-104-import-anleitungen-android.md)
Erstellt: 2026-05-21
Branch (Vorschlag): `feature/shared-104-android`

iOS-Pendant: [shared-039b](../shared/shared-039b-import-anleitungen.md) — DONE.
iOS-Referenzdateien:
- `ios/StillMoment/Presentation/Views/GuidedMeditations/ContentGuideSheet.swift` (Banner-Sektion + `ImportBannerCard`)
- `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportBrowserView.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportFilesView.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportStepCard.swift`

---

## Kernidee

Reine UI-Erweiterung im `ContentGuideSheet`. Zwei Banner direkt unter dem Intro, jeder pusht eine dreistufige How-To-Ansicht. Auf iOS funktioniert das ueber den `NavigationStack`, der das Sheet umgibt; Android-`ModalBottomSheet` hat keinen NavigationStack. Loesung: **State-basierter Switch innerhalb des Sheet-Contents** via `AnimatedContent` mit horizontalem Slide. Das Sheet selbst bleibt offen; nur sein Inhalt animiert zwischen „Liste" und „Detail". `BackHandler` faengt die System-Back-Geste im Detail-Modus und resetet den Switch — fuehlt sich wie iOS-Push/Pop an.

Drag-down auf den Sheet-Grabber schliesst weiterhin das ganze Sheet (analog iOS, akzeptierter Trade-off aus shared-039b).

Texte und Layout werden 1:1 von iOS portiert. Theme-Tokens (`accentBannerBackground`, `accentBannerBorder`, `accentBubbleBackground`) sind seit shared-094 schon im Android-Theme vorhanden und bisher ungenutzt — dieses Ticket ist der erste Konsument.

---

## Annahmen

- **Sub-Navigation: State-basiert.** Innerhalb des `ContentGuideSheet` wird ein neuer interner State (`var detail by remember { mutableStateOf<GuideDetail?>(null) }`) zwischen Listenansicht und einer der beiden Anleitungen umgeschaltet. Begruendung: am nahesten am iOS-Push-Verhalten, keine Sheet-on-Sheet-Komplikation, keine Vollscreen-Route noetig. Sheet-on-Sheet wuerde mit zwei Drag-Indicators „doppelt-stacked" aussehen; Vollscreen-Route wuerde das „im Sheet bleiben"-Gefuehl brechen.
- **Browser-Flow funktioniert auf Android.** Manifest hat bereits `intent-filter` fuer `ACTION_SEND` + `text/plain` (eingefuehrt mit shared-091 fuer URL-Share). Der Flow „Long-press Link → Teilen → Still Moment" landet als URL-String in `MainActivity` und triggert die bestehende URL-Download-Pipeline. Die Anleitungstexte koennen den iOS-Wortlaut behalten — der Download im Hintergrund ist fuer den User unsichtbar. Geprueft via `AndroidManifest.xml:54–58` und `FileOpenHandler.kt` (URL-Pfad).
- **Theme-Tokens existieren bereits.** `Theme.kt:74–81` definiert `accentBannerBackground` / `accentBannerBorder` / `accentBubbleBackground` mit den iOS-aequivalenten Alphas (0.10 / 0.28 / 0.18) auf `interactive`. Kein Token-Add noetig.
- **`material-icons-extended` ist auf dem Classpath** (`libs.versions.toml:43`). Alle Mapping-Kandidaten sind verfuegbar.
- **Step-Count via `stringResource(R.string.x, stepNumber)`** mit Format-String `"Schritt %d von 3"` / `"Step %d of 3"` — analog zu bestehenden Pluralisierungen im Projekt (siehe `accessibility_dial_value`).
- **Keine MVI-Aenderungen.** Banner-Tap und Detail-Navigation sind reine UI-States im Composable, nicht im ViewModel — analog dazu, wie die Sheet-Sichtbarkeit selbst (`uiState.showGuideSheet`) auf ViewModel-Ebene bleibt, der Detail-Switch aber lokal ist. Keine Tracking-Events, kein Logging.

---

## Icon-Mapping (SF Symbol → Material Icons)

| Verwendung | SF Symbol (iOS) | Material Icon (Android) |
|------------|-----------------|-------------------------|
| Banner Browser (Bubble) | `safari` | `Icons.Default.Public` |
| Banner Files (Bubble) | `folder` | `Icons.Default.Folder` |
| Banner Chevron | `chevron.right` | `Icons.AutoMirrored.Filled.KeyboardArrowRight` |
| Step1 Browser (Share) | `square.and.arrow.up` | `Icons.Default.Share` |
| Step2 Browser (App) | `flame` | `Icons.Default.LocalFireDepartment` |
| Step3 Browser/Files (Done) | `checkmark.circle` | `Icons.Outlined.CheckCircle` |
| Step1 Files (+) | `plus` | `Icons.Default.Add` |
| Step2 Files (Datei) | `doc.fill` | `Icons.AutoMirrored.Outlined.InsertDriveFile` (bereits in `MeditationEditSheet.kt` verwendet) |

`LocalFireDepartment` ist die naechste Material-Entsprechung zu `flame`. Alternative waere die App-Launcher-Icon-Darstellung, ist aber als `ImageVector` umstaendlich. Visuell identisches Familienkonzept (Flamme = Waerme = Still Moment).

---

## Betroffene Codestellen

### Neue Dateien

| Datei | Layer | Beschreibung |
|-------|-------|--------------|
| `presentation/ui/meditations/ImportBannerCard.kt` | Presentation | Banner-Karte: Icon-Bubble (links), Titel + Untertitel (mittig), Chevron rechts. `accentBannerBackground` + `accentBannerBorder`-Border. `Modifier.clickable(role = Role.Button)`. Accessibility: kombiniert Titel + Untertitel als `contentDescription`. |
| `presentation/ui/meditations/HowToImportStepCard.kt` | Presentation | Numbered Step-Card: Badge (Zahl in `accentBubbleBackground`-Kreis), Icon + Titel-Zeile, Body-Text. Plus `HowToImportStepConnector`-Composable (1-dp vertikaler Strich zwischen Badges, linksbuendig). Accessibility-Label: `"Schritt N von 3, <title>, <body>"` (formatiert via `R.string.guided_meditations_guide_howto_step_count`). |
| `presentation/ui/meditations/HowToImportGuideScreen.kt` | Presentation | Parametrisierte Detail-Ansicht. Nimmt ein `HowToImportGuideKind { BROWSER, FILES }` (oder eine `data class HowToImportGuide` mit Titel-Key, Intro-Key und Liste von Step-Specs) und rendert Eyebrow + Titel + Intro + drei `HowToImportStepCard`s mit Konnektoren. Vermeidet zwei fast identische Composables. |

### Geaenderte Dateien

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/meditations/ContentGuideSheet.kt` | Presentation | Erweitern | (a) `ContentGuideSheetContent` umbauen: lokaler State `var activeGuide by remember { mutableStateOf<HowToImportGuideKind?>(null) }`. (b) `AnimatedContent`-Switch zwischen `GuideListContent` (Title + Intro + zwei Banner + SourceCard) und `HowToImportGuideScreen(activeGuide)`. (c) `BackHandler(enabled = activeGuide != null)` setzt `activeGuide = null`. (d) Im Detail-Modus oben links zusaetzlich ein kleiner Back-Icon-Button (`Icons.AutoMirrored.Filled.ArrowBack`) — sichtbarer Rueckweg fuer Nutzer, die nicht die System-Back-Geste kennen. (e) `GuideListContent` extrahieren als private Composable, damit der Switch-Block lesbar bleibt. |
| `res/values/strings.xml` | Resources | Neue Keys | `guided_meditations_guide_banner_browser_title/subtitle` + `_files_title/subtitle`. `guided_meditations_guide_howto_eyebrow`, `_step_count` (Format `"Step %d of 3"`). Browser- und Files-Anleitung: je `_title`, `_intro`, `_stepN_title`, `_stepN_body` (N = 1..3). Insgesamt ~22 neue Keys. Texte exakt aus den iOS-Localizable-Strings uebernehmen. |
| `res/values-de/strings.xml` | Resources | Neue Keys | Deutsche Uebersetzungen, ebenfalls 1:1 aus iOS-DE (`guided_meditations.guide.banner.*` / `guided_meditations.guide.howto.*`). |

### Tests

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `presentation/ui/meditations/ContentGuideSheetTest.kt` (Compose-UI-Test, falls im Projekt vorhanden — sonst neu) | **Neu** | Drei Tests: (1) Banner sichtbar im List-Modus. (2) Browser-Banner-Tap → Browser-Detail sichtbar, Liste verborgen. (3) System-Back im Detail-Modus → zurueck zur Liste. Files-Banner-Pfad ist symmetrisch — als Parametrized Test oder zweiten Block ergaenzen. Headless mit `composeTestRule`. |

Bestaetigung: im aktuellen Projekt existiert noch kein `ContentGuideSheetTest.kt`. Es existieren `GuidedMeditationsListViewModelTest.kt` etc., aber keine reinen Composable-UI-Tests fuer das Guide-Sheet — die Tests werden neu erstellt.

---

## Design-Entscheidungen

### 1. State-basierte Sub-Navigation statt Sheet-on-Sheet oder Vollscreen-Route

**Trade-off:**
- *Sheet-on-Sheet* (zweites `ModalBottomSheet`): Doppelter Drag-Indicator, gestackter Look, Animation springt. Im Compose-Material-3 nicht ergonomisch.
- *Vollscreen-Route*: Sheet schliessen, neue Compose-Destination pushen. Macht den „Im Sheet bleiben"-Eindruck kaputt; Back-Navigation muesste das Sheet wieder oeffnen — fehleranfaellig.
- *State-basiert mit `AnimatedContent`*: Sheet bleibt offen, Inhalt animiert horizontal hin und zurueck. Naehe zu iOS-Push am besten.

**Entscheidung:** State-basiert. Animation: `slideInHorizontally` von rechts beim Push, `slideOutHorizontally` nach rechts beim Pop. Konsistent mit bestehender Verwendung von `AnimatedContent` im Projekt (`LibraryHeaderBar.kt:86`, `TimerFocusScreen.kt:357`).

### 2. Ein parametrisiertes `HowToImportGuideScreen` statt zwei separate Composables

iOS hat zwei getrennte Views (`HowToImportBrowserView`, `HowToImportFilesView`) — aus historischen SwiftUI-Gruenden (NavigationLink-Target sind eigene Views). Auf Android existiert dieser Zwang nicht.

**Trade-off:**
- *Zwei Composables*: 1:1 zu iOS, leichter zu lesen, aber ~80 % Code-Duplikat.
- *Eine parametrisierte Composable*: Mehr Konzentration, einfacher zu pflegen, Title/Intro/Steps kommen aus einer Daten-Spec.

**Entscheidung:** Eine Composable mit `HowToImportGuideKind`-Enum-Parameter. Pro Kind eine private Konstante mit Titel-Key, Intro-Key und Step-Specs (Liste von `StepSpec(icon, titleKey, bodyKey)`). Vermeidet detekt-`LongMethod`/`Duplication`-Warnungen und passt zu der „Reducer-style"-Praxis des Projekts.

### 3. Sichtbarer Back-Button zusaetzlich zur System-Back-Geste

iOS hat den nativen Chevron-Left im NavigationBar. Auf Android ist die System-Back-Geste der Standard, aber nicht alle Nutzer kennen sie zuverlaessig (Gesten-Navigation vs. 3-Button-Nav). Ohne sichtbaren Back-Button koennten User im Detail-Modus „verloren" sein.

**Entscheidung:** Im Detail-Modus oben links einen kleinen Icon-Button (`Icons.AutoMirrored.Filled.ArrowBack`, 24 dp, `theme.textSecondary`). Plus `BackHandler` fuer die Geste. Beides geht auf `activeGuide = null`.

---

## Refactorings

Keine echten Refactorings. `ContentGuideSheetContent` wird erweitert; um den Lesefluss zu halten, wird die Listen-Sektion in eine private `GuideListContent`-Composable extrahiert. Das ist Kosmetik, keine Architektur-Aenderung — und vermeidet eine `LongMethod`-Warnung von detekt.

---

## Fachliche Szenarien

### AK-1: Banner sichtbar im Quellen-Sheet

- **Gegeben:** Bibliothek hat mindestens eine Meditation; User tippt auf das Info-Icon im Header.
  **Wenn:** Das `ContentGuideSheet` oeffnet.
  **Dann:** Direkt unter dem Intro-Text sind zwei Banner sichtbar — oben „So importierst du aus dem Browser" mit `Public`-Icon-Bubble, darunter „So importierst du aus deinen Dateien" mit `Folder`-Icon-Bubble. Beide zeigen rechts den Chevron. Darunter folgt die Quellenliste unveraendert.

### AK-2: Browser-Banner navigiert zur Browser-Anleitung

- **Gegeben:** Sheet ist offen, Listenansicht aktiv.
  **Wenn:** User tippt den Browser-Banner an.
  **Dann:** Der Sheet-Inhalt animiert horizontal nach links; rechts erscheint die Browser-Anleitung mit Eyebrow „Anleitung", Titel „So importierst du aus dem Browser", Intro-Text und den drei Schritt-Karten. Die Quellenliste ist nicht mehr sichtbar.

- **Gegeben:** User ist in der Browser-Anleitung.
  **Wenn:** User tippt den Back-Icon oben links oder triggert die System-Back-Geste.
  **Dann:** Sheet-Inhalt animiert zurueck; die Quellenliste mit Banner ist wieder sichtbar. Das Sheet selbst bleibt offen.

### AK-3: Files-Banner navigiert zur Files-Anleitung

- **Gegeben:** Sheet ist offen, Listenansicht aktiv.
  **Wenn:** User tippt den Files-Banner an.
  **Dann:** Der Sheet-Inhalt animiert nach links; rechts erscheint die Files-Anleitung mit Titel „So importierst du aus deinen Dateien" und Schritten „„+" in der Bibliothek tippen", „Aufnahme waehlen", „Fertigstellen".

### AK-4: Schritt-Karten sind korrekt aufgebaut

- **Gegeben:** Eine der beiden Anleitungen ist sichtbar.
  **Wenn:** Der User schaut sich die drei Schritt-Karten an.
  **Dann:** Jede Karte zeigt links eine Nummer-Badge (1/2/3) auf `accentBubbleBackground`-Kreis; rechts daneben Icon + Titel-Zeile, darunter den Body-Text. Zwischen Karte 1↔2 und 2↔3 ist eine duenne vertikale Verbindungslinie sichtbar (linksbuendig am Badge-Zentrum).

### AK-5: Texte sind lokalisiert

- **Gegeben:** Geraet-Locale ist Deutsch.
  **Wenn:** User oeffnet die Browser-Anleitung.
  **Dann:** Titel „So importierst du aus dem Browser", Eyebrow „Anleitung", Schritt-Titel und -Bodies in deutsch. Bei Locale-Wechsel auf Englisch sind alle Texte englisch — die Keys aus `strings.xml` aufgeloest.

### AK-6: Drag-down schliesst das ganze Sheet

- **Gegeben:** User ist in einer der Anleitungen.
  **Wenn:** User zieht den Sheet-Grabber nach unten.
  **Dann:** Das ganze Sheet schliesst (akzeptierter Trade-off — Back-Button und Swipe-back sind die expliziten Rueckwege; Drag-down ist immer ein „Sheet zu").

### AK-7: Accessibility (TalkBack)

- **Gegeben:** TalkBack ist aktiv, User fokussiert die erste Schritt-Karte einer Anleitung.
  **Wenn:** TalkBack liest die Karte vor.
  **Dann:** Ansage „Schritt 1 von 3, <Titel>, <Body>" (alles in einem Element zusammengefasst, kein Vorlesen der Verbindungslinie).

- **Gegeben:** TalkBack ist aktiv, User fokussiert einen Banner.
  **Wenn:** TalkBack liest ihn vor.
  **Dann:** Ansage „<Titel>, <Untertitel>", angekuendigt als Button.

### AK-8: Theme-Konsistenz

- **Gegeben:** User wechselt das Geraet zwischen Light- und Dark-Mode.
  **Wenn:** Das Sheet ist offen und/oder die Anleitung sichtbar.
  **Dann:** Banner-Hintergrund und Step-Badge-Hintergrund nutzen `accentBannerBackground` bzw. `accentBubbleBackground`, die ueber `interactive` mit Alpha definiert sind — Farbe passt in beiden Modi zum aktuellen Theme. Border-Linien und Schritt-Konnektoren sind in Light/Dark sichtbar (`cardBorder`).

---

## Reihenfolge der Akzeptanzkriterien

Empfohlene TDD-Reihenfolge:

1. **AK-5 (Lokalisierung)** — Strings zuerst, sonst kann Compose nicht resolved werden. Beide Sprachdateien zusammen committen.
2. **AK-4 (Step-Card)** — `HowToImportStepCard` + Connector als reine UI-Composables. Compose-Preview-Verifikation reicht.
3. **AK-2/AK-3 Detail-Inhalt** — `HowToImportGuideScreen` parametrisiert. Browser- und Files-Specs als private Konstanten.
4. **AK-1 (Banner)** — `ImportBannerCard`-Composable + Einbettung in `ContentGuideSheetContent` (noch ohne Sub-Navigation, Banner-Tap ist Stub).
5. **AK-2/AK-3 Navigation** — State + `AnimatedContent` + `BackHandler` + sichtbarer Back-Button. Verdrahtet Banner mit Detail.
6. **AK-7 (Accessibility)** — Labels und Step-Count-Vorlesen explizit pruefen, eventuelle Korrekturen.
7. **AK-8 (Theme)** — manueller Check in Light/Dark. Kein Code-Aufwand, wenn Tokens richtig benutzt.
8. **AK-6 (Drag-down)** — bestaetigen, dass das default `ModalBottomSheet`-Verhalten unveraendert ist. Kein Code.
9. **Compose-UI-Tests** — schreiben am Schluss (3 Tests, siehe Tests-Tabelle).

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| `BackHandler` im Sheet kollidiert mit der Sheet-Default-Dismiss-Geste, sodass System-Back das ganze Sheet schliesst statt nur das Detail. | `BackHandler(enabled = activeGuide != null)` — nur aktiv im Detail-Modus. Im List-Modus laeuft Back wie zuvor (schliesst das Sheet via `onDismiss`). Manuell pruefen. |
| `AnimatedContent` mit Inhalt unterschiedlicher Hoehe (Listenansicht vs. Detail) kann Layout-Jumps verursachen — Sheet-Hoehe waechst oder schrumpft. | `ModalBottomSheet` mit `skipPartiallyExpanded = true` (bereits gesetzt) hat dynamische Hoehe. Wenn Sprung stoert: feste `Modifier.heightIn(min = X.dp)` auf den `AnimatedContent`-Container. Beim ersten Smoke-Test pruefen. |
| `LocalFireDepartment` wirkt visuell zu „aggressiv" fuer einen Meditationskontext. | Im manuellen Test pruefen. Fallback: `Icons.Default.AutoAwesome` (Sparkles) oder `Icons.Default.Flare`. Entscheidung beim Verify-Schritt, nicht jetzt. |
| Compose-UI-Test fuer `ModalBottomSheet` ist mit `composeTestRule` flaky, weil das Sheet asynchron animiert. | Falls flaky: Test gegen `ContentGuideSheetContent` direkt (ohne `ModalBottomSheet`-Wrapper), das ist ein reines Composable und deterministisch. Pattern aus `MeditationEditSheet`-Tests uebernehmbar. |

---

## Vorbereitung

- Branch erstellen: `git checkout -b feature/shared-104-android`.
- Aktuelle Arbeit auf `feature/shared-103-android` ist work-in-progress (siehe `git status` vor Branch-Wechsel) — vorher stashen oder committen.

---

## Offene Fragen

Keine. Alle drei urspruenglichen Hinweise aus dem Ticket sind in den Annahmen aufgeloest:

- Sub-Navigation → State-basiert mit `AnimatedContent` + `BackHandler`.
- Android-Share-Flow → existiert ueber `text/plain`-SEND-Intent-Filter, Schritt-Texte 1:1 uebernehmbar.
- Icon-Mapping → siehe Tabelle, `LocalFireDepartment` als Fallback fuer `flame`, manueller Verify am Ende.

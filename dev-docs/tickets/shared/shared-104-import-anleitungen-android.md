# Ticket shared-104: Import-Anleitungen im Content Guide (Android-Sync)

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: UI-only. Banner-Karten und zwei Anleitungs-Screens werden 1:1 vom iOS-Pendant (`shared-039b`) uebernommen. Die einzige nicht-triviale Frage ist, wie die Sub-Screens aus dem `ModalBottomSheet` heraus erreicht werden — Compose Material 3 hat keinen eingebauten NavigationStack im Sheet. Risiko liegt darin, dass die gewaehlte Navigationsform sich beim Drag-down-Verhalten und der Back-Geste sauber anfuehlt.
**Phase**: 4-Polish

---

## Was

Erweitert das bestehende Android-`ContentGuideSheet` analog zu iOS um zwei Banner-Karten direkt unter dem Intro: eine Anleitung zum Importieren aus dem Browser (Share-Sheet → Still Moment), eine zweite zum Importieren aus den Dateien (`+` → Datei waehlen). Jeder Banner-Tap oeffnet eine dreistufige Schritt-fuer-Schritt-Anleitung. Layout, Copy und Theme-Tokens kommen 1:1 vom iOS-Pendant `shared-039b`.

## Warum

Neue Nutzer kennen die App-internen Import-Wege nicht. Sie sehen den Quellen-Sheet, finden eine Meditation — und wissen oft nicht, wie sie diese Datei zu Still Moment bekommen. Auf iOS wurde diese Luecke mit `shared-039b` geschlossen; auf Android fehlt sie noch. Der Content-Guide-Flow bricht hier heute genauso ab wie frueher auf iOS, mit derselben Folge: User springen ab, statt zu importieren.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `shared-039b` |
| Android   | [ ]    | Dieses Ticket |

---

## Akzeptanzkriterien

### Quellen-Sheet (Erweiterung des ContentGuideSheet)

- [ ] Zwei Banner-Karten erscheinen direkt unter dem Intro, oberhalb der Quellen-Sektion
- [ ] Browser-Banner steht oben, Datei-Banner darunter
- [ ] Jedes Banner zeigt eine Icon-Bubble links, Titel + Untertitel mittig, Chevron-Right rechts
- [ ] Tap auf einen Banner oeffnet die jeweilige Anleitung
- [ ] Bestehender Header, Intro, Quellenliste und Close-Verhalten unveraendert

### Browser-Anleitung

- [ ] Sub-Screen zeigt Eyebrow „Anleitung", Titel „So importierst du aus dem Browser" und einen sichtbaren Zurueck-Weg (Back-Button oder Swipe-Geste)
- [ ] Drei nummerierte Schritte mit vertikaler Verbindungslinie zwischen den Badges:
  1. „Im Browser teilen" — lange auf Link tippen, „Teilen" waehlen
  2. „Still Moment auswaehlen" — App aus dem Share-Sheet
  3. „In der App fertigstellen" — Edit-Sheet ausfuellen
- [ ] Zurueckweg fuehrt zurueck zur Quellenliste; das Sheet bleibt erhalten
- [ ] Kein zusaetzlicher Footer-CTA

### Datei-Anleitung

- [ ] Identische Struktur wie Browser-Anleitung
- [ ] Titel: „So importierst du aus deinen Dateien"
- [ ] Drei Schritte: „„+" in der Bibliothek tippen", „Aufnahme waehlen", „Fertigstellen"

### Lokalisierung

- [ ] Alle neuen Strings als `strings.xml`-Keys (DE + EN), keine hartcodierten Texte
- [ ] Texte stimmen wortgleich mit den iOS-Localizable-Strings (`guided_meditations.guide.howto.*`) ueberein

### Privacy

- [ ] Kein Logging fuer Banner-Taps oder Sheet-Oeffnungen, keine Tracking-Events

### Theme & Quality

- [ ] Funktioniert in Light- und Dark-Mode des aktuellen Themes
- [ ] Banner-Hintergrund und Border kommen aus semantischen Theme-Tokens (analog `accentBannerBackground`/`accentBannerBorder` auf iOS), keine direkten Hex-Werte oder Opacity-Aufrufe im Composable
- [ ] Banner-Karten sind als Button semantisch gekennzeichnet, Zurueck-Aktion hat `contentDescription`, Schritt-Nummern werden TalkBack-vorgelesen („Schritt 1 von 3")

### Tests

- [ ] UI-Test: Beide Banner sichtbar im Quellen-Sheet
- [ ] UI-Test: Browser-Banner-Tap navigiert zur Browser-Anleitung; Zurueck-Weg kehrt zur Quellenliste zurueck
- [ ] UI-Test: Files-Banner-Tap navigiert zur Files-Anleitung; Zurueck-Weg kehrt zur Quellenliste zurueck

### Dokumentation

- [ ] CHANGELOG.md aktualisiert

---

## Manueller Test

1. Library oeffnen, Info-Icon antippen → Quellen-Sheet erscheint
2. Beide Banner sichtbar oberhalb der Quellen
3. Browser-Banner antippen → Browser-Anleitung erscheint
4. Drei Schritte sichtbar, Verbindungslinie zwischen Badges
5. Zurueck (Button oder Swipe) → zurueck zur Quellenliste
6. Dateien-Banner antippen → Datei-Anleitung erscheint
7. Zurueck → zurueck zur Quellenliste
8. Locale auf EN umschalten → alle neuen Texte englisch
9. Light- und Dark-Mode pruefen → Banner-Hintergrund und Step-Badges harmonieren mit dem Akzent

---

## Referenz

- iOS-Pendant: [shared-039b](shared-039b-import-anleitungen.md) — gleiche Copy, gleiches Layout-Konzept
- iOS-Implementierung als Vorlage:
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/ContentGuideSheet.swift` (Banner-Sektion + `ImportBannerCard`)
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportBrowserView.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportFilesView.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportStepCard.swift`
- iOS-Localizable: `ios/StillMoment/Resources/{de,en}.lproj/Localizable.strings`, Keys mit Praefix `guided_meditations.guide.banner.*` und `guided_meditations.guide.howto.*`
- Android-Basis: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/ContentGuideSheet.kt`

---

## Hinweise

Drei Punkte sollten **vor** der Implementierung geklaert werden, weil sie das Verhalten nach aussen praegen:

1. **Sub-Screen-Navigation aus dem `ModalBottomSheet`.** Compose Material 3 hat keinen NavigationStack im Sheet. Drei realistische Wege:
   - State-basiert (`AnimatedContent` o.ae. wechselt zwischen Listen-View und Detail-View innerhalb desselben Sheets). Naehe zum iOS-Push-Verhalten am besten, kein extra Setup, einfach testbar.
   - Sheet-on-Sheet (zweites `ModalBottomSheet` oben drauf). Zwei Drag-Indicators, doppelt-stacked Look — eher unschoen.
   - Vollscreen-Route (Sheet schliessen, Detail als Compose-Destination pushen). Konsistent mit Material, aber bricht den „im Sheet bleiben"-Eindruck.
   Vorschlag: Variante 1, weil sie iOS am naechsten kommt.

2. **Android-Share-Intent-Flow.** Die Schritt-Texte aus dem iOS-Pendant beschreiben „Im Browser lange tippen → Teilen → Still Moment". Vor der Uebernahme verifizieren, dass die App in `AndroidManifest.xml` einen passenden `intent-filter` fuer `ACTION_SEND` mit Audio-MIME-Types hat (sonst erscheint Still Moment im Browser-Share-Sheet gar nicht und die Anleitung beschreibt einen nicht-funktionierenden Weg). Falls der Flow auf Android anders aussieht (z. B. „Herunterladen + dann via Files importieren"), Copy entsprechend anpassen statt 1:1 uebersetzen.

3. **Material-Icon-Mapping fuer SF Symbols.** Die iOS-Anleitung nutzt `square.and.arrow.up` (Share), `flame` (App-Symbol), `checkmark.circle`, `plus`, `doc.fill`, `safari`, `folder`. Vor der Implementierung ein passendes Material-Icons-Mapping festlegen, das den gleichen visuellen Eindruck transportiert; insbesondere fuer Schritt 2 der Browser-Anleitung („Still Moment auswaehlen" — auf iOS `flame`, auf Android ggf. App-Launcher-Icon oder ein generisches App-Symbol).

Weitere Punkte aus shared-039b, die wir uebernehmen sollten:

- **Kein Footer-CTA.** Mit nativem Zurueck + Swipe-Geste waere ein „Verstanden"-Button reine Redundanz.
- **Drag-down schliesst das ganze Sheet.** Akzeptiert, weil Back-Button und Swipe als Rueckweg ausreichen.
- **Theme-Tokens.** `accentBannerBackground` + `accentBannerBorder` als neue computed properties auf `StillMomentColors` einfuehren (abgeleitet von `interactive` mit Opacity 0.10 / 0.28, analog iOS).
- **Kein Tracking.** Harte Anforderung, keine Verhandlungsbasis.

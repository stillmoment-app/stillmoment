# Ticket shared-039b: Import-Anleitungen im Content Guide

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: UI-only auf iOS. Banner-Karten als NavigationLink in den bestehenden NavigationStack des `ContentGuideSheet`, zwei Detail-Views als gepushte Sub-Screens. Zwei neue Theme-Tokens (computed properties) fuer Banner-BG und -Border.
**Phase**: 4-Polish

---

## Was

Erweitert das in shared-039 eingefuehrte `ContentGuideSheet` um zwei Banner-Karten direkt unter dem Intro. Jedes Banner oeffnet ein eigenes Detail-Sheet mit einer dreistufigen Anleitung, wie Nutzer Audio-Dateien importieren koennen — einmal aus dem Browser (Share-Sheet → Still Moment), einmal aus den iOS-Dateien (`+` → Aus Dateien).

## Warum

Neue Nutzer kennen die App-internen Import-Wege nicht. Sie sehen den Quellen-Sheet, finden eine MP3 — und wissen oft nicht, wie sie diese Datei zu Still Moment bekommen. Ohne sichtbare Anleitung bleiben beide Import-Wege ein Blindfleck und der Content-Guide-Flow bricht ab. Die Banner schliessen die Luecke direkt am Punkt der hoechsten Motivation.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-039 (ContentGuideSheet)  |
| Android   | -      | folgt in spaeterem Ticket |

---

## Akzeptanzkriterien

### Quellen-Sheet (Erweiterung von ContentGuideSheet)
- [ ] Zwei Banner-Karten erscheinen direkt unter dem Intro, oberhalb der Quellen-Sektion.
- [ ] Browser-Banner steht oben, Datei-Banner darunter.
- [ ] Jedes Banner zeigt Icon-Bubble (links), Titel + Subtitle (Mitte), Chevron-Right (rechts).
- [ ] Tap auf Banner oeffnet das jeweilige Detail-Sheet.
- [ ] Bestehender Header, Intro-Paragraph, Quellenliste, Footer-Hinweis und Close-X-Verhalten unveraendert.

### Browser-Anleitung (HowToImportBrowserView)
- [ ] Sub-Screen zeigt Eyebrow „Anleitung", Titel „So importierst du aus dem Browser" und nativen Chevron-Left Back-Button (oben links).
- [ ] Drei nummerierte Schritte: „Im Browser teilen", „Still Moment auswaehlen" (Icon `flame`), „In der App fertigstellen".
- [ ] Vertikale Verbindungslinie zwischen Schritt-Badges sichtbar (1↔2 und 2↔3).
- [ ] Back-Button und Swipe-back-Geste navigieren zurueck zur Quellenliste; das Quellen-Sheet bleibt erhalten. Kein zusaetzlicher Footer-CTA.

### Datei-Anleitung (HowToImportFilesView)
- [ ] Identische Struktur und Verhalten wie Browser-Anleitung.
- [ ] Titel: „So importierst du aus deinen Dateien".
- [ ] Drei Schritte: „„+" in der Bibliothek tippen", „Audio-Datei waehlen", „Fertigstellen".

### Lokalisierung
- [ ] Alle neuen Strings als Localizable.strings-Keys (DE + EN). Keine hartcodierten Texte in Views.

### Privacy
- [ ] Keine Tracking-Events fuer Banner-Taps oder Sheet-Oeffnungen. Keine Logging-Eintraege.

### Theme & Quality
- [ ] Funktioniert in allen drei Themes (Kerzenschein / Wald / Mondlicht), Light + Dark — manuell in allen 6 Kombinationen verifiziert.
- [ ] Banner-Hintergrund und Border kommen aus semantischen Theme-Tokens (computed properties auf `ThemeColors`), keine direkten Hex-Werte oder Opacity-Aufrufe in Views.
- [ ] Banner-Karten sind als Button semantisch, Back-Button hat `accessibilityLabel`, Schritt-Nummern werden VoiceOver-vorgelesen („Schritt 1 von 3").

### Tests
- [ ] UI-Test: Beide Banner sichtbar im Quellen-Sheet (`LibraryFlowUITests`).
- [ ] UI-Test: Browser-Banner-Tap navigiert zur Browser-Anleitung; Back-Button kehrt zur Quellenliste zurueck.
- [ ] UI-Test: Files-Banner-Tap navigiert zur Files-Anleitung; Back-Button kehrt zur Quellenliste zurueck.

### Dokumentation
- [ ] CHANGELOG.md aktualisiert.

---

## Manueller Test

1. Library oeffnen, `ⓘ` antippen → Quellen-Sheet erscheint.
2. Beide Banner sichtbar oberhalb der Quellen.
3. Browser-Banner antippen → Browser-Anleitung pusht rein.
4. Drei Schritte sichtbar, Verbindungslinie zwischen Badges.
5. Back-Button tippen → zurueck zur Quellenliste.
6. Dateien-Banner antippen → Datei-Anleitung pusht rein.
7. Swipe-back-Geste → zurueck zur Quellenliste.
9. Locale auf EN umschalten → alle neuen Texte englisch.
10. Alle 6 Theme-Kombinationen durchgehen (Kerzenschein/Wald/Mondlicht × Light/Dark) → Banner-BG und Step-Badges harmonieren mit dem jeweiligen Akzent.

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_039b_import_guides/` (README.md ist Source of Truth fuer Layout, Copy, Tokens; `import-flow.jsx` als visuelle Referenz).
- Bestehender Sheet: `ios/StillMoment/Presentation/Views/GuidedMeditations/ContentGuideSheet.swift`.
- Vorgaenger-Ticket: `shared-039` (Empty State + In-App Content Guide).

---

## Hinweise

- **Praesentation als NavigationLink-Push**: Der `ContentGuideSheet` laeuft bereits in einem `NavigationStack` (`GuidedMeditationsListView.swift`). Banner sind `NavigationLink`s, die Anleitungs-Views in den bestehenden Stack pushen. Bewusste Abweichung vom Handoff (das Sheet-on-Sheet beschreibt) — vermeidet bekannte iOS-16-Sheet-Vererbungs-Quirks und liefert nativen Chevron-Left + Swipe-back-Geste.
- **Drag-down-Verhalten**: Drag-down auf den Sheet-Grabber schliesst das ganze Quellen-Sheet — auch wenn eine Anleitung gerade gepusht ist. Trade-off: Akzeptiert, weil Back-Button und Swipe-back als explizite Rueckwege ausreichen.
- **Kein Footer-CTA**: Bewusste Abweichung vom Handoff (das einen „Verstanden"-Button vorsieht). Mit nativem Back-Button + Swipe-back-Geste waere ein zusaetzlicher CTA reine Redundanz.
- **Mini-Vorschau Share-Sheet**: Optional im Handoff erwaehnt — bewusst weggelassen (Pflegeaufwand, kein klarer Mehrwert; Schritt-Text reicht).
- **Theme-Tokens**: Banner-BG und -Border werden als computed properties (`accentBannerBackground`, `accentBannerBorder`) auf `ThemeColors` ergaenzt — abgeleitet von `interactive` mit Opacity 0.10 / 0.28. Kein Per-Theme-Hand-Tuning noetig.
- **Step-2-Icon Browser-Flow**: SF Symbol `flame` (statt App-Icon-Asset). Konsistent mit anderen Step-Icons, tintet automatisch im Theme.
- **Android folgt spaeter**: Bewusst nicht in diesem Ticket. Sobald iOS abgenommen ist, wird ein eigenes Android-Ticket angelegt.
- **Kein Tracking** ist eine harte Anforderung, keine Verhandlungsbasis.

# Ticket shared-099: Typografie Newsreader + Geist (Android-Sync)

**Status**: [~] IN PROGRESS — Android implementiert, Close ausstehend
**Plan**: [shared-099-android.md](../plans/shared-099-android.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Zwei neue Schrift-Familien (Newsreader Serif + Geist Sans) ins App-Bundle einbinden und das bestehende Compose-Typografie-System auf zwei Familien aufteilen statt einer einzigen System-Font. Risiko liegt in der Token-Reduktion (existierende `TypographyRole`-Aufrufstellen umstellen), Dynamic-Type-aequivalenter Skalierung (Compose nutzt `sp` + System-Font-Scale) und visueller Regression in allen Views.
**Phase**: 4-Polish

---

## Was

Die zwei im Handoff "Kerzenschein 2.0" festgelegten Schrift-Familien ins Android-App-Bundle einziehen: **Newsreader** (Serif) traegt Display, Inhalt und Numerik, **Geist** (Sans) traegt UI, Labels und technische Werte. Das bestehende `TypographyRole`-System (20+ Rollen, Nunito Variable Font) wird auf **10 Tokens** reduziert (`display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`) — identisch zur iOS-Variante.

## Warum

Android laeuft heute mit Nunito und einem 20-Rollen-System, das ueber die letzten Refinement-Schritte gewachsen ist. iOS hat mit `ios-048` Newsreader + Geist eingezogen und das Token-System auf 10 reduziert — ohne diesen Sync sehen die Plattformen unterschiedlich aus, und die nachfolgenden Refinements (`shared-094` Theme 2.0) bauen auf der neuen Rollen-Liste auf.

Editorial-Voice fuer Display-Texte (Serif) gibt der App Charakter, technische UI-Texte (Sans) bleiben ruhig steuernd. Das Mapping ist im iOS-Handoff bereits durchdacht; Android zieht 1:1 nach.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `ios-048` |
| Android   | [~]    | Implementierung abgeschlossen, ausstehend: `/close-ticket` |

---

## Akzeptanzkriterien

### Schrift-Bundling

- [ ] Newsreader (OFL) in Light/Regular und Italic statisch im Android-App-Bundle (`res/font/`), nicht zur Laufzeit nachgeladen
- [ ] Geist (OFL) in Light/Regular/Medium statisch im Bundle
- [ ] OFL-Lizenztexte liegen bei den Schriften im Bundle und sind ueber die "Klang- und Schrift-Nachweise"-Sektion erreichbar (Folge-Ticket fuer beide Plattformen — `ios-049` ist iOS-Pendant)

### Token-System

- [ ] Exakt 10 Tokens: `display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`
- [ ] Mapping Serif: `display`, `title`, `screenTitle`, `section`, `bodyItalic` → Newsreader
- [ ] Mapping Sans: `body`, `bodyEmphasis`, `caption`, `micro`, `eyebrow` → Geist
- [ ] Gewichte: Newsreader Light 300 fuer Display-Tokens; Geist Regular 400 fuer Body/Caption/Micro/Eyebrow; Geist Medium 500 fuer `.bodyEmphasis` (CTAs)
- [ ] Italic-Akzent ueber eigenen Token `.bodyItalic` mit Newsreader-Italic — kein dekoratives `fontStyle = Italic` mehr; nur fuer Hervorhebungen / Eigennamen in Akzentfarbe
- [ ] Sekundaerfarbe wird ueber Theme-Color-Override am Token gesetzt, nicht ueber einen eigenen Token (kein `bodyPrimary`/`bodySecondary`-Split)
- [ ] Alte `TypographyRole`-Namen geloescht (nicht deprecated): die heute existierenden Rollen wie `TimerCountdown`, `PlayerTitle`, `BodyPrimary`/`BodySecondary`, `ListSubtitle`, `EditLabel` etc. fallen weg

### Dynamic Text / System-Font-Scale

- [ ] Jeder Token nutzt `sp` — das System-Font-Scale-Setting skaliert mit
- [ ] Display-Numerik (Timer Idle + Running) bindet container-relativ statt fixe `sp`-Werte — Pendant zum iOS `DisplayNumeral(text:, containerDiameter:)`
- [ ] iPhone-SE-Aequivalent (Pixel 3a, kompakte Hoehe) — keine Truncation in Library, Timer-Idle, Timer-Running, Settings, ContentGuide-Sheet
- [ ] System-Font-Scale auf "Largest" (1.3x): Custom-Layouts (Library Empty, IdleSettingsList, Beginnen-Button) bleiben sichtbar; falls ein Layout dort bricht, in Folge-Ticket auslagern (entspricht iOS `ios-050`)

### Halation-Kompensation

- [ ] Der automatische Weight-Bump in Dark Mode (Nunito-Regular → Medium etc.) entfaellt analog zu iOS — Newsreader-Serifen und Geist-Mediums tragen ohne globalen Bump. Wenn eine Rolle in Dark Mode zu duenn wirkt, **gezielt** im Spec eine Stufe schwerer setzen, kein versteckter Modus-Bump

### Bold-Text-Setting

- [ ] Wenn das System-Bold-Text-Setting aktiv ist, mappt das Token-System: Geist Regular → Medium, Geist Medium → SemiBold (sofern SemiBold gebundled), Newsreader Light → Regular; Italic bleibt Italic
- [ ] Pendant zur iOS `LegibilityWeight`-Environment-Logik

### Migration der Aufrufstellen

- [ ] Alle `TypographyRole.{Alt}.textStyle()`-Aufrufe auf `.textStyle(_)`-Modifier mit neuem 10-Token-System umgestellt
- [ ] Numerik via `.textStyle(.display, monospacedDigits = true)` bzw. `.textStyle(.body, monospacedDigits = true)` — Tabular Figures pro Aufrufstelle, nicht global

### Tests

- [ ] Unit-Tests fuer das 10-Token-System: Anzahl, Mapping Font-Familie pro Token, Base-Sizes, Bold-Text-Bump
- [ ] Unit-Tests fuer container-relative Display-Numerik (Diameter × Faktor, Cap bei sehr grosser System-Font-Scale)
- [ ] Alte `TypographyRoleTests` mit dem Cleanup entfernt

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung: neue Schrift, ruhigere Schrift-Hierarchie, kein Halation-Bump mehr)
- [ ] Debug-Reference-Screen (Settings → Debug → Typography Reference) analog iOS — 10 Tokens, Side-by-Side Light/Dark, Picker fuer Font-Scale-Stufen, Toggle fuer Bold-Text. Nur in Debug-Builds.

---

## Manueller Test

1. App in Light Mode oeffnen — Library, Timer (Idle + Running), Player, Settings, Danke-Screen besuchen
2. App in Dark Mode oeffnen — gleiche Views besuchen
3. System-Font-Scale auf "Largest" stellen → Library und Timer pruefen
4. System-Bold-Text aktivieren → erneut pruefen, Gewichte sind eine Stufe schwerer

Erwartung: Titel/Body/Numerik in Serif (Newsreader), Labels/Buttons/Werte in Sans (Geist); visuell vergleichbar mit dem iOS-Endstand; kein Text wird abgeschnitten, kein Layout-Bruch in groesseren Font-Scale-Stufen.

---

## Referenz

- iOS-Pendant: [ios-048](../ios/ios-048-typografie-newsreader-geist.md)
- iOS-Handoff: `handoffs/handoff_typografie/Kerzenschein 2.0 Final.html`
- iOS-Plan: `handoffs/Typografie 2.1 - Plan.html`
- iOS-Implementierung (zur Referenz): `ios/StillMoment/Presentation/Views/Shared/TextStyle.swift` + `View+TextStyle.swift` + `DisplayNumeral.swift`
- Aktuelles Android-Typografie-System: `android/app/src/main/kotlin/com/stillmoment/.../ui/theme/Typography.kt` (Nunito + `TypographyRole`)

---

## Hinweise

- Newsreader und Geist sind Google Fonts (OFL-Lizenz). Aus Privacy-Gruenden statisch ins App-Bundle einbinden, nicht zur Laufzeit nachladen.
- Compose `Font(R.font.newsreader_light, FontWeight.Light)` etc.; `FontFamily(...)` pro Familie aufbauen.
- Dynamic Text auf Android: Compose nutzt `sp` und folgt damit automatisch `Settings → Display → Font Size`. Display-Numerik soll trotzdem container-relativ sein, damit der Timer-Ring nicht aus dem Bildschirm waechst — gleiche Spielregel wie iOS.
- Tabular Figures: Newsreader unterstuetzt `tnum`. In Compose via `TextStyle(fontFeatureSettings = "tnum")` pro Aufrufstelle, nicht global.
- Begleit-Tickets ueber Folgeschritte (Layout-Anpassungen fuer sehr grosse Font-Scales, OFL-Nachweise in den Settings) werden separat angelegt, falls beim Smoketest noetig.

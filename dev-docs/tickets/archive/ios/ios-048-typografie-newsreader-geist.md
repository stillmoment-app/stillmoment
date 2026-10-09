---
id: ios-048
title: Typografie Newsreader + Geist nachziehen
status: done
phase: 4-Polish
priority: mittel
---


# Ticket ios-048: Typografie Newsreader + Geist nachziehen

**Plan**: [Implementierungsplan](../../plans/ios-048.md)
**Komplexitaet**: Zwei neue Schrift-Familien (Newsreader Serif + Geist Sans) ins App-Bundle einbinden und das bestehende Typografie-System auf zwei Familien aufteilen statt einer einzigen System-Font. Risiko liegt in Dynamic Type (Custom Fonts skalieren anders), Dark-Mode-Halation (Halation-Kompensation muss mit Custom-Weights weiter greifen) und visueller Regression in allen Views.
**Abhaengigkeiten**: Keine

---

## Was

Die zwei im Handoff "Kerzenschein 2.0" festgelegten Schrift-Familien einziehen: **Newsreader** (Serif) traegt Display, Inhalt und Numerik, **Geist** (Sans) traegt UI, Labels und technische Werte. Die Rollen-Zuordnung folgt der Tabelle im Handoff.

**Erweiterung (Typografie 2.1):** Das durch den ersten Schritt entstandene 27-Rollen-System wird auf **10 Tokens** reduziert (`display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`). Jeder Token bindet ueber `UIFontMetrics` an einen iOS-TextStyle und skaliert mit Dynamic Type. Display-Numerik (Timer) wird container-relativ statt fixe pt-Werte. Alte Style-Namen werden geloescht, nicht deprecated.

## Warum

Seit den Theme-Refinements (shared-094 bis shared-097) ist das Farb- und Layout-System aus dem Handoff in die App gewandert — die Typografie aber nicht. Die App nutzt weiterhin durchgehend SF Rounded. Damit fehlt der Charakter des Designs: Serif als Stimme (Titel, Erklaerung, Ziffern), Sans als Steuerung (Labels, Buttons, Werte).

Der erste Migrationsschritt (Newsreader+Geist einziehen) hat das System auf 27 Rollen aufgeblaeht und mischt feste pt-Werte mit Dynamic-Type-Bindungen. Bei Accessibility-Einstellungen (AX3+) brechen Layouts. Typografie 2.1 raeumt das auf: weniger Tokens, Dynamic Type ist Quelle der Wahrheit, klare Spielregel fuer Display-Numerik.

---

## Akzeptanzkriterien

### Feature

- [x] Display-Texte erscheinen in Newsreader (Serif): Hero-/Screen-Titel, Section-Titel, Body-Italic (Lehrer-Name), Timer-Ziffern (Idle + Running via `DisplayNumeral`), Player-Countdown, Dialog-Titel, Dial-Wert — gemappt auf Tokens `.display`, `.title`, `.screenTitle`, `.section`, `.bodyItalic`
- [x] UI-Texte erscheinen in Geist (Sans): Library-Titel, Track-Listen-Titel/Untertitel, Settings-Labels, Row-Labels, Eyebrows/Caps, CTA-Buttons, Card-Labels, Dial-Einheit, Timestamps — gemappt auf `.body`, `.bodyEmphasis`, `.caption`, `.micro`, `.eyebrow`
- [x] Gewichte folgen Handoff: Newsreader Light 300 fuer Display-Tokens, Geist Regular 400 fuer Body/Caption/Micro/Eyebrow, Geist Medium 500 fuer `.bodyEmphasis` (CTAs)
- [x] Italic-Akzent als eigener Token `.bodyItalic` (Newsreader16pt-Italic) — kein dekoratives `.italic()` mehr; nur fuer Hervorhebungen / Eigennamen in Akzentfarbe
- [x] Dynamic Type skaliert: jeder Token bindet ueber `UIFontMetrics` an einen `Font.TextStyle`. Layout-Anpassungen ab AX2+ ausgelagert nach [ios-050](../../ios/ios-050-typografie-2-1-a11y-layout.md)
- [x] Dark Mode bleibt lesbar — Halation-Kompensation entfaellt bewusst (siehe CHANGELOG-Eintrag): Newsreader Light traegt auf dunklem Hintergrund durch Serif-Optik; falls eine Rolle zu duenn wirkt, gezielt eine Stufe schwerer im Spec statt globalem Modus-Bump
- [x] Numerik via `.textStyle(.display, monospacedDigits: true)` bzw. `.textStyle(.body, monospacedDigits: true)` — tabular Figures als Modifier-Parameter pro Aufrufstelle

### Typografie 2.1 (Acceptance-Checkliste aus `handoffs/Typografie 2.1 - Plan.html`)

In dieser Reihenfolge — Punkt fuer Punkt, jeweils mit eigenem Commit:

- [x] 1. Schriften registriert (Newsreader-Light/-Regular/-Italic, Geist-Regular/-Medium/-SemiBold in `UIAppFonts`; Debug-Print verifiziert) — Commit c1c5ac8
- [x] 2. `TextStyle.swift` existiert mit 10 Cases (`display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`) — Commit a6e6577
- [x] 3. `.textStyle(_)`-Modifier ersetzt alle `.font(_)`/`.themeFont(_)`-Aufrufe (Ausnahme: `DisplayNumeral`) — Commit b89811e
- [x] 4. Alte Style-Namen geloescht (nicht deprecated): `.timerCountdown`, `.playerTitle`, `.bodyPrimary`, `.bodySecondary`, `.listSubtitle`, `.editLabel` etc. — Commit 372f7b9
- [x] 5. Display-Numerik container-relativ via `DisplayNumeral(text:, containerDiameter:)` — keine hardcoded pt-Werte mehr; ab AX2 cappt die Numerik (Layout-Verschiebung folgt in Schritt 8) — Commit 311a4a6
- [x] 6. Sekundaerfarbe via Theme-Color-Override am Token, nicht via eigenen Token — strukturell durch Schritt-3-Migration implementiert (z.B. `.body, color: \.textSecondary` statt eigenem `.bodySecondary`)
- [x] 7. iPhone-SE-2022-Smoketest (375x667) — Library (Empty State), Timer-Idle, Timer-Running (mit DisplayNumeral), Settings und ContentGuide-Sheet visuell geprueft. Kein Overflow, TabBar bleibt sichtbar, kein Layout-Bruch. **Bekanntes Pre-Existing-Issue (nicht durch Migration verursacht):** Inline-NavBar-Title "Geführte Meditatio..." truncated — Inline-NavBars haben weniger horizontalen Platz als Large-Titles und 'Geführte Meditationen' ist auch im alten System knapp gewesen. Folge-Ticket optional.
- [x] 8. Dynamic-Type-Smoketest auf AX3 verifiziert — Findings: Custom-Layouts (Library Empty, IdleSettingsList, Beginnen-Button-Position) truncaten/ueberlappen bei AX3; Settings-Form (System) skaliert sauber. Layout-Refactoring (HStack→VStack, Numerik unter Ring, Sheet-Detents) ist scope-grenzwertig fuer dieses Ticket; **Folge-Ticket [ios-050](../../ios/ios-050-typografie-2-1-a11y-layout.md) angelegt**.
- [x] 9. Bold-Text-Setting honoriert — `TextStyle.effectiveFontName(legibility: .bold)` mappt Geist Regular→Medium, Geist Medium→SemiBold, Newsreader Light→Regular; Italic bleibt Italic. **Acceptance:** 4 fachliche Tests in `TextStyleTests` (testBoldTextBumps*) — alle gruen. Visuell beweisbar via Debug-Reference-View mit `.environment(\.legibilityWeight, .bold)`-Preview (Schritt 10 erweitert die Reference-View entsprechend).
- [x] 10. Debug-„Typography Reference"-Screen aktualisiert: 10 Tokens mit Plan-spezifischen Sample-Texten ("15:00", "Player-Titel", "Stille beobachten.", "— Anna Maria Berg", "Heute · 14. März" …), Segmented-Picker fuer Dynamic-Type-Stops (xS / L / AX1 / AX3 / AX5), Toggle fuer Bold-Text. Spec-Description zeigt `effectiveFontName(legibility:)` — bei Bold-Toggle wechselt der angezeigte Font-Name dynamisch (z.B. Geist-Medium → Geist-SemiBold). Light/Dark Side-by-Side bleibt erhalten.

### Tests

- [x] `TextStyleTests` validiert das 10-Token-System: Anzahl, Dynamic-Type-Mapping, Base-Sizes, Font-Familien-Zuordnung (Serif-Tokens → Newsreader, Sans-Tokens → Geist), Tracking/Casing, Bold-Text-Bump
- [x] `DisplayNumeralTests` validiert die container-relative Numerik (Diameter × Faktor, AX1-Cap, Tabular Figures)
- [x] Alte `TypographyTests.swift` mit Schritt 4 geloescht (Stale-Tests gegen die abgeloeste TypographyRole-API); ersetzt durch obige Tests

### Dokumentation

- [x] CHANGELOG.md (mehrere Eintraege unter [Unreleased] → Typografie, Player-Editorial-Voice, Halation-Entfernung, Buttons + Stepper auf Geist, Debug-Reference-View)
- [x] Memory-Eintrag aktualisiert: `MEMORY.md` Abschnitt „Typography System (Typografie 2.1 — TextStyle.swift)"

---

## Manueller Test

1. App in Light Mode oeffnen — Library, Timer (Idle + Running), Player, Settings, Danke-Screen besuchen
2. App in Dark Mode oeffnen — gleiche Views besuchen
3. Dynamic Type auf "extraExtraLarge" stellen, Library und Timer pruefen
4. Erwartung: Titel/Body/Numerik in Serif (Newsreader), Labels/Buttons/Werte in Sans (Geist); visuell vergleichbar mit `handoffs/handoff_typografie/Kerzenschein 2.0 Final.html`; kein Text wird abgeschnitten, kein Layout-Bruch in groesseren Dynamic-Type-Stufen

---

## Referenz

- Handoff: `handoffs/handoff_typografie/Kerzenschein 2.0 Final.html` (Sektion "Typografie · Newsreader + Geist", Rollen-Tabelle)
- **Typografie 2.1 Plan (Source of Truth fuer Reduktion auf 10 Tokens):** `handoffs/Typografie 2.1 - Plan.html`
- Vorherige Refinement-Tickets: shared-094, shared-095, shared-096, shared-097
- Aktuelles Typografie-System: `ios/StillMoment/Presentation/Views/Shared/TextStyle.swift` (10 Tokens) + `View+TextStyle.swift` (ViewModifier-Bridge) + `DisplayNumeral.swift` (container-relative Numerik)
- Tests: `ios/StillMomentTests/Presentation/TextStyleTests.swift` + `DisplayNumeralTests.swift`
- Debug-Hilfe: `ios/StillMoment/Presentation/Views/Debug/DebugTypographyReferenceView.swift` (Settings → Debug → Typography Reference, nur Debug-Build)

---

## Hinweise

- Newsreader und Geist sind Google Fonts (OFL-Lizenz). Aus Privacy-Gruenden statisch ins App-Bundle einbinden, nicht zur Laufzeit nachladen.
- Beide Familien werden in mehreren Gewichten gebraucht (300/400/500). Newsreader zusaetzlich in Italic.
- Dynamic Type mit Custom Fonts: `Font.custom(_, size:relativeTo:)` skaliert relativ zu einem TextStyle. Fuer `.dynamic`-Rollen im bestehenden System pruefen, dass das mitskaliert.
- Tabular Figures fuer Timer-Ziffern: Newsreader unterstuetzt `.featureSettings` mit `tnum` — sicherstellen, dass die Ziffernbreite konstant bleibt, sonst springt der Timer.
- Andere Plattform (Android) ist explizit nicht Teil dieses Tickets. Wenn das Refinement dorthin uebergeht, wird das in einem separaten Ticket nachgezogen.

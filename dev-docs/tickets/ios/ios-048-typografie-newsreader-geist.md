
# Ticket ios-048: Typografie Newsreader + Geist nachziehen

**Status**: [ ] TODO
**Plan**: [Implementierungsplan](../plans/ios-048.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Zwei neue Schrift-Familien (Newsreader Serif + Geist Sans) ins App-Bundle einbinden und das bestehende Typografie-System auf zwei Familien aufteilen statt einer einzigen System-Font. Risiko liegt in Dynamic Type (Custom Fonts skalieren anders), Dark-Mode-Halation (Halation-Kompensation muss mit Custom-Weights weiter greifen) und visueller Regression in allen Views.
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die zwei im Handoff "Kerzenschein 2.0" festgelegten Schrift-Familien einziehen: **Newsreader** (Serif) traegt Display, Inhalt und Numerik, **Geist** (Sans) traegt UI, Labels und technische Werte. Die Rollen-Zuordnung folgt der Tabelle im Handoff.

## Warum

Seit den Theme-Refinements (shared-094 bis shared-097) ist das Farb- und Layout-System aus dem Handoff in die App gewandert — die Typografie aber nicht. Die App nutzt weiterhin durchgehend SF Rounded. Damit fehlt der Charakter des Designs: Serif als Stimme (Titel, Erklaerung, Ziffern), Sans als Steuerung (Labels, Buttons, Werte).

---

## Akzeptanzkriterien

### Feature

- [ ] Display-Texte erscheinen in Newsreader (Serif): Hero-/Screen-Titel, Section-Titel, Body-Display/Lede, Timer-Ziffern (Idle + Running), Player-Countdown, Dialog-Titel, Dial-Wert
- [ ] UI-Texte erscheinen in Geist (Sans): Library-Titel, Track-Listen-Titel/Untertitel, Settings-Labels, Row-Labels, Eyebrows/Caps, CTA-Buttons, Card-Labels, Dial-Einheit, Code/Token-Snippets
- [ ] Default-Gewicht 300 (light), Regular 400 fuer benannte Elemente, Medium 500 nur fuer Play-CTA und Systemzeit — wie im Handoff
- [ ] Italic-Akzent ausschliesslich fuer Hervorhebungen in Akzent-/Highlight-Farbe, nie als dekorativer Stil
- [ ] Dynamic Type skaliert weiterhin korrekt (Texte werden bei groesseren Stufen groesser, brechen Layout nicht)
- [ ] Dark Mode: Lesbarkeit/Kontrast nicht schlechter als vorher — Halation-Kompensation greift weiter
- [ ] Numerik (Timer-Ziffern) zeigt einheitliche Ziffernbreite (tabular figures), damit die Anzeige beim Herunterzaehlen nicht springt

### Tests

- [ ] Unit-Tests in TypographyTests validieren Font-Familien-Zuordnung pro Rolle (Display-Rollen → Newsreader, UI-Rollen → Geist)
- [ ] Bestehende Typografie-Tests bleiben gruen (Weight, Size, Farbe, Halation-Kompensation)

### Dokumentation

- [ ] CHANGELOG.md (Typografie sichtbar geaendert)
- [ ] Memory-Eintrag fuer Typography System aktualisieren (Custom-Font-Wechsel)

---

## Manueller Test

1. App in Light Mode oeffnen — Library, Timer (Idle + Running), Player, Settings, Danke-Screen besuchen
2. App in Dark Mode oeffnen — gleiche Views besuchen
3. Dynamic Type auf "extraExtraLarge" stellen, Library und Timer pruefen
4. Erwartung: Titel/Body/Numerik in Serif (Newsreader), Labels/Buttons/Werte in Sans (Geist); visuell vergleichbar mit `handoffs/handoff_typografie/Kerzenschein 2.0 Final.html`; kein Text wird abgeschnitten, kein Layout-Bruch in groesseren Dynamic-Type-Stufen

---

## Referenz

- Handoff: `handoffs/handoff_typografie/Kerzenschein 2.0 Final.html` (Sektion "Typografie · Newsreader + Geist", Rollen-Tabelle)
- Vorherige Refinement-Tickets: shared-094, shared-095, shared-096, shared-097
- Bestehendes Typografie-System: `ios/StillMoment/Presentation/Views/Shared/Font+Theme.swift`
- Bestehende Tests: `ios/StillMomentTests/Presentation/TypographyTests.swift`

---

## Hinweise

- Newsreader und Geist sind Google Fonts (OFL-Lizenz). Aus Privacy-Gruenden statisch ins App-Bundle einbinden, nicht zur Laufzeit nachladen.
- Beide Familien werden in mehreren Gewichten gebraucht (300/400/500). Newsreader zusaetzlich in Italic.
- Dynamic Type mit Custom Fonts: `Font.custom(_, size:relativeTo:)` skaliert relativ zu einem TextStyle. Fuer `.dynamic`-Rollen im bestehenden System pruefen, dass das mitskaliert.
- Tabular Figures fuer Timer-Ziffern: Newsreader unterstuetzt `.featureSettings` mit `tnum` — sicherstellen, dass die Ziffernbreite konstant bleibt, sonst springt der Timer.
- Andere Plattform (Android) ist explizit nicht Teil dieses Tickets. Wenn das Refinement dorthin uebergeht, wird das in einem separaten Ticket nachgezogen.

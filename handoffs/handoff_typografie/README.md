# Handoff · Typografie Kerzenschein 2.0

Aktualisiertes Spec-Dokument mit einer neuen Sektion **„Typografie · Newsreader + Geist"** direkt nach dem Hero. Löst die offenen Fragen zur Schrift-Zuordnung im Theme.

## Inhalt
- `Kerzenschein 2.0 Final.html` — vollständiges Spec-Dokument, lokal im Browser öffnen.

## Was neu ist
Die neue Typografie-Sektion enthält:

1. **Zwei Familien-Cards** (Newsreader + Geist) mit Glyph-Sample, CSS-Variable, Fallback-Stack und genutzten Gewichten (300 / 400 / 500).
2. **Rollen-Tabelle** mit jedem konkreten Slot — H1, Lede, Italic-Akzent, Timer-Numerik, Library-Title, Row-Label, Eyebrow, CTA, Code — inkl. Beispiel, Einsatzort und zugewiesener Familie.
3. **Drei Regeln** als Kurz-Manifest:
   - Serif spricht, Sans steuert
   - Italic ist Farbe, kein Stil (nur `<em>` + `var(--hl)`)
   - Light (300) ist der Default in beiden Familien

## Kernaussage
- `var(--font-display)` = **Newsreader** → Stimme, Inhalt, Numerik
- `var(--font-ui)` = **Geist** → Funktion, Labels, Werte, Code
- Italic ausschließlich für `<em>` in Akzentfarbe
- Default-Gewicht 300, Regular 400 für benannte Elemente, Medium 500 nur für Play-CTA + Systemzeit

## Quellen im Code
```css
--font-display: 'Newsreader', Georgia, serif;
--font-ui: 'Geist', -apple-system, system-ui, sans-serif;
```
Google-Fonts-Imports stehen am Anfang der Datei (`<head>`).

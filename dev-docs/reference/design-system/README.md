# Still Moment — Design-Referenz (Ist-Stand)

> *Deine Meditationen, dein Raum.*

Konsolidierte Design-Referenz für Still Moment: App-Beschreibung, Screens, Farb-Tokens,
Typografie und Richtlinien. **Aus dem Code extrahiert** (`ThemeColors+Palettes.swift`,
`TextStyle.swift`, `CLAUDE.md`, `ux-conventions.md`) — dokumentiert den *aktuell implementierten*
Stand, nicht offene Entwürfe.

## Inhalt dieses Ordners

| Datei | Zweck |
|-------|-------|
| `still-moment-design.md` | **Die Referenz** — alles in Markdown (App, Screens, Tokens, Typo, Richtlinien). |
| `index.html` | Browsbare Version derselben Inhalte: echte App-Fonts gerendert, Farbfelder, Screenshots. Im Browser öffnen. |
| `screens/` | 15 Screenshots (iPhone 17 Pro Max, de-DE, Dark Mode) — alle App-Screens (Bibliothek, Suche, Player, Bearbeiten, Trim, Import-Anleitung, Timer idle/läuft, Vorbereitung, Gong, Intervall-Gongs, Soundscape, Einstellungen, Abschluss, leere Bibliothek). |
| `fonts/` | Die echten App-Fonts (Geist, Newsreader) — nur für die `index.html`-Darstellung. |

## In ein claude.ai-Projekt hochladen

Damit Claude den **Ist-Stand** kennt (und ihn von offenen Entwürfen unterscheidet), genügt:

1. `still-moment-design.md` — die eigentliche Referenz, die Claude liest.
2. Die 15 PNGs aus `screens/` — geben den visuellen Kontext.

Die `index.html` und `fonts/` sind für *menschliches* Browsen im Repo gedacht; für den
claude.ai-Upload sind sie nicht nötig (Claude liest die Markdown sauberer als HTML-Quelltext).

> **Nicht** mit hochladen: das Gong-Auswahl-Handoff (`handoffs/design_handoff_gong_auswahl/`).
> Das ist ein *Zukunfts-Entwurf*, kein Ist-Stand — genau die Sorte Artefakt, von der dieses
> Dokument den implementierten Stand abgrenzen soll.

## Pflege

Bei Code-Änderungen an Farben/Typografie hier nachziehen. Ergänzend: [`../color-system.md`](../color-system.md).

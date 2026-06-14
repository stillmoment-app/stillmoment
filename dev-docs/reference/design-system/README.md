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
| `screens/` | 6 Screenshots (iPhone, de-DE): `library`, `player`, `edit`, `timer-idle`, `timer-running`, `settings`. |
| `fonts/` | Die echten App-Fonts (Geist, Newsreader) — nur für die `index.html`-Darstellung. |

## In ein claude.ai-Projekt hochladen

Damit Claude den **Ist-Stand** kennt (und ihn von offenen Entwürfen unterscheidet), genügt:

1. `still-moment-design.md` — die eigentliche Referenz, die Claude liest.
2. Die 6 PNGs aus `screens/` — geben den visuellen Kontext.

Die `index.html` und `fonts/` sind für *menschliches* Browsen im Repo gedacht; für den
claude.ai-Upload sind sie nicht nötig (Claude liest die Markdown sauberer als HTML-Quelltext).

> **Nicht** mit hochladen: das Gong-Auswahl-Handoff (`handoffs/design_handoff_gong_auswahl/`).
> Das ist ein *Zukunfts-Entwurf*, kein Ist-Stand — genau die Sorte Artefakt, von der dieses
> Dokument den implementierten Stand abgrenzen soll.

## Pflege

Bei Code-Änderungen an Farben/Typografie hier nachziehen. Ergänzend: [`../color-system.md`](../color-system.md).

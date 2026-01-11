# Developer Documentation

Zentrale Dokumentation fuer das Still Moment Projekt.

**Quick Start:** Fuer den taeglichen Einstieg siehe [`CLAUDE.md`](../CLAUDE.md) im Root.

---

## Architektur verstehen

Dokumentation zum Verstaendnis der Systemarchitektur und Design-Entscheidungen.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [architecture/overview.md](architecture/overview.md) | Monorepo-Struktur, Layer, Cross-Platform Patterns | Einstieg ins Projekt |
| [architecture/audio-system.md](architecture/audio-system.md) | Audio-Session-Koordination, Background Audio | Bei Audio-Features |
| [architecture/ddd.md](architecture/ddd.md) | Immutable Models, Reducer Pattern, Effects | Bei Domain-Logik-Aenderungen |
| [architecture/decisions/](architecture/decisions/) | Architecture Decision Records (ADRs) | "Warum wurde X so geloest?" |

---

## Entwickeln

Guides fuer die taegliche Entwicklungsarbeit.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [guides/tdd.md](guides/tdd.md) | Red-Green-Refactor, Test-Patterns, Coverage | Vor Feature-Implementierung |
| [guides/swiftlint.md](guides/swiftlint.md) | Lint-Regeln, Disable-Kommentare | Bei Lint-Fehlern |
| [guides/screenshots-ios.md](guides/screenshots-ios.md) | iOS App Store Screenshots erstellen | Vor iOS-Release |
| [guides/screenshots-android.md](guides/screenshots-android.md) | Android Play Store Screenshots | Vor Android-Release |
| [guides/website.md](guides/website.md) | GitHub Pages lokal entwickeln | Bei Website-Aenderungen |

---

## Nachschlagen

Referenzdokumentation zum schnellen Nachschlagen.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [reference/glossary.md](reference/glossary.md) | Ubiquitous Language, Domain-Begriffe | Begriff unklar? |
| [reference/color-system.md](reference/color-system.md) | Semantische Farben, Design Tokens | Bei UI-Styling |
| [reference/view-names.md](reference/view-names.md) | Naming-Konventionen fuer Views | Neue View erstellen |

---

## Release

Alles rund um App-Releases.

| Dokument | Inhalt |
|----------|--------|
| [release/RELEASE_GUIDE.md](release/RELEASE_GUIDE.md) | Release-Prozess Schritt fuer Schritt |
| [release/RELEASE_NOTES.md](release/RELEASE_NOTES.md) | User-facing Release Notes |
| [release/TEST_PLAN_IOS.md](release/TEST_PLAN_IOS.md) | Manuelle Tests vor iOS-Release |
| [release/TEST_PLAN_ANDROID.md](release/TEST_PLAN_ANDROID.md) | Manuelle Tests vor Android-Release |
| [release/STORE_CONTENT_*.md](release/) | App Store / Play Store Texte |

---

## Planung

Feature-Konzepte und Ticket-System.

| Verzeichnis | Inhalt |
|-------------|--------|
| [tickets/](tickets/) | Aktive und abgeschlossene Tickets |
| [tickets/INDEX.md](tickets/INDEX.md) | Ticket-Uebersicht nach Status |
| [concepts/](concepts/) | Groessere Feature-Konzepte vor Umsetzung |

---

## Dokumentations-Konventionen

- **CLAUDE.md** im Root: Quick Reference fuer taegliche Arbeit
- **dev-docs/**: Ausfuehrliche Dokumentation
- **ADRs**: Signifikante Architekturentscheidungen in `architecture/decisions/`
- **Tickets**: Feature-Arbeit wird ueber `tickets/` getrackt

### Verzeichnisstruktur

```
dev-docs/
├── architecture/     # System verstehen (Explanation)
│   ├── overview.md
│   ├── audio-system.md
│   ├── ddd.md
│   └── decisions/    # ADRs
├── guides/           # Aufgaben erledigen (How-to)
│   ├── tdd.md
│   ├── swiftlint.md
│   ├── screenshots-ios.md
│   ├── screenshots-android.md
│   └── website.md
├── reference/        # Nachschlagen (Reference)
│   ├── glossary.md
│   ├── color-system.md
│   └── view-names.md
├── release/          # Release-Prozess
├── concepts/         # Feature-Planung
└── tickets/          # Ticket-System
```

Bei neuen Dokumenten:
1. Passende Kategorie oben waehlen
2. In diese README.md eintragen
3. `Last Updated` Datum am Ende des Dokuments pflegen

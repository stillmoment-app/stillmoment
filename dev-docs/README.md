# Developer Documentation

Zentrale Dokumentation fuer das Still Moment Projekt.

**Quick Start:** Fuer den taeglichen Einstieg siehe [`CLAUDE.md`](../CLAUDE.md) im Root.

---

## Architektur verstehen

Dokumentation zum Verstaendnis der Systemarchitektur und Design-Entscheidungen.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Monorepo-Struktur, Layer, Cross-Platform Patterns | Einstieg ins Projekt |
| [AUDIO_ARCHITECTURE.md](AUDIO_ARCHITECTURE.md) | Audio-Session-Koordination, Background Audio | Bei Audio-Features |
| [DDD_GUIDE.md](DDD_GUIDE.md) | Immutable Models, Reducer Pattern, Effects | Bei Domain-Logik-Aenderungen |
| [decisions/](decisions/) | Architecture Decision Records (ADRs) | "Warum wurde X so geloest?" |

---

## Entwickeln

Guides fuer die taegliche Entwicklungsarbeit.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [TDD_GUIDE.md](TDD_GUIDE.md) | Red-Green-Refactor, Test-Patterns, Coverage | Vor Feature-Implementierung |
| [SWIFTLINT_GUIDELINES.md](SWIFTLINT_GUIDELINES.md) | Lint-Regeln, Disable-Kommentare | Bei Lint-Fehlern |
| [SCREENSHOTS.md](SCREENSHOTS.md) | iOS App Store Screenshots erstellen | Vor iOS-Release |
| [ANDROID_SCREENSHOTS.md](ANDROID_SCREENSHOTS.md) | Android Play Store Screenshots | Vor Android-Release |

---

## Nachschlagen

Referenzdokumentation zum schnellen Nachschlagen.

| Dokument | Inhalt | Wann lesen? |
|----------|--------|-------------|
| [GLOSSARY.md](GLOSSARY.md) | Ubiquitous Language, Domain-Begriffe | Begriff unklar? |
| [COLOR_SYSTEM.md](COLOR_SYSTEM.md) | Semantische Farben, Design Tokens | Bei UI-Styling |
| [VIEW_NAMES.md](VIEW_NAMES.md) | Naming-Konventionen fuer Views | Neue View erstellen |

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
| [feature-concepts/](feature-concepts/) | Groessere Feature-Konzepte vor Umsetzung |

---

## Sonstiges

| Dokument | Inhalt |
|----------|--------|
| [WEBSITE.md](WEBSITE.md) | GitHub Pages Website-Struktur |

---

## Dokumentations-Konventionen

- **CLAUDE.md** im Root: Quick Reference fuer taegliche Arbeit
- **dev-docs/**: Ausfuehrliche Dokumentation
- **ADRs**: Signifikante Architekturentscheidungen in `decisions/`
- **Tickets**: Feature-Arbeit wird ueber `tickets/` getrackt

Bei neuen Dokumenten:
1. Passende Kategorie oben waehlen
2. In diese README.md eintragen
3. `Last Updated` Datum am Ende des Dokuments pflegen

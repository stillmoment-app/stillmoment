---
name: review-website
description: Prueft die GitHub Pages Website auf Aktualitaet, Uebersetzungen, rechtliche Anforderungen, Bildgroessen und SEO. Aktiviere bei Website-Updates, vor Releases, oder auf Anfrage.
---

# Website Review

Systematische Pruefung der Still Moment Website (`docs/`).

## Kernprinzip

**Fokus auf das Wesentliche.** 5 Checks, keine unnoetige Komplexitaet.

## Wann aktivieren

- "Review die Website"
- "Ist die Website aktuell?"
- "Pruefe die Support-Seite"
- Vor App Store Releases
- Nach Feature-Releases (neue Features = Website-Update)

## Website-Struktur

```
docs/
├── index.html        # Landing Page
├── support.html      # FAQs und Hilfe
├── privacy.html      # Datenschutzerklaerung
├── impressum.html    # Impressum (rechtlich erforderlich)
├── styles.css        # Gemeinsames Styling
├── _includes/        # Header, Footer (Jekyll)
└── images/
    ├── app-icon.png
    └── screenshots/  # Lokalisierte Screenshots
```

## Workflow

### Schritt 1: Dateien lesen

Alle relevanten Website-Dateien lesen:
- `docs/index.html`
- `docs/support.html`
- `docs/privacy.html`
- `docs/impressum.html`
- `docs/_includes/header.html`
- `docs/_includes/footer.html`

### Schritt 2: 5 Checks durchfuehren

1. **Inhalt-Sync** - `checklists/inhalt-sync.md`
   - Features auf Website entsprechen App-Features in CLAUDE.md
   - FAQs in support.html sind aktuell

2. **Uebersetzungen** - `checklists/uebersetzungen.md`
   - Alle `lang-en` Elemente haben `lang-de` Aequivalent
   - Keine fehlenden Uebersetzungen

3. **Rechtlich** - `checklists/rechtlich.md`
   - Impressum vorhanden und vollstaendig
   - Privacy Policy vorhanden
   - Kontakt-E-Mail erreichbar

4. **Bildgroessen** - `checklists/bildgroessen.md`
   - Screenshots < 200KB
   - Icons < 50KB
   - Keine uebergroessen Bilder

5. **SEO-Basics** - `checklists/seo-basics.md`
   - Meta-Tags vorhanden
   - Open Graph Tags korrekt
   - Titel aussagekraeftig

### Schritt 3: Report generieren

Report nach `templates/report.md`:
- Zusammenfassung
- Findings (nur wenn vorhanden)
- Empfehlungen

**Wenn alles OK:**
```
Website ist aktuell und erfuellt alle Anforderungen.
Keine Anmerkungen.
```

## Automatisierbare Checks

```bash
# Bildgroessen pruefen
du -sh docs/images/*
du -sh docs/images/screenshots/*

# Uebersetzungen zaehlen (sollten gleich sein)
grep -c "lang-en" docs/index.html
grep -c "lang-de" docs/index.html

# Links pruefen (optional)
grep -oP 'href="[^"]+' docs/*.html | grep -v "#"
```

## Referenzen

- `CLAUDE.md` - App-Features und Architektur
- `docs/` - Website-Dateien

# Still Moment Website

Marketing-Website für Still Moment (iOS + Android).

Für Dateistruktur: `ls docs/` verwenden.

## Lokale Entwicklung

### Voraussetzungen

- Ruby (Homebrew auf macOS)
- Bundler

### Setup (einmalig)

```bash
cd docs
/opt/homebrew/opt/ruby/bin/bundle install --path vendor/bundle
```

### Server starten

```bash
cd docs
bundle exec jekyll serve --port 4000
```

Website öffnen: http://127.0.0.1:4000

### Server stoppen

```bash
pkill -f "jekyll serve"
```

## Deployment

Push zu `main` → GitHub Pages baut automatisch.

**URL**: https://stillmoment-app.github.io/stillmoment/

### Nicht committen

- `docs/_site/`
- `docs/vendor/`
- `docs/.jekyll-cache/`

## Troubleshooting

### Jekyll nicht gefunden

```bash
/opt/homebrew/opt/ruby/bin/bundle exec jekyll serve
```

### Port belegt

```bash
bundle exec jekyll serve --port 4001
# oder
pkill -f "jekyll serve"
```

### Includes nicht aufgelöst

- Prüfen: `---` am Dateianfang vorhanden?
- Prüfen: `_includes/` Ordner existiert?

---

**Letztes Update**: 2026-01-10

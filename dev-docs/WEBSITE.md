# Still Moment Marketing Website

Die Marketing-Website für die Still Moment iOS App, gebaut mit Jekyll und optimiert für GitHub Pages.

## Features

✨ **Vollständige Marketing-Funktionen**:
- Hero Section mit App Icon und CTA
- Screenshot-Carousel mit iPhone-Mockups
- 6 animierte Feature-Cards
- Privacy-Banner (Datenschutz-Fokus)
- Footer mit Links und Kontaktinformationen

🌍 **Bilingualer Support**:
- Vollständiger Deutsch/Englisch Support
- Sprachumschalter im Header (EN/DE)
- localStorage speichert Sprachauswahl
- Automatisches Laden der gespeicherten Sprache

🎨 **Design**:
- Exakte App-Farbpalette (Terracotta, Warm Sand, etc.)
- SF Pro Rounded Typography
- Responsive Design (Mobile-First)
- Smooth Animationen und Transitions
- iPhone-Mockups mit Notch

🔧 **Technologie**:
- Jekyll für Template-Includes (Header, Footer)
- Gemeinsame CSS-Datei (`styles.css`)
- Vanilla JavaScript (keine Dependencies)
- GitHub Pages native Jekyll-Unterstützung

## Dateistruktur

```
docs/
├── _config.yml             # Jekyll-Konfiguration
├── _includes/              # Wiederverwendbare Komponenten
│   ├── header.html         # Header mit Logo + Sprachumschalter
│   └── footer.html         # Footer mit 3-Spalten Layout
├── index.html              # Haupt-Website
├── privacy.html            # Datenschutzerklärung
├── support.html            # Support & FAQ
├── impressum.html          # Impressum (Legal Notice)
├── styles.css              # Gemeinsame CSS-Styles
├── Gemfile                 # Ruby Dependencies
├── images/
│   ├── app-icon.png        # App Icon (1024x1024)
│   └── screenshots/        # App-Screenshots (DE + EN)
└── _site/                  # Generierte Website (nicht committen)
```

## Lokal entwickeln

### Voraussetzungen

- **Ruby** (macOS: Homebrew Ruby empfohlen)
- **Bundler** (wird mit Ruby installiert)

### Erste Einrichtung

```bash
cd docs

# Dependencies installieren (einmalig)
/opt/homebrew/opt/ruby/bin/bundle install --path vendor/bundle
```

### Website bauen und testen

```bash
cd docs

# Website bauen (ohne Server)
/opt/homebrew/opt/ruby/bin/bundle exec jekyll build

# ODER: Mit lokalem Server (empfohlen)
/opt/homebrew/opt/ruby/bin/bundle exec jekyll serve --port 4000
```

Öffne dann http://127.0.0.1:4000 im Browser.

### Kurzform (nach Einrichtung)

```bash
cd docs
bundle exec jekyll serve
```

### Server stoppen

```bash
pkill -f "jekyll serve"
```

## Jekyll Includes

Die Website verwendet Jekyll-Includes für konsistente Komponenten:

### Header (`_includes/header.html`)
```html
{% include header.html %}
```
- Logo mit Link zur Startseite
- Sprachumschalter (EN/DE Buttons)

### Footer (`_includes/footer.html`)
```html
{% include footer.html %}
```
- 3-Spalten Layout
- Links: Still Moment Info, Navigation, Kontakt
- Zweisprachig (DE/EN)

### Neue Seite erstellen

1. HTML-Datei mit Jekyll Front Matter erstellen:
```html
---
---
<!DOCTYPE html>
<html lang="en">
<head>
    ...
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    {% include header.html %}

    <div class="content">
        <!-- Seiteninhalt -->
    </div>

    {% include footer.html %}

    <script>
        // switchLanguage() Funktion hier
    </script>
</body>
</html>
```

2. Die leeren `---` am Anfang sind wichtig - sie aktivieren Jekyll-Processing.

## GitHub Pages Deployment

Die Website wird automatisch von GitHub Pages gebaut.

### Automatisches Deployment

1. **Push zu GitHub**:
   ```bash
   git add docs/
   git commit -m "docs: Update website"
   git push origin main
   ```

2. **GitHub Pages aktivieren** (nur beim ersten Mal):
   - Repository Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: `main`, Folder: `/docs`
   - Save

3. **Website ist live**:
   - URL: https://stillmoment-app.github.io/stillmoment/
   - Deployment dauert 1-2 Minuten

### Was nicht committen

Die folgenden Dateien/Ordner sind lokal und sollten nicht committed werden:

```gitignore
docs/_site/           # Generierte Website
docs/vendor/          # Ruby Dependencies
docs/.jekyll-cache/   # Jekyll Cache
docs/Gemfile.lock     # Lock-Datei (optional)
```

## Seiten

| Seite | Pfad | Beschreibung |
|-------|------|--------------|
| Startseite | `index.html` | Hero, Features, Screenshots |
| Privacy | `privacy.html` | Datenschutzerklärung |
| Support | `support.html` | FAQ & Hilfe |
| Impressum | `impressum.html` | Rechtliche Angaben |

## Farben & Design-System

```css
/* App-Farben */
--warm-cream: #FFF8F0;      /* Hintergrund */
--warm-sand: #F5E6D3;       /* Sekundärer Hintergrund */
--pale-apricot: #FFD4B8;    /* Gradient-Ende */
--terracotta: #D4876F;      /* Hauptakzent (Buttons, Links) */
--clay: #C97D60;            /* Hover-States */
--dusty-rose: #E8B4A0;      /* Soft Highlights */
--warm-black: #3D3228;      /* Text */
--warm-gray: #8B7D6B;       /* Sekundärer Text */
```

## Sprachumschaltung

Jede Seite benötigt die `switchLanguage()` Funktion im Script-Block:

```javascript
function switchLanguage(lang) {
    localStorage.setItem('preferredLanguage', lang);

    document.querySelectorAll('.language-switcher button').forEach(btn => {
        btn.classList.remove('active');
    });
    document.getElementById('lang-' + lang).classList.add('active');

    if (lang === 'en') {
        document.querySelectorAll('.lang-en').forEach(el => el.classList.remove('hidden'));
        document.querySelectorAll('.lang-de').forEach(el => el.classList.add('hidden'));
        document.documentElement.lang = 'en';
    } else {
        document.querySelectorAll('.lang-en').forEach(el => el.classList.add('hidden'));
        document.querySelectorAll('.lang-de').forEach(el => el.classList.remove('hidden'));
        document.documentElement.lang = 'de';
    }
}

document.addEventListener('DOMContentLoaded', function() {
    const savedLang = localStorage.getItem('preferredLanguage') || 'en';
    switchLanguage(savedLang);
});
```

## Troubleshooting

### Jekyll nicht gefunden
```bash
# Homebrew Ruby verwenden
/opt/homebrew/opt/ruby/bin/bundle exec jekyll serve
```

### Port bereits belegt
```bash
# Anderen Port verwenden
bundle exec jekyll serve --port 4001

# Oder alten Prozess beenden
pkill -f "jekyll serve"
```

### Includes werden nicht aufgelöst
- Prüfe, ob `---` am Anfang der HTML-Datei steht
- Prüfe, ob `_includes/` Ordner existiert

## Support & Fragen

- **Issues**: https://github.com/stillmoment-app/stillmoment/issues
- **Email**: stillMoment@posteo.de

---

**Letztes Update**: 2025-12-14
**Version**: 2.0 (Jekyll)
**Status**: ✅ Produktionsbereit

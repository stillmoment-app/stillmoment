# SEO-Basics

Grundlegende SEO-Anforderungen fuer Auffindbarkeit.

## Meta-Tags (head)

### Pflicht
```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="...">
<title>Still Moment - ...</title>
```

### Empfohlen
```html
<meta name="keywords" content="meditation, timer, iOS, ...">
<meta name="author" content="Helmut Zechmann">
<link rel="icon" type="image/png" href="images/app-icon.png">
```

## Open Graph Tags (Social Sharing)

Fuer Facebook, LinkedIn, etc.:
```html
<meta property="og:type" content="website">
<meta property="og:url" content="https://stillmoment-app.github.io/stillmoment/">
<meta property="og:title" content="Still Moment - ...">
<meta property="og:description" content="...">
<meta property="og:image" content=".../app-icon.png">
```

## Twitter Cards

Fuer Twitter/X:
```html
<meta property="twitter:card" content="summary_large_image">
<meta property="twitter:url" content="...">
<meta property="twitter:title" content="...">
<meta property="twitter:description" content="...">
<meta property="twitter:image" content="...">
```

## Pruefung

### Automatisch
```bash
# Meta-Tags in index.html zaehlen
grep -c '<meta' docs/index.html

# Open Graph Tags pruefen
grep 'og:' docs/index.html

# Twitter Tags pruefen
grep 'twitter:' docs/index.html
```

### Manuell
- [ ] Titel ist aussagekraeftig (nicht nur "Still Moment")
- [ ] Description enthaelt Keywords
- [ ] og:image zeigt auf existierende Datei
- [ ] URLs sind korrekt (https://stillmoment-app.github.io/stillmoment/)

## Alle Seiten pruefen

Jede HTML-Seite braucht mindestens:
- [ ] index.html - Alle Tags
- [ ] support.html - Basis-Tags + eigener Titel
- [ ] privacy.html - Basis-Tags + eigener Titel
- [ ] impressum.html - Basis-Tags + eigener Titel

## Melden wenn

- Meta description fehlt
- Title ist generisch oder fehlt
- Open Graph Tags fehlen (index.html)
- og:image URL ist falsch
- Viewport Meta fehlt

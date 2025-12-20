# Bildgroessen

Bilder muessen fuer Web optimiert sein.

## Grenzwerte

| Bildtyp | Max. Groesse | Format |
|---------|--------------|--------|
| App-Icon | 50 KB | PNG |
| Screenshots | 200 KB | PNG |
| Sonstige | 100 KB | PNG/JPG |

## Automatischer Check

```bash
# Alle Bilder mit Groesse
du -sh docs/images/*
du -sh docs/images/screenshots/*

# Detailliert (Bytes)
ls -la docs/images/
ls -la docs/images/screenshots/

# Groesste Dateien finden
find docs/images -type f -exec du -h {} \; | sort -hr | head -10
```

## Aktuelle Situation (Stand: Analyse)

| Datei | Groesse | Status |
|-------|---------|--------|
| app-icon.png | 394 KB | ZU GROSS (max 50 KB) |
| screenshots/ | 25 MB total | ZU GROSS |

## Optimierungsvorschlaege

### App-Icon
```bash
# Auf 512px verkleinern (reicht fuer Web)
sips -Z 512 docs/images/app-icon.png --out docs/images/app-icon-optimized.png

# Oder mit ImageOptim/TinyPNG komprimieren
```

### Screenshots
```bash
# Breite auf 750px reduzieren (iPhone-Breite reicht)
sips -Z 750 docs/images/screenshots/*.png

# Danach mit ImageOptim oder TinyPNG weiter komprimieren
```

## Melden wenn

- Einzelbild > 200 KB
- App-Icon > 50 KB
- Gesamt-Bildordner > 5 MB
- Bilder nicht optimiert (PNG ohne Kompression)

## Tools zur Optimierung

- **sips** (macOS built-in) - Groesse aendern
- **ImageOptim** (macOS App) - Verlustfreie Kompression
- **TinyPNG** (Web) - Starke Kompression
- **squoosh.app** (Web) - Moderne Formate (WebP)

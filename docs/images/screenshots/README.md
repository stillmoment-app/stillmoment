# Screenshots für Still Moment Website

Diese Anleitung beschreibt, wie du Screenshots der App für die Marketing-Website erstellst.

## Benötigte Screenshots

Die Website erwartet folgende Screenshots in **beiden Sprachen** (Deutsch und Englisch):

### Englische Screenshots (EN)
1. `timer-ready-en.png` - Timer in Ready State
2. `timer-running-en.png` - Timer während Meditation läuft
3. `library-en.png` - Guided Meditations Library
4. `player-en.png` - Audio Player Ansicht

### Deutsche Screenshots (DE)
1. `timer-ready-de.png` - Timer in Bereit-Zustand
2. `timer-running-de.png` - Timer während Meditation läuft
3. `library-de.png` - Bibliothek für geführte Meditationen
4. `player-de.png` - Audio Player Ansicht

## Schritt-für-Schritt Anleitung

### 1. Simulator vorbereiten

```bash
# iPhone 16 Pro Simulator öffnen
open -a Simulator

# App bauen und im Simulator starten
xcodebuild -project StillMoment.xcodeproj \
  -scheme StillMoment \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  build

# App im Simulator installieren (Output-Pfad aus Build-Logs verwenden)
xcrun simctl install booted /path/to/StillMoment.app
xcrun simctl launch booted com.stillmoment.StillMoment
```

### 2. Englische Screenshots erstellen

```bash
# Systemsprache auf Englisch setzen
xcrun simctl spawn booted defaults write .GlobalPreferences AppleLanguages -array en

# Simulator neu starten
xcrun simctl shutdown booted
xcrun simctl boot booted
xcrun simctl launch booted com.stillmoment.StillMoment
```

**Screenshots machen:**

1. **Timer Ready** (`timer-ready-en.png`):
   - App öffnen
   - Timer Tab
   - Ready State (z.B. mit 20 Minuten)
   - Cmd+S oder Screenshot-Tool verwenden

2. **Timer Running** (`timer-running-en.png`):
   - Timer starten
   - Während Meditation läuft (z.B. 15:30 verbleibend)
   - Screenshot machen

3. **Library** (`library-en.png`):
   - Zum Library Tab wechseln
   - Mit einigen importierten Meditationen
   - Screenshot machen

4. **Player** (`player-en.png`):
   - Eine Meditation abspielen
   - Player-Ansicht
   - Screenshot machen

### 3. Deutsche Screenshots erstellen

```bash
# Systemsprache auf Deutsch setzen
xcrun simctl spawn booted defaults write .GlobalPreferences AppleLanguages -array de

# Simulator neu starten
xcrun simctl shutdown booted
xcrun simctl boot booted
xcrun simctl launch booted com.stillmoment.StillMoment
```

Wiederhole die gleichen Screenshots wie oben, aber mit deutscher Sprache.

### 4. Alternative: Manuell im Simulator

1. Simulator öffnen
2. **Settings** → **General** → **Language & Region** → **iPhone Language**
3. Sprache zu **English** oder **Deutsch** ändern
4. App öffnen und Screenshots machen:
   - **Cmd + S** für Screenshot
   - Oder **Simulator** → **File** → **Save Screen**

### 5. Screenshots in richtiges Verzeichnis kopieren

```bash
# Screenshots vom Desktop verschieben
mv ~/Desktop/Simulator\ Screenshot*.png docs/images/screenshots/

# Umbenennen entsprechend der Konvention
mv "Simulator Screenshot 1.png" timer-ready-en.png
mv "Simulator Screenshot 2.png" timer-running-en.png
# etc.
```

## Screenshot-Spezifikationen

- **Format**: PNG
- **Gerät**: iPhone 16 Pro (oder ähnlich)
- **Orientation**: Portrait
- **Auflösung**: Native Simulator-Auflösung (wird automatisch skaliert)
- **Dateigröße**: Optimieren für Web (<500KB pro Bild empfohlen)

## Bildoptimierung (optional)

```bash
# Mit ImageOptim (falls installiert)
imageoptim docs/images/screenshots/*.png

# Oder mit pngquant
pngquant --quality=65-80 docs/images/screenshots/*.png
```

## Website aktualisieren

Sobald die Screenshots im `docs/images/screenshots/` Verzeichnis sind, wird die Website sie automatisch anzeigen. Die Platzhalter-Texte verschwinden automatisch, wenn die Bilder geladen werden.

## Testen

Öffne `docs/index.html` in einem Browser und überprüfe:
- ✅ Alle Screenshots laden korrekt
- ✅ Sprachumschaltung (EN/DE) zeigt die richtigen Screenshots
- ✅ iPhone-Mockups sehen professionell aus
- ✅ Keine Platzhalter-Texte mehr sichtbar

## Troubleshooting

**Problem**: Screenshots sind zu groß
- **Lösung**: Verwende Bildoptimierungs-Tools wie ImageOptim oder TinyPNG

**Problem**: Falsche Sprache im Screenshot
- **Lösung**: Überprüfe Simulator-Spracheinstellungen und App neu starten

**Problem**: Screenshots werden nicht angezeigt
- **Lösung**: Überprüfe Dateinamen (exakt wie oben angegeben) und Pfade

---

**Letztes Update**: 2025-11-09

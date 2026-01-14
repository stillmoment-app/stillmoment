# Fastlane Android - Setup & Verwendung

Automatisierte Screenshots und Play Store Uploads mit Fastlane.

## Voraussetzungen

- Ruby (via rbenv)
- Android SDK
- Google Play Service Account

## Service Account einrichten (einmalig)

### 1. Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) öffnen
2. Projekt auswählen oder neues erstellen
3. **APIs & Services** → **Bibliothek**
4. "Google Play Android Developer API" suchen und aktivieren
5. **APIs & Services** → **Anmeldedaten**
6. **Anmeldedaten erstellen** → **Dienstkonto**
7. Name: z.B. "stillmoment-fastlane"
8. **Erstellen und fortfahren** (keine Rollen nötig)
9. **Fertig**

### 2. JSON Key herunterladen

1. Auf das erstellte Dienstkonto klicken
2. **Schlüssel** Tab → **Schlüssel hinzufügen** → **Neuen Schlüssel erstellen**
3. Format: **JSON**
4. Datei speichern als: `~/.fastlane/stillmoment-play-console.json`

### 3. Play Console konfigurieren

1. [Google Play Console](https://play.google.com/console/) öffnen
2. **Nutzer und Berechtigungen** → **Nutzer einladen**
3. E-Mail-Adresse des Service Accounts eingeben (aus JSON-Datei)
4. Berechtigungen:
   - **App-Zugriff**: "Still Moment" auswählen
   - **Kontoberechtigungen**: Keine
   - **App-Berechtigungen**: "Releases verwalten" aktivieren
5. **Einladung senden**

## Installation

```bash
cd android
make screenshot-setup    # Ruby + Fastlane installieren
```

## Verwendung

### Screenshots generieren

```bash
make screenshots         # Alle Screenshots (DE + EN)
```

### Release zu Closed Testing

```bash
make release-dry         # Validierung ohne Upload
make release             # Upload zu Closed Testing
```

### Nur Metadata aktualisieren

```bash
make metadata            # Beschreibungen + Changelogs
```

### Production Release

```bash
make release-production  # Mit Bestätigung
```

## Verzeichnisstruktur

```
android/fastlane/
├── Appfile              # Package Name + Service Account
├── Fastfile             # Lane-Definitionen
├── Screengrabfile       # Screenshot-Konfiguration
└── metadata/
    └── android/
        ├── de-DE/
        │   ├── title.txt
        │   ├── short_description.txt
        │   ├── full_description.txt
        │   └── changelogs/
        │       └── default.txt
        └── en-US/
            └── ... (analog)
```

## Changelogs

Für versionsspezifische Changelogs:

```
changelogs/
├── default.txt          # Fallback für alle Versionen
├── 10.txt               # Für versionCode 10
└── 11.txt               # Für versionCode 11
```

## CI/CD Integration

Für GitHub Actions, Service Account JSON als Secret:

```yaml
env:
  SUPPLY_JSON_KEY: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
```

## Troubleshooting

### "Google Api Error: forbidden"

- Service Account hat keine Berechtigungen in Play Console
- Prüfen: Play Console → Nutzer und Berechtigungen

### "App not found"

- Erste App-Version muss manuell hochgeladen werden
- Package Name in Appfile prüfen

### "Invalid request - Invalid package name"

- Package Name stimmt nicht mit Play Console überein
- `com.stillmoment` in Appfile prüfen

## Referenzen

- [Fastlane supply](https://docs.fastlane.tools/actions/supply/)
- [Google Play API Setup](https://docs.fastlane.tools/actions/supply/#setup)

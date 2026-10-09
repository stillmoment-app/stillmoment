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

### 4. Upload-Keystore

`android/keystore.properties` (gitignored) mit `storeFile`, `storePassword`, `keyAlias`,
`keyPassword`. `storeFile` ist relativ zu `android/app/`. Ohne die Datei signiert
`bundleRelease` mit dem Debug-Key — `release-prepare` bricht deshalb ab, wenn sie oder die
Keystore-Datei fehlt.

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

### Release in den Play Store

Ablauf (release-prepare, Testplan, Guard): `dev-docs/release/RELEASE_GUIDE.md`.

```bash
make release-dry                          # bundleRelease + Validierung gegen die Play API, kein Upload
make release VERSION=1.9.0                # Guard, bundleRelease, Upload in den Production-Track
make release-production VERSION=1.9.0     # wie release, mit Bestätigungsfrage
```

`VERSION` ist Pflicht: `scripts/release/release-guard.sh` prüft vorher Tag, `versionName`,
sauberen Arbeitsbaum und Screenshots.

`make release` lädt App-Bundle, Metadaten, Changelogs und Screenshots in den **Production**-Track.
`supply` wird ohne `release_status` aufgerufen; fastlane-Default ist `completed`: Das Release geht
direkt in Googles Prüfung und nach Freigabe an alle Nutzer — keine gestaffelte Auslieferung.
Ausnahme: In der Play Console ist „Verwaltete Veröffentlichung“ aktiv, dann wartet die Freigabe auf
einen Klick. Deshalb gehört der Testplan **vor** den Upload.

### Nur Metadata / Screenshots aktualisieren

```bash
make metadata            # Beschreibungen + Changelogs, ohne Build
make screenshots-upload  # Nur Screenshots, ohne Build
```

`make metadata` aktualisiert den Changelog des Releases mit dem `versionCode` aus
`app/build.gradle.kts` (also dem zuletzt vorbereiteten Release); anderes Release über
`make metadata VERSION_CODE=19`. Ohne `versionCode` bricht supply ab („no version code given“).
Existiert im Track kein Release mit diesem `versionCode`, meldet supply das ebenfalls.

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
        │       └── 21.txt       # je versionCode
        └── en-US/
            └── ... (analog)
```

## Changelogs

Release Notes liegen je Sprache in `changelogs/<versionCode>.txt` (max. 500 Zeichen) und werden
von `/release-notes` geschrieben. `release-prepare` erwartet die Datei für den *nächsten*
`versionCode` (aktueller + 1, den `bump-version.sh` setzt).

Bewusst **kein** `default.txt`: supply nimmt es als Fallback, wenn für den versionCode keine
eigene Datei existiert. Im Release-Prozess erzwingt der Preflight die passende Datei, der Fallback
würde also nur greifen, wenn sie fehlt — und dann veralteten Text veröffentlichen statt aufzufallen.

## CI/CD Integration

`SUPPLY_JSON_KEY` ist im Appfile der **Pfad** zur JSON-Datei, nicht ihr Inhalt. In GitHub Actions
also das Secret erst in eine Datei schreiben:

```yaml
env:
  SUPPLY_JSON_KEY: /tmp/stillmoment-play-console.json

steps:
  - name: Setup Play Console key
    run: echo '${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}' > /tmp/stillmoment-play-console.json
```

(Releases laufen derzeit nur lokal; CI baut nur ohne Upload.)

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

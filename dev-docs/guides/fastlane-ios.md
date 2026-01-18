# Fastlane iOS - Setup & Verwendung

Automatisierte Screenshots und App Store Connect Uploads mit Fastlane.

## Voraussetzungen

- Ruby (via rbenv)
- Xcode
- App Store Connect API Key

## API Key einrichten (einmalig)

### 1. App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com/) oeffnen
2. **Benutzer und Zugriff** → **Integrationen** → **App Store Connect API**
3. **Schlussel generieren** klicken
4. Name: z.B. "stillmoment-fastlane"
5. Zugriff: **App Manager** (oder hoeher)
6. **Generieren** klicken
7. **Key ID** und **Issuer ID** notieren
8. `.p8` Datei herunterladen (nur einmal moeglich!)

### 2. API Key konfigurieren

```bash
# 1. .p8 Datei kopieren
cp ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.fastlane/stillmoment-appstore.p8
chmod 600 ~/.fastlane/stillmoment-appstore.p8

# 2. Umgebungsvariablen setzen
export APP_STORE_CONNECT_KEY_ID='DEIN_KEY_ID'
export APP_STORE_CONNECT_ISSUER_ID='deine-issuer-id-hier'

# 3. JSON-Datei generieren (Script konvertiert .p8 zu JSON)
cd ios && ./scripts/create-api-key-json.sh
```

**Tipp**: Umgebungsvariablen in `~/.zshrc` oder `~/.bashrc` dauerhaft setzen.

## Installation

```bash
cd ios
make screenshot-setup    # Ruby + Fastlane installieren
```

## Verwendung

### Metadata herunterladen

Beim ersten Setup die aktuellen Metadaten vom App Store holen:

```bash
make metadata-download   # Laedt name.txt, description.txt, etc.
```

### Screenshots generieren

```bash
make screenshots              # Alle Screenshots (DE + EN), headless
HEADLESS=false make screenshots  # Mit sichtbarem Simulator (zum Debugging)
```

Der `HEADLESS`-Modus ist standardmaessig aktiviert (Simulator im Hintergrund).
Setze `HEADLESS=false` um den Simulator waehrend der Tests zu beobachten.

### Release zu App Store Connect

```bash
make release-dry                  # Validierung ohne Upload
make release VERSION=1.9.0        # Build + Upload zu App Store Connect
make release VERSION=1.9.0 SKIP_BUILD=1  # Nur Metadata + Screenshots
```

### TestFlight Upload

```bash
make testflight          # Build + Upload zu TestFlight
```

## Verzeichnisstruktur

```
ios/fastlane/
├── Appfile              # Bundle ID
├── Deliverfile          # Upload-Konfiguration
├── Fastfile             # Lane-Definitionen
├── Snapfile             # Screenshot-Konfiguration
├── metadata/
│   ├── app_rating_config.json
│   ├── de-DE/
│   │   ├── name.txt
│   │   ├── subtitle.txt
│   │   ├── description.txt
│   │   ├── keywords.txt
│   │   ├── promotional_text.txt
│   │   ├── release_notes.txt
│   │   └── changelogs/
│   │       └── 1.9.0.txt
│   └── en-GB/
│       └── ... (analog)
└── screenshots/
    ├── de-DE/
    │   └── iPhone 17 Pro Max-*.png
    └── en-GB/
        └── ... (analog)
```

## Release Notes / Changelogs

Release Notes werden aus `metadata/<locale>/release_notes.txt` gelesen.

Fuer versionsspezifische Changelogs kann auch `changelogs/<version>.txt` verwendet werden:

```
changelogs/
├── 1.8.0.txt
└── 1.9.0.txt
```

## Binary Upload

**Wichtig**: Fastlane deliver laedt standardmaessig nur Metadata und Screenshots hoch.

Fuer den Binary-Upload gibt es zwei Optionen:

1. **TestFlight** (empfohlen):
   ```bash
   make testflight
   ```

2. **Manuell via Xcode/Transporter**:
   - In Xcode: Product → Archive → Distribute App
   - Oder: Transporter App verwenden

## CI/CD Integration

Fuer GitHub Actions mit JSON-Secret:

```yaml
env:
  APP_STORE_CONNECT_API_KEY_PATH: /tmp/stillmoment-appstore.json

steps:
  - name: Setup API Key
    run: |
      echo '${{ secrets.APP_STORE_CONNECT_API_KEY_JSON }}' > /tmp/stillmoment-appstore.json
```

Oder mit separaten Secrets:

```yaml
env:
  APP_STORE_CONNECT_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
  APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
  APP_STORE_CONNECT_API_KEY_PATH: /tmp/stillmoment-appstore.p8

steps:
  - name: Setup API Key
    run: |
      echo '${{ secrets.APP_STORE_CONNECT_P8_KEY }}' > /tmp/stillmoment-appstore.p8
```

## Screenshot-Performance optimieren

Die Fastlane `snapshot()` Funktion hat versteckte Zeitfresser die Screenshots
um bis zu 21 Sekunden verzoegern koennen.

### Problemstellung: SnapshotHelper.swift

```swift
// In SnapshotHelper.swift (Fastlane-generiert)
open class func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    if timeout > 0 {
        self.waitForLoadingIndicatorToDisappear(within: timeout)  // Bis zu 20s!
    }
    if Snapshot.waitForAnimations {
        sleep(1)  // Harter 1s Sleep
    }
    // ... Screenshot erstellen
}
```

**Zeitfresser:**
| Parameter | Default | Auswirkung |
|-----------|---------|------------|
| `timeWaitingForIdle` | 20s | Wartet auf Network Loading Indicator in Statusbar |
| `waitForAnimations` | true | Pauschaler `sleep(1)` vor jedem Screenshot |

### Loesung

**1. setUp konfigurieren:**
```swift
override func setUpWithError() throws {
    // waitForAnimations: false - wir warten explizit mit waitForExistence
    setupSnapshot(self.app, waitForAnimations: false)
}
```

**2. snapshot() mit timeWaitingForIdle: 0 aufrufen:**
```swift
// Statt:
snapshot("01_TimerIdle")

// Besser:
snapshot("01_TimerIdle", timeWaitingForIdle: 0)
```

**3. Explizit auf UI-Elemente warten (statt Thread.sleep):**
```swift
// Schlecht: Harter Sleep
Thread.sleep(forTimeInterval: 0.3)
XCTAssertTrue(element.exists)

// Gut: Intelligentes Warten
XCTAssertTrue(element.waitForExistence(timeout: 2.0))
```

### Ergebnis

| Messung | Vorher | Nachher |
|---------|--------|---------|
| snapshot() Aufruf | ~2.3s (bis 20s!) | ~0.2s |
| Timer-Screenshot | 04:47 (13s vergangen) | 04:59 (1s vergangen) |

## Troubleshooting

### "App Store Connect API key not configured"

Option A (.p8 Datei):
- Datei vorhanden? `ls ~/.fastlane/stillmoment-appstore.p8`
- Umgebungsvariablen gesetzt? `echo $APP_STORE_CONNECT_KEY_ID`

Option B (JSON):
- Datei vorhanden? `ls ~/.fastlane/stillmoment-appstore.json`
- JSON valide? `cat ~/.fastlane/stillmoment-appstore.json | jq .`

### "Invalid API Key"

- Key ID und Issuer ID pruefen (App Store Connect → Integrationen)
- Key in App Store Connect noch aktiv?
- Bei JSON: `.p8` Inhalt korrekt eingebettet? (einzeilig mit `\n`)

### "No App Store Connect API Key provided"

- Fastfile api_key() Funktion pruefen
- Entweder .p8 + Umgebungsvariablen ODER JSON-Datei konfigurieren

### "App not found"

- Bundle ID pruefen: `com.stillmoment.StillMoment`
- App muss in App Store Connect existieren

### "Missing required metadata"

- `make metadata-download` ausfuehren
- Oder fehlende Dateien manuell erstellen

## Code Signing

iOS Apps muessen mit einem Apple-Zertifikat und Provisioning Profile signiert werden.
Es gibt drei gaengige Ansaetze:

### Optionen

| Ansatz | Beschreibung | Anwendungsfall |
|--------|--------------|----------------|
| **Xcode Automatic** | Xcode verwaltet Zertifikate automatisch | Lokale Entwicklung, Solo-Entwickler |
| **Manuelles Signing** | Zertifikate exportieren, als CI-Secrets hinterlegen | Einfache CI-Pipelines |
| **Fastlane Match** | Zertifikate in privatem Git-Repo synchronisiert | Teams, komplexe CI/CD |

### Was ist Fastlane Match?

Match ist ein Fastlane-Tool das Code Signing fuer Teams vereinfacht:

1. Erstellt Zertifikate und Provisioning Profiles
2. Speichert sie verschluesselt in einem privaten Git-Repo
3. Alle Teammitglieder und CI-Server klonen das Repo
4. Zertifikate werden automatisch installiert und aktualisiert

**Vorteile:**
- Ein Satz Zertifikate fuer alle (keine Konflikte)
- CI-Server brauchen nur Git-Zugang + Passwort
- Automatische Erneuerung

**Nachteile:**
- Zusaetzliches privates Git-Repo noetig
- Einrichtungsaufwand
- Overkill fuer Solo-Entwickler

### Entscheidung: Xcode Automatic Signing

Fuer Still Moment wird **Xcode Automatic Signing** verwendet:

- Solo-Entwickler, kein Team-Sync noetig
- Releases werden lokal erstellt (kein CI-Build)
- Kein zusaetzlicher Einrichtungsaufwand

**Spaeter evaluieren:** Wenn CI/CD automatisierte Releases implementiert werden (shared-028),
wird Match erneut evaluiert. Bis dahin ist Xcode Automatic die einfachste Loesung.

## Referenzen

- [Fastlane deliver](https://docs.fastlane.tools/actions/deliver/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Fastlane match](https://docs.fastlane.tools/actions/match/) (optional)

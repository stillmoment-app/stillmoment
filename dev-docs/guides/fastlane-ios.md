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

Die Umgebungsvariablen braucht nur dieses Script. Fastlane (`api_key` im Fastfile) und
`release-prepare` lesen ausschliesslich die JSON-Datei: `APP_STORE_CONNECT_API_KEY_PATH`, sonst
`~/.fastlane/stillmoment-appstore.json`.

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

Ablauf (release-prepare, Guard, Testplan, Einreichen): `dev-docs/release/RELEASE_GUIDE.md`.

```bash
make release-dry                         # API-Key, Metadaten-Dateien, Screenshots vorhanden? Kein Upload
make release VERSION=1.9.0               # Guard, Build, Upload nach TestFlight + Metadaten/Screenshots
make release VERSION=1.9.0 SKIP_BUILD=1  # Guard, nur Metadaten + Screenshots
make testflight                          # Nur Build nach TestFlight (ohne Guard, ohne Versions-Bump)
```

`make release` (Lane `release`):

- reicht **nicht** zur Pruefung ein (`submit_for_review: false`) — das passiert manuell in
  App Store Connect, nach dem Testplan mit dem TestFlight-Build
- `automatic_release: true` — nach Apples Freigabe geht die Version sofort live
- `phased_release: false` — keine 7-taegige gestaffelte Veroeffentlichung, alle Nutzer auf einmal

`make testflight` ist fuer den Release nicht noetig, weil `make release` den Build ebenfalls nach
TestFlight laedt. Beide Lanes bauen ueber dieselbe Methode `build_release_ipa` im Fastfile
(gleiche Provisioning Profiles fuer App und Share Extension, IPA unter `ios/build/StillMoment.ipa`).

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

`/release-notes` schreibt `metadata/<locale>/changelogs/<version>.txt`. `make release-prepare`
kopiert diese Datei nach `metadata/<locale>/release_notes.txt` — die liest `deliver` beim Upload.

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

Eine `.p8`-Datei direkt in `APP_STORE_CONNECT_API_KEY_PATH` funktioniert nicht — das Fastfile
parst die Datei als JSON. (Releases laufen derzeit nur lokal; CI baut nur ohne Upload.)

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

### "App Store Connect API key not found"

- JSON vorhanden? `ls ~/.fastlane/stillmoment-appstore.json` (bzw. Pfad aus `APP_STORE_CONNECT_API_KEY_PATH`)
- JSON valide? `jq . ~/.fastlane/stillmoment-appstore.json`
- Fehlt sie: mit `./scripts/create-api-key-json.sh` aus der `.p8` erzeugen (siehe oben)

### "Invalid API Key"

- Key ID und Issuer ID pruefen (App Store Connect → Integrationen)
- Key in App Store Connect noch aktiv?
- Bei JSON: `.p8` Inhalt korrekt eingebettet? (einzeilig mit `\n`)

### "No App Store Connect API Key provided"

- Fastfile `api_key()` pruefen — jede Upload-Lane muss sie zuerst aufrufen
- Konfiguriert wird nur ueber die JSON-Datei (siehe oben)

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

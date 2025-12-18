# Ticket ios-008: Domain-Layer SPM-Extraktion

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Hoch (~8-12h)
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Beschreibung

Extraktion der Domain-Schicht in ein separates Swift Package (SPM), damit
Unit-Tests ohne iOS-Simulator laufen koennen. Aktuell dauern Unit-Tests
~42s, obwohl die reine Testausfuehrung nur ~5.7s betraegt. Der Overhead
kommt vom Simulator-Start.

**Ziel**: Domain-Tests in <5s statt 42s ausfuehren.

---

## Akzeptanzkriterien

### Phase 1: Analyse
- [ ] Alle Domain-Dateien identifizieren (keine iOS-Imports)
- [ ] Abhaengigkeiten zwischen Domain und Infrastructure dokumentieren
- [ ] Tests kategorisieren (Simulator-noetig vs. reine Logik)

### Phase 2: SPM Package erstellen
- [ ] `StillMomentCore` Package erstellen
- [ ] Domain/Models/ in Package verschieben
- [ ] Domain/Services/ (Protocols) in Package verschieben
- [ ] Package.swift mit korrekten Targets konfigurieren

### Phase 3: Tests migrieren
- [ ] Reine Logik-Tests in Package verschieben
- [ ] Mock-Klassen in Package-Tests duplizieren/verschieben
- [ ] Sicherstellen dass Package-Tests ohne Simulator laufen

### Phase 4: Integration
- [ ] App importiert `StillMomentCore`
- [ ] Bestehende App-Tests funktionieren weiterhin
- [ ] CI Pipeline anpassen (Package-Tests separat)

### Dokumentation
- [ ] CLAUDE.md mit neuer Architektur aktualisieren
- [ ] Makefile-Targets fuer Package-Tests hinzufuegen

---

## Betroffene Dateien

### Zu verschieben (Domain - keine iOS-Imports):

```
StillMoment/Domain/Models/
├── MeditationTimer.swift        ✓ Reine Logik
├── MeditationSettings.swift     ✓ Reine Logik
├── TimerState.swift             ✓ Reine Logik
├── GuidedMeditation.swift       ✓ Reine Logik
├── AudioMetadata.swift          ✓ Reine Logik
└── BackgroundSound.swift        ✓ Reine Logik

StillMoment/Domain/Services/
├── AudioSessionCoordinatorProtocol.swift  ✓ Protocol
├── AudioServiceProtocol.swift             ✓ Protocol
├── TimerServiceProtocol.swift             ✓ Protocol
└── GuidedMeditationServiceProtocol.swift  ✓ Protocol
```

### Tests zu migrieren:

```
StillMomentTests/
├── MeditationTimerTests.swift           ✓ Reine Logik
├── AutocompleteTextFieldTests.swift     ✓ Reine Logik
├── TimerViewModel/*BasicTests.swift     ~ Teilweise (Combine)
└── Mocks/Mock*.swift                    ✓ Protocol-Mocks
```

### Verbleiben in App (brauchen iOS-APIs):

```
StillMomentTests/
├── AudioServiceTests.swift              ✗ AVFoundation
├── AudioPlayerServiceTests.swift        ✗ AVFoundation
├── AudioSessionCoordinatorTests.swift   ✗ AVAudioSession
├── BackgroundSoundRepositoryTests.swift ✗ Bundle.main
├── GuidedMeditationServiceTests.swift   ✗ FileManager
└── TimerServiceTests.swift              ✗ Timer (Foundation OK)
```

---

## Technische Details

### Ziel-Struktur

```
stillmoment/
├── ios/
│   ├── StillMoment/              # App
│   │   ├── Application/
│   │   ├── Infrastructure/
│   │   └── Presentation/
│   ├── StillMomentTests/         # Integration Tests (Simulator)
│   ├── StillMomentUITests/       # UI Tests (Simulator)
│   └── StillMoment.xcodeproj
│
├── Packages/
│   └── StillMomentCore/          # NEU: Swift Package
│       ├── Sources/
│       │   └── StillMomentCore/
│       │       ├── Models/
│       │       └── Services/
│       ├── Tests/
│       │   └── StillMomentCoreTests/  # Laufen OHNE Simulator!
│       └── Package.swift
```

### Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StillMomentCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)  // Ermoeglicht Tests auf Mac
    ],
    products: [
        .library(name: "StillMomentCore", targets: ["StillMomentCore"])
    ],
    targets: [
        .target(name: "StillMomentCore"),
        .testTarget(
            name: "StillMomentCoreTests",
            dependencies: ["StillMomentCore"]
        )
    ]
)
```

### Makefile-Erweiterung

```makefile
# Schnelle Domain-Tests (ohne Simulator)
test-core:
	cd ../Packages/StillMomentCore && swift test

# Alle Tests (Core + App + UI)
test-all: test-core test
```

### Erwartete Zeiten nach Migration

| Test-Kategorie | Vorher | Nachher |
|----------------|--------|---------|
| Domain (Core) | 42s | **<3s** |
| Infrastructure | - | ~30s |
| UI Tests | ~99s | ~99s |
| **Gesamt** | 144s | ~132s |

**Entwickler-Workflow-Verbesserung**: TDD-Zyklus mit Domain-Tests in 3s statt 42s.

---

## Risiken und Mitigationen

| Risiko | Mitigation |
|--------|------------|
| Zirkulaere Abhaengigkeiten | Domain hat KEINE Abhaengigkeiten (by design) |
| Doppelte Mock-Klassen | Mocks in Package, App-Tests importieren Package |
| CI-Komplexitaet | Separater Job fuer Package-Tests |
| Xcode-Projekt-Umstellung | SPM-Integration ist standard seit Xcode 11 |

---

## Testanweisungen

```bash
# Nach Migration: Schnelle Domain-Tests
cd Packages/StillMomentCore
swift test  # Erwartet: <3s

# App-Tests (weiterhin mit Simulator)
cd ios
make test-unit  # Erwartet: ~30s (reduziert)

# Alle Tests
make test-all
```

---

## Referenzen

- [Apple: Creating a Swift Package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode)
- [Swift Package Manager](https://www.swift.org/package-manager/)
- ios-003 Analyse-Bericht: [ios-test-analysis-report.md](../../ios-test-analysis-report.md)

---

## Abhaengige Tickets

Dieses Ticket ermoeglicht:
- Schnellere TDD-Zyklen
- Bessere Architektur-Trennung
- Potenzielle Code-Sharing mit anderen Targets (Widgets, Watch)

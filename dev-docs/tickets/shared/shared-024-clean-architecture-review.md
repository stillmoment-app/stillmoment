# Ticket shared-024: Clean Architecture Layer-Review

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~M | Android ~M
**Phase**: 2-Architektur

---

## Was

Systematisches Review der Layer-Abhängigkeiten in beiden Codebases, um Clean Architecture Verletzungen zu identifizieren und zu dokumentieren.

## Warum

Über die Zeit können sich unbeabsichtigt Abhängigkeiten einschleichen, die gegen die Architektur-Regeln verstoßen:
- Domain importiert Framework-Code
- ViewModels (Application) nutzen direkte Infrastruktur (Timer, FileManager, UserDefaults)
- Presentation enthält Business-Logik

Ein Review deckt diese auf und erstellt ggf. Follow-up-Tickets für kritische Verstöße.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Review (beide Plattformen)
- [x] Domain Layer: Keine Imports von Foundation/UIKit/SwiftUI (iOS) bzw. Android-Framework (Android)
- [x] Application Layer: Keine direkten Timer-, FileManager-, UserDefaults-Aufrufe
- [x] Presentation Layer: Keine Business-Logik, nur UI-Binding
- [x] Infrastructure Layer: Implementiert Domain-Protokolle, keine zirkulären Abhängigkeiten
- [x] Ergebnis dokumentiert mit Liste der Verstöße und Empfehlungen

### Dokumentation
- [x] Review-Ergebnis in Ticket-Kommentar oder separatem Dokument
- [x] Follow-up-Tickets für kritische Verstöße (falls nötig)

---

## Review-Checkliste

### Domain Layer prüfen
```
Erlaubt: Swift/Kotlin Standard-Library, eigene Domain-Types
Verboten: Foundation (außer basics), UIKit, SwiftUI, Combine, Android SDK
```

### Application Layer prüfen
```
Erlaubt: Domain-Imports, Combine/Flow für Reactive
Verboten: Direkte Timer, FileManager, UserDefaults, Netzwerk-Calls
```

### Presentation Layer prüfen
```
Erlaubt: SwiftUI/Compose, ViewModels, Domain-Models für Display
Verboten: Business-Logik, direkte Service-Aufrufe
```

### Bekannte Ausnahmen
- `Logger` im Application Layer ist akzeptiert (Cross-Cutting Concern)
- `Combine`/`Flow` für Reactive Patterns ist akzeptiert

---

## Referenz

- Architektur-Doku: `dev-docs/architecture/overview.md`
- DDD-Guide: `dev-docs/architecture/ddd.md`
- Bereits behoben: `GuidedMeditationPlayerViewModel` Clock-Abstraktion (shared-023)

---

## Hinweise

- Review soll keine sofortige Behebung aller Verstöße erfordern
- Ziel ist Transparenz und Priorisierung
- Kleine Verstöße können als "akzeptierte technische Schuld" dokumentiert werden

---

## iOS Review-Ergebnis (2026-01-18)

### Gefundene Verstöße

#### KRITISCH - Domain Layer
| Datei | Verstoß |
|-------|---------|
| `GuidedMeditation.swift:153` | `FileManager.default.urls()` im Domain Model |

→ Follow-up: **ios-031**

#### MITTEL - Application Layer
| Datei | Verstoß |
|-------|---------|
| `TimerViewModel.swift:140-150` | `UserDefaults.standard` in `saveSettings()` |
| `TimerViewModel.swift:402-434` | `UserDefaults.standard` in `loadSettings()` |
| `GuidedMeditationPlayerViewModel.swift:138` | `FileManager.default.fileExists()` |

→ Follow-up: **ios-032**

#### NIEDRIG - Presentation Layer (DI-Probleme)
| Datei | Verstoß |
|-------|---------|
| `SettingsView.swift:15` | `AudioService()` intern instantiiert |
| `SettingsView.swift:27` | `BackgroundSoundRepository()` als Default |

→ Follow-up: **ios-033**

### Akzeptierte Patterns
- Foundation (Date, TimeInterval, UUID, URL) im Domain Layer
- Combine (AnyPublisher) im Domain Layer für Protokoll-Return-Types
- OSLog/Logger im Application Layer als Cross-Cutting Concern

### Logging im Domain Layer
Domain importiert kein OSLog - korrekt so. Logging ist Infrastructure-Concern.

### Automatisierung
SwiftLint unterstützt keine layer-basierten Import-Regeln. Empfehlung: Einfaches Shell-Skript in `make check` als Warnung bei neuen Verstößen.

### Follow-up-Tickets
1. **ios-031** (HOCH): Domain FileManager-Abstraktion
2. **ios-032** (MITTEL): Timer Settings Repository
3. **ios-033** (NIEDRIG): SettingsView Dependency Injection

---

## Android Review-Ergebnis (2026-01-18)

### Gefundene Verstöße

#### NIEDRIG - Domain Layer
| Datei | Verstoß |
|-------|---------|
| `AudioPlayerServiceProtocol.kt:3` | `android.net.Uri` im Domain-Protokoll |
| `GuidedMeditationRepository.kt:3` | `android.net.Uri` im Domain-Protokoll |

→ **Akzeptiert**: Uri ist analog zu iOS URL - notwendig für File-Handling. Kotlin/Java Standard-Library hat keinen eigenen URI-Typ der für Content URIs funktioniert. Alternative wäre String, aber das würde Type-Safety reduzieren.

#### MITTEL - Application Layer (ViewModel)
| Datei | Verstoß |
|-------|---------|
| `TimerViewModel.kt:7` | `import com.stillmoment.data.local.SettingsDataStore` |
| `TimerViewModel.kt:17` | `import com.stillmoment.infrastructure.audio.AudioService` |
| `TimerViewModel.kt:18` | `import com.stillmoment.infrastructure.audio.TimerForegroundService` |
| `TimerViewModel.kt:78` | `settingsDataStore: SettingsDataStore` als Constructor-Parameter |
| `TimerViewModel.kt:80` | `audioService: AudioService` - konkrete Klasse statt Protokoll |
| `TimerViewModel.kt:92,220` | Direkter `settingsDataStore.getHasSeenSettingsHint()` Aufruf |
| `TimerViewModel.kt:129-170` | Direkte `TimerForegroundService` statische Aufrufe |

→ Follow-up: **android-061**, **android-062**

### Positiv - Saubere Bereiche

- **Presentation Layer**: Keine Business-Logik, nur UI-Binding - vollständig sauber
- **Infrastructure Layer**: Korrekte Protokoll-Implementierungen, keine zirkulären Abhängigkeiten
- **GuidedMeditationPlayerViewModel**: Verwendet Protokolle korrekt (`AudioPlayerServiceProtocol`, `AudioSessionCoordinatorProtocol`)
- **GuidedMeditationsListViewModel**: Verwendet nur Repositories - vollständig sauber
- **DI-Module (AppModule.kt)**: Korrekte Bindings von Implementierungen an Domain-Protokolle

### Akzeptierte Patterns
- `android.net.Uri` im Domain Layer für File-URIs (analog iOS URL)
- `kotlinx.coroutines.flow.Flow/StateFlow` im Domain Layer für Reactive Patterns
- `kotlinx.coroutines.delay` im ViewModel für Timer-Loops (analog iOS Task.sleep)

### Gesamtbewertung

Android hat weniger Verstöße als iOS:
- **Domain**: Nur Uri-Import (akzeptiert)
- **Application**: TimerViewModel hat direkte Infrastruktur-Zugriffe (analog iOS)
- **Presentation**: Vollständig sauber
- **Infrastructure**: Vollständig sauber

Die Architektur ist insgesamt gut eingehalten.

### Follow-up-Tickets
1. **android-061** (MITTEL): Timer Settings Repository Abstraktion
2. **android-062** (MITTEL): Timer Service Abstraktionen

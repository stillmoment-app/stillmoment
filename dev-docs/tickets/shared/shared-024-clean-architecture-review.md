# Ticket shared-024: Clean Architecture Layer-Review

**Status**: [ ] TODO
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
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Review (beide Plattformen)
- [ ] Domain Layer: Keine Imports von Foundation/UIKit/SwiftUI (iOS) bzw. Android-Framework (Android)
- [ ] Application Layer: Keine direkten Timer-, FileManager-, UserDefaults-Aufrufe
- [ ] Presentation Layer: Keine Business-Logik, nur UI-Binding
- [ ] Infrastructure Layer: Implementiert Domain-Protokolle, keine zirkulären Abhängigkeiten
- [ ] Ergebnis dokumentiert mit Liste der Verstöße und Empfehlungen

### Dokumentation
- [ ] Review-Ergebnis in Ticket-Kommentar oder separatem Dokument
- [ ] Follow-up-Tickets für kritische Verstöße (falls nötig)

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

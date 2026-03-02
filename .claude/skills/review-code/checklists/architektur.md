# Architektur

Folgt der Code den Projekt-Patterns? Sind Abhaengigkeiten korrekt?

## Nur melden wenn wirklich problematisch

### Layer-Verletzungen
- Domain haengt von Infrastructure ab (KRITISCH)
- ViewModels importieren UIKit/SwiftUI (iOS) oder Android-Framework-Klassen
- Zirkulaere Abhaengigkeiten zwischen Modulen

### Projekt-Pattern-Verletzungen
- Neuer Service ohne Protocol in Domain-Layer
- ViewModel greift direkt auf Dateisystem/Netzwerk zu
- Neue Abhaengigkeiten nicht ueber DI

### Single Responsibility
- Klasse oder Funktion hat mehr als einen Grund sich zu aendern
- God-Class (alles in einer Klasse die nicht zusammengehoert)
- Falsche Verantwortlichkeiten (z.B. View macht Geschaeftslogik)

### Dependency Direction
- Abhaengigkeiten zeigen nach aussen statt nach innen (Domain ← Application ← Presentation)
- Feature Envy (Klasse arbeitet mehr mit fremden Daten als eigenen — deutet auf falsche Heimat hin)

## Projekt-Architektur (Referenz)

```
Domain (keine Abhaengigkeiten)
    |
Application (nur Domain)
    |
Presentation (Domain + Application)
    |
Infrastructure (implementiert Domain-Protocols)
```

### iOS
- Domain: `Domain/Models/`, `Domain/Services/` (Protocols)
- Application: `Application/ViewModels/`
- Presentation: `Presentation/Views/`
- Infrastructure: `Infrastructure/Services/`

### Android
- Domain: `domain/models/`, `domain/repositories/` (Interfaces)
- Application: `presentation/viewmodel/`
- Presentation: `presentation/ui/`
- Infrastructure: `infrastructure/`, `data/`

## NICHT melden

- "Koennte man auch in separates Modul auslagern"
- "Ist nicht 100% Clean Architecture"
- "In einem groesseren Projekt wuerde ich..."
- Stilistische Architektur-Praeferenzen

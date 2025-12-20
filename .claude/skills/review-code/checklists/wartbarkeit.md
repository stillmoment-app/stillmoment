# Wartbarkeit

Kann ein anderer Entwickler diesen Code in 6 Monaten verstehen und aendern?

## Nur melden wenn wirklich problematisch

### Verstaendlichkeit
- Code ist ohne Erklaerung nicht nachvollziehbar
- Wichtige Entscheidungen sind nicht offensichtlich
- Komplexe Logik ohne erklaerenden Kommentar

### Aenderbarkeit
- Aenderung an einer Stelle erfordert viele Folgeaenderungen
- Keine klare Stelle fuer neue Funktionalitaet erkennbar
- Enge Kopplung erschwert Anpassungen

### Fehleranfaelligkeit
- Leicht zu uebersehende Fallstricke
- Implicit State der Bugs verursachen kann
- Reihenfolge-Abhaengigkeiten die nicht offensichtlich sind

## iOS-spezifisch

### Nur wenn problematisch:
- Force Unwraps (`!`) in Produktionscode ohne Begruendung
- Retain Cycles durch fehlendes `[weak self]`
- Thread-Safety-Probleme (fehlende `@MainActor` wo noetig)

## Android-spezifisch

### Nur wenn problematisch:
- Nullable ohne Null-Handling (`!!` ohne Begruendung)
- Lifecycle-Probleme (Memory Leaks, Crashes)
- Coroutine-Scope-Probleme

## NICHT melden

- "Methode ist etwas lang" (wenn sie trotzdem klar ist)
- "Koennte man in kleinere Klassen aufteilen" (wenn nicht noetig)
- "Variablenname koennte besser sein" (wenn er verstaendlich ist)

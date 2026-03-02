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

### DRY — Kein dupliziertes Wissen
- Gleiche Logik an mehreren Stellen (nicht nur Code, auch Konzepte)
- Mehrere Primitives die immer zusammen geprueft werden → fehlendes Konzept
  (Beispiel: `enabled + id` statt `activeIntroductionId`)
- Caller muss interne Repräsentation eines Objekts verstehen um zu entscheiden (Tell, Don't Ask)

### Fail Fast
- Validierung tief im System statt an der Eingabegrenze
- Ungueltige Zustände werden durchgereicht statt sofort abgefangen

### Explicit over Implicit
- Versteckte Side Effects in scheinbar harmlosen Aufrufen
- Magic Values oder undokumentierte Konventionen
- Reihenfolge-Abhaengigkeiten die nicht aus dem Code ersichtlich sind

### Fehleranfaelligkeit
- Leicht zu uebersehende Fallstricke
- Implicit State der Bugs verursachen kann

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

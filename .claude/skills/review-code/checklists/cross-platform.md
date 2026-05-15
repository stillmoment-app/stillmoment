# Cross-Platform-Konsistenz

Beide Plattformen muessen sich identisch verhalten. Same features, same UX, same edge cases. (Siehe `CLAUDE.md` Abschnitt "Cross-Platform Consistency".)

## Kernfrage

> Wurde ein Feature auf nur einer Plattform geaendert, das auf der anderen Plattform ebenfalls existiert?

Wenn ja → potenzielles Konsistenz-Finding.

## Wann pruefen

- Diff aendert eine Plattform (`ios/` oder `android/`), aber nicht beide
- Aenderung betrifft Domain-Logik, UX-Flow, oder ein Feature aus dem Glossar
- Tests fuer das Feature existieren auf beiden Plattformen, aber nur eine wurde aktualisiert

**Nicht pruefen** wenn die Aenderung eindeutig plattformspezifisch ist:
- iOS: AVFoundation, Lock-Screen-Keep-Alive, AudioServicesPlaySystemSound
- Android: Compose-internals, MediaSession, ADB-Workflow
- Build-Skripte, Fastlane, Gradle

## Pruef-Heuristik

1. **Diff nur auf einer Plattform?** → Andere Plattform anschauen
2. **Glossar pruefen** (`dev-docs/reference/glossary.md`): Gibt es das Konzept dort? Wie heisst es auf der anderen Plattform?
3. **Tests vergleichen:** Hat die andere Plattform aequivalente Tests? Wurden die mitgezogen?
4. **UX-Konsistenz:** Wenn ein UX-Pattern (z.B. Confirmation-Dialog) auf iOS geaendert wurde — Android-Pendant in gleicher Form?

## Subagent fuer Cross-Platform-Verify

Bei Verdacht: `Explore`-Subagent starten:

> "Suche im `{andere-plattform}/` Verzeichnis nach dem aequivalent zu `{Feature/Klasse}` auf dieser Plattform. Vergleiche das Verhalten. Wurde es synchron mit dem Diff gehalten? Gib gefundene Stellen + Status zurueck."

So bleibt der Hauptkontext frei.

## Was als Finding melden

### Echtes Finding
- Domain-Logik auf einer Plattform geaendert, auf der anderen nicht (z.B. Timer-State-Machine, Audio-Coordinator-Verhalten)
- Neuer Akzeptanzkriterium-Pfad nur auf einer Plattform implementiert
- Domain-Begriff nur auf einer Plattform umbenannt
- Tests fuer kritisches Verhalten nur auf einer Plattform aktualisiert

### Kein Finding
- Plattform-spezifische Implementierung (UIKit-Bridge vs Compose-MultipleEmitters)
- Style/Spacing-Unterschiede die durch HIG/Material vorgegeben sind
- Reines Bug-Fix-Ticket fuer eine Plattform (Cross-Platform-Konsistenz haengt am Ticket-Scope)

## Ticket-Scope respektieren

**Wichtig:** Wenn das Ticket explizit nur eine Plattform betrifft (`#ios-042`, `#android-018`), ist die andere Plattform **nicht** Scope dieses Tickets. Konsistenz-Finding dann nur als Hinweis fuer ein Follow-up-Ticket — nicht als Nacharbeit.

Bei `shared-*`-Tickets dagegen ist Cross-Platform-Konsistenz Pflicht.

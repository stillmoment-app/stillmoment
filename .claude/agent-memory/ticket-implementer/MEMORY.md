# Ticket Implementer - Key Learnings

## Ticket-Referenzen

- **Ticket-Dateinamen nie raten.** Ticket-ID und Dateiname stimmen nicht immer ueberein (z.B. `shared-013-timer-focus-mode.md` statt erwartetem `shared-013-timer-state-machine.md`). Immer per `Glob("dev-docs/tickets/**/*shared-013*")` suchen statt Dateinamen zu konstruieren.

## Feature-Entfernungen (Refactoring)

- **CLAUDE.md Code-Beispiele pruefen.** Bei Feature-Entfernungen (z.B. Pause-Funktionalitaet) auch `ios/CLAUDE.md` und `android/CLAUDE.md` auf veraltete Code-Beispiele pruefen. Diese Dateien enthalten oft Architektur-Snippets die das entfernte Feature referenzieren.

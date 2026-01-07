# Ticket {platform}-{NNN}: {Titel}

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: KRITISCH | HOCH | MITTEL | NIEDRIG
**Aufwand**: Klein | Mittel | Gross
**Abhaengigkeiten**: Keine | {platform}-{NNN}
**Phase**: 1-Quick Fix | 2-Architektur | 3-Feature | 4-Polish | 5-QA

---

## Was

{1-2 Saetze: Was soll gemacht werden?}

## Warum

{1-2 Saetze: Warum ist das wichtig? Welches Problem loest es?}

---

## Akzeptanzkriterien

<!-- Gute Kriterien: Beobachtbar, testbar, user-zentriert. Details: dev-docs/TICKET_GUIDE.md -->

### Feature
- [ ] {Beobachtbares Verhalten 1}
- [ ] {Beobachtbares Verhalten 2}
- [ ] Lokalisiert (DE + EN) falls UI

### Tests
- [ ] Unit Tests fuer {Hauptlogik}

### Dokumentation
- [ ] CHANGELOG.md (bei user-sichtbaren Aenderungen)
- [ ] GLOSSARY.md (bei neuen Domain-Begriffen)

---

## Manueller Test

1. {Schritt 1}
2. {Schritt 2}
3. Erwartung: {Was soll passieren?}

---

## Referenz

{Optional: Verweis auf existierenden Code als Orientierung}

- iOS: `ios/StillMoment/{path}/`
- Android: `android/app/src/main/kotlin/com/stillmoment/{path}/`
- Doku: {Link falls relevant}

---

## Hinweise

{Optional: Nur fuer nicht-offensichtliche Entscheidungen, bekannte Fallstricke, oder spezifische API-Namen die recherchiert wurden}

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine Dateilisten (Claude Code findet die Dateien)
- Keine Architektur-Diagramme (steht in CLAUDE.md)
- Keine Test-Befehle (steht in CLAUDE.md)

Claude Code hat Zugriff auf:
- CLAUDE.md (Architektur, Commands, Patterns)
- Bestehenden Code als Referenz
- iOS-Implementierung fuer Android-Ports
-->

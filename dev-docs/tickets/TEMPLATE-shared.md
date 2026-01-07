# Ticket shared-{NNN}: {Titel}

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: KRITISCH | HOCH | MITTEL | NIEDRIG
**Aufwand**: iOS ~X | Android ~X
**Phase**: 1-Quick Fix | 2-Architektur | 3-Feature | 4-Polish | 5-QA

---

## Was

{1-2 Saetze: Was soll gemacht werden?}

## Warum

{1-2 Saetze: Warum ist das wichtig? Welches Problem loest es?}

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen. Details: dev-docs/TICKET_GUIDE.md -->

### Feature (beide Plattformen)
- [ ] {Beobachtbares Verhalten 1}
- [ ] {Beobachtbares Verhalten 2}
- [ ] Lokalisiert (DE + EN) falls UI
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md (bei user-sichtbaren Aenderungen)
- [ ] GLOSSARY.md (bei neuen Domain-Begriffen)

---

## Manueller Test

1. {Schritt 1}
2. {Schritt 2}
3. Erwartung: {Was soll passieren - identisch auf beiden Plattformen?}

---

## UX-Konsistenz

{Optional: Nur falls plattform-spezifische Unterschiede erlaubt/gewuenscht sind}

| Verhalten | iOS | Android |
|-----------|-----|---------|
| {Beispiel} | {iOS-Variante} | {Android-Variante} |

---

## Referenz

- iOS: `ios/StillMoment/{path}/`
- Android: `android/app/src/main/kotlin/com/stillmoment/{path}/`

---

## Hinweise

{Optional: Plattform-spezifische Fallstricke, API-Unterschiede}

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->

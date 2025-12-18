# iOS Tickets

## Status-Legende
- `[ ]` TODO
- `[~]` IN PROGRESS
- `[x]` DONE

---

## Ticket-Übersicht

| Nr | Ticket | Typ | Status | Priorität |
|----|--------|-----|--------|-----------|
| [iOS-001](001-headphone-playpause.md) | Play/Pause über kabelgebundene Kopfhörer | Bug-Fix | [ ] | MITTEL |
| [iOS-002](002-ambient-sound-fade.md) | Ambient Sound Fade In/Out | Feature | [ ] | MITTEL |

---

## Workflow

```bash
# 1. Ticket lesen
cat dev-docs/ios-tickets/001-headphone-playpause.md

# 2. Claude Code beauftragen
"Setze Ticket iOS-001 um gemäß der Spezifikation"

# 3. Tests ausführen
cd ios && make test-unit

# 4. Status auf [x] setzen
```

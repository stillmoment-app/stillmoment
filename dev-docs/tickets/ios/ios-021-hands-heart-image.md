# Ticket ios-021: Haende-Herz-Bild statt Emoji

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das Emoji im TimerView (Idle-State) durch ein eigenes Bild ersetzen. Das Bild zeigt Haende, die ein Herz halten.

## Warum

Das eigene Bild ist visuell ansprechender und passt besser zum warmherzigen Design der App als das Standard-Emoji.

---

## Akzeptanzkriterien

- [ ] Bild wird im TimerView (Idle-State) anstelle des Emojis angezeigt
- [ ] Bild hat Groesse 150x150pt
- [ ] Bild passt zum warmen Farbverlauf-Hintergrund (transparenter PNG-Hintergrund)
- [ ] Unit Tests geschrieben/aktualisiert (nicht noetig - rein visuell)
- [ ] Lokalisiert (DE + EN) falls UI (nicht noetig - kein Text)

---

## Manueller Test

1. App starten
2. Timer-Tab oeffnen (Idle-State)
3. Erwartung: Haende-mit-Herz-Bild wird ueber der Minuten-Auswahl angezeigt (150x150)

---

## Referenz

- Quellbild: `hands_heart.png` (Projekt-Hauptordner)
- iOS: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` (minutePicker)

---

## Hinweise

Keine besonderen Hinweise.

---
id: shared-141
title: "Timer-Zifferblatt zeigt „1 Minuten“ statt „1 Minute“"
status:
  ios: wontfix
  android: wontfix
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket shared-141: Timer-Zifferblatt zeigt „1 Minuten“ statt „1 Minute“

## Was

**Beobachtet:** Ist im Timer eine Dauer von 1 Minute eingestellt, steht im Zifferblatt unter der Zahl „MINUTEN“ (EN „MINUTES“).
**Erwartet:** Bei 1 Minute steht „MINUTE“ (EN „MINUTE“), bei jeder anderen Dauer wie bisher „MINUTEN“ (EN „MINUTES“).
**Umstaende:** Timer-Startbildschirm, iOS und Android, Deutsch und Englisch. Bestand schon in 2.5.0; aufgefallen bei der Screenshot-Prüfung für 2.6.0.

## Warum

Grammatikfehler direkt im Mittelpunkt des Timer-Bildschirms wirken nachlässig.

---

## Akzeptanzkriterien

- [ ] Bei einer eingestellten Dauer von 1 Minute zeigt das Zifferblatt „MINUTE“ (DE und EN)
- [ ] Bei jeder anderen Dauer zeigt das Zifferblatt weiterhin „MINUTEN“ bzw. „MINUTES“
- [ ] Die Einheit wechselt sofort mit, wenn die Dauer zwischen 1 und 2 Minuten verstellt wird
- [ ] VoiceOver bzw. TalkBack sagt die Dauer bei 1 Minute ebenfalls in der Einzahl an

---

## WONTFIX

2026-10-11 Duplikat von shared-140. shared-140 deckt denselben Fehler ab, zusätzlich die Intervall-Gong-Ansage auf Android und den Schutz bereits korrekter Stellen. Das Kriterium „Einheit wechselt sofort mit“ und der Screenshot-Hinweis wurden nach shared-140 übernommen.

## Manueller Test

1. Timer-Tab öffnen, Dauer auf 1 Minute stellen
2. Auf 2 Minuten und wieder zurück auf 1 Minute stellen
3. Erwartung: Bei 1 „MINUTE“, bei 2 „MINUTEN“ — auf beiden Plattformen und in beiden Sprachen

---

## Hinweise

- Die Store-Screenshots zeigen den Timer ab 2.6.0 mit 10 Minuten, der Fehler ist dort also nicht mehr sichtbar.

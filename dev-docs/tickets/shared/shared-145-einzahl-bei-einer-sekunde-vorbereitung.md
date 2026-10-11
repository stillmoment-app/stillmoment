---
id: shared-145
title: "Einzahl bei einer Sekunde in der Ansage der Vorbereitungszeit"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket shared-145: Einzahl bei einer Sekunde in der Ansage der Vorbereitungszeit

## Was

**Beobachtet:** Während der Vorbereitungszeit sagen VoiceOver und TalkBack bei der letzten Sekunde die Mehrzahl:
- iOS, Timer: „Preparation: 1 seconds“ bzw. „Vorbereitung: 1 Sekunden“
- iOS, Player einer geführten Meditation: „1 seconds until meditation starts“ bzw. „1 Sekunden bis die Meditation beginnt“
- Android, Timer und Player: „1 seconds until meditation starts“ bzw. „Noch 1 Sekunden bis die Meditation beginnt“

**Erwartet:** Bei 1 Sekunde die Einzahl („1 second“, „1 Sekunde“), ab 2 Sekunden die Mehrzahl.

**Umstände:** iOS und Android, Deutsch und Englisch, Timer und Player, sobald eine Vorbereitungszeit eingestellt ist. Die sichtbare Zahl im Atemkreis ist nicht betroffen, nur die Screenreader-Ansage. Gefunden bei shared-140.

## Warum

Screenreader-Nutzer hören den Fehler bei jeder Meditation mit Vorbereitungszeit, direkt vor dem Beginn. Nach shared-140 ist es die letzte bekannte Stelle mit falscher Mehrzahl.

---

## Akzeptanzkriterien

- [ ] Timer, Vorbereitungszeit: Ansage bei 1 Sekunde in der Einzahl, bei 2 Sekunden in der Mehrzahl, in EN und DE
- [ ] Player einer geführten Meditation, Vorbereitungszeit: dasselbe
- [ ] Der übrige Wortlaut der Ansagen bleibt wie bisher

---

## Reproduktion

1. Vorbereitungszeit einstellen (z.B. 5 Sekunden), VoiceOver bzw. TalkBack einschalten
2. Timer starten und die Zahl im Atemkreis fokussiert lassen, bis 1 erreicht ist
3. Erwartung: „1 second …“ bzw. „1 Sekunde …“; dasselbe beim Start einer geführten Meditation

---

## Nicht Teil dieses Tickets

- Der unterschiedliche Wortlaut der Ansage im Timer auf iOS („Vorbereitung: … Sekunden“) und Android („Noch … Sekunden bis die Meditation beginnt“). Das ist kein Grammatikfehler und wird hier nicht angeglichen.

---

## Hinweise

- Vorbild ist shared-140: Dort wurden die Minuten-Ansagen auf beiden Plattformen mit Plural-Regeln der Lokalisierung gelöst, nicht mit einer Fallunterscheidung im Code.

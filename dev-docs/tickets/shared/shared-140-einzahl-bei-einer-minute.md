---
id: shared-140
title: "Einzahl bei einer Minute im Atemkreis und in Ansagen"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket shared-140: Einzahl bei einer Minute im Atemkreis und in Ansagen

## Was

**Beobachtet:** Steht der Atemkreis auf 1 Minute, zeigt er unter der Zahl „MINUTES“ bzw. „MINUTEN“. VoiceOver und TalkBack sagen „1 minutes“ bzw. „1 Minuten“. Auf Android sagt TalkBack beim Intervall-Gong-Abstand von 1 Minute ebenfalls „Interval: 1 minutes“ bzw. „Intervall: 1 Minuten“.

**Erwartet:** Bei 1 Minute steht und klingt die Einzahl („MINUTE“, „1 minute“, „1 Minute“); ab 2 Minuten die Mehrzahl.

**Umstände:** iOS und Android, Deutsch und Englisch, Timer-Startbildschirm und Intervall-Gong-Einstellung (Android). Besteht seit Einführung des Atemkreises (shared-086).

## Warum

Ein grammatischer Fehler an der prominentesten Stelle des Timers wirkt nachlässig, und Screenreader-Nutzer hören ihn bei jeder Bedienung.

---

## Akzeptanzkriterien

- [ ] Atemkreis bei 1 Minute: Einheit „MINUTE“ (in EN und DE gleich); bei 2 und 60 Minuten „MINUTES“ bzw. „MINUTEN“
- [ ] Screenreader-Ansage des Atemkreises: „1 minute“ / „1 Minute“ bei 1, „2 minutes“ / „2 Minuten“ bei 2
- [ ] Android: TalkBack-Ansage des Intervall-Gong-Abstands bei 1 Minute in der Einzahl, ab 2 in der Mehrzahl
- [ ] Bereits korrekte Stellen bleiben korrekt: „von 1 Minute“ in der laufenden Sitzung, Vorbereitungszeit-Anzeige, Restzeit-Ansage, Intervall-Hinweistexte

---

## Manueller Test

1. Timer-Tab öffnen, Atemkreis auf 1 Minute drehen
2. Erwartung: unter der Zahl steht „MINUTE“; auf 2 drehen → „MINUTES“ / „MINUTEN“
3. VoiceOver bzw. TalkBack einschalten, Atemkreis auf 1 und 2 stellen → Ansage in Einzahl bzw. Mehrzahl
4. Android: Intervall-Gongs öffnen, Abstand auf 1 Minute stellen, mit TalkBack fokussieren → Einzahl
5. In Deutsch und Englisch wiederholen, identisch auf beiden Plattformen

---

## Hinweise

- shared-125 (offen) ersetzt den Atemkreis später durch „Zahl mit Einheit darunter + Bahn“. Entschieden: trotzdem jetzt beheben. Die Lösung sollte so gebaut sein, dass shared-125 die Einzahl-fähige Einheit übernehmen kann, statt den Fehler neu einzuführen.
- Zahl und Einheit stehen im Atemkreis in getrennten Zeilen; die Einheit enthält die Zahl selbst nicht.

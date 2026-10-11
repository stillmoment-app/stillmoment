---
id: ios-066
title: "VoiceOver liest am Spul-Regler des Players „nan“ vor"
status: wontfix
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket ios-066: VoiceOver liest am Spul-Regler des Players „nan“ vor

## Was

**Beobachtet:** Im Player einer laufenden geführten Meditation meldet der Spul-Regler als Wert „nan“ statt der aktuellen Position.
**Erwartet:** VoiceOver liest die aktuelle Position verständlich vor (z.B. verstrichene Zeit oder Restzeit) und der Regler lässt sich mit VoiceOver-Gesten verstellen.
**Umstände:** Im Bedienungshilfen-Abbild der Wiedergabe-Ansicht im Simulator gesehen (2026-10-11, bei der Prüfung von shared-143). Bestand schon vor shared-143. Ob es auch ohne aktives VoiceOver-Abbild auftritt oder nur in bestimmten Momenten (z.B. direkt nach dem Start), ist nicht geprüft.

## Warum

Wer den Player mit VoiceOver bedient, hört „nan“ statt einer Zeitangabe und kann nicht einschätzen, wo er in der Meditation steht.

---

## Akzeptanzkriterien

- [ ] VoiceOver liest am Spul-Regler eine verständliche Zeitangabe statt „nan“, auch direkt nach dem Start der Meditation
- [ ] Wischen nach oben oder unten auf dem Regler verstellt die Position in sinnvollen Schritten
- [ ] Die Beschriftung ist auf Deutsch und Englisch vorhanden

---

## Manueller Test

VoiceOver-Ansage lässt sich nur mit aktivem VoiceOver sicher prüfen.

1. VoiceOver einschalten, geführte Meditation starten
2. Den Spul-Regler auswählen
3. Erwartung: Ansage mit Zeitangabe, kein „nan“

---

## Hinweise

- Android-Verhalten mit TalkBack zum Vergleich prüfen.

---

## WONTFIX

Nicht wichtig genug. Der Spul-Bereich hat seit shared-109 einen lokalisierten Wert („3:12 von 20:00“) und Wischgesten. Aus diesem Wert kann kein „nan“ entstehen. Vermutlich stammt das „nan“ aus dem Bedienungshilfen-Abbild im Simulator, nicht aus der VoiceOver-Ansage. Mit echtem VoiceOver nicht geprüft. Wieder aufnehmen, wenn ein Nutzer das Problem meldet.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->

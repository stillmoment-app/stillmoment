---
id: shared-136
title: "Schrift-Nachweise (OFL) in den Einstellungen"
status:
  ios: done
  android: done
phase: 5-QA
priority: mittel
depends_on: []
---

# Ticket shared-136: Schrift-Nachweise (OFL) in den Einstellungen

## Was

In den Einstellungen gibt es im Abschnitt „Info & Rechtliches“ einen neuen Eintrag „Schrift-Nachweise“, gleich neben „Klang-Nachweise“. Er nennt die beiden Schriften der App und zeigt den vollständigen Lizenztext, unter dem sie stehen.

## Warum

Beide Plattformen liefern seit ios-048 und shared-099 die Schriften Newsreader und Geist mit. Beide stehen unter der SIL Open Font License 1.1 (OFL). Die OFL verlangt in §2, dass der Lizenztext mit der Software ausgeliefert wird und leicht einsehbar ist. Der Text liegt zwar in beiden Apps bei, ist aus der App heraus aber nirgends zu sehen. Die Schriften sind seit Version 2.4.0 im Store, die Lücke betrifft also schon veröffentlichte Versionen.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. Beobachtbar, konkret, pruefbar. Tests, Lokalisierung und Doku regelt die Definition of Done (README). -->

- [ ] Unter „Info & Rechtliches“ erscheint der Eintrag „Schrift-Nachweise“ (EN „Font Attributions“, passend zu „Sound Attributions“), direkt nach „Klang-Nachweise“
- [ ] Ein Tipp auf den Eintrag öffnet eine eigene Seite, die beide Schriften mit ihrer Quelle nennt: Newsreader (Production Type) und Geist (Vercel), jeweils unter der SIL Open Font License 1.1
- [ ] Auf derselben Seite steht der vollständige OFL-1.1-Lizenztext, wie er der App beiliegt: von den Copyright-Zeilen am Anfang bis zum Ende des Haftungsausschlusses, ohne abgeschnittene Zeilen, scrollbar
- [ ] Überschriften und Erläuterungen sind auf Deutsch und Englisch übersetzt; der Lizenztext selbst bleibt im englischen Original
- [ ] Die Seite ist im hellen und im dunklen Erscheinungsbild lesbar und skaliert mit der Schriftgröße des Systems
- [ ] „Klang-Nachweise“ öffnet weiterhin die bisherige Seite mit den Klang-Quellen

---

## Manueller Test

1. App starten, Einstellungen öffnen
2. Zum Abschnitt „Info & Rechtliches“ scrollen
3. Auf „Schrift-Nachweise“ tippen
4. Bis ans Ende der Seite scrollen
5. Erscheinungsbild auf Dunkel umstellen, Seite erneut öffnen
6. Erwartung: Die Seite nennt Newsreader und Geist mit Quelle und Lizenz, darunter steht der vollständige OFL-Text bis zum Haftungsausschluss. Hell und dunkel ist alles lesbar. iOS und Android verhalten sich gleich.

---

## Hinweise

- Der Lizenztext ist die Datei, die mit den Schriften in der App liegt, keine eigene Abschrift. Wird eine Schrift aktualisiert und ändert sich dabei der Text, zeigt die App automatisch den neuen.
- OFL §2 erlaubt die Auslieferung „as a stand-alone text file, human-readable header, or in machine-readable metadata“. Eine Seite in der App, die den Text anzeigt, erfüllt „human-readable“.
- OFL §4 verbietet, die Namen der Autoren zur Werbung für die App zu nutzen. Als Quellenangabe auf dieser Seite sind sie erlaubt.
- Ersetzt ios-049, das noch davon ausging, dass nur iOS die Schriften nutzt.

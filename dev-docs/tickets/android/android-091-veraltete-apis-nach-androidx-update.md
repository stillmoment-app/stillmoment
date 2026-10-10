---
id: android-091
title: "Veraltete AndroidX-/Compose-APIs nach dem Dependabot-Update ersetzen"
status: todo
phase: 5-QA
priority: niedrig
depends_on: []
---

# Ticket android-091: Veraltete AndroidX-/Compose-APIs nach dem Dependabot-Update ersetzen

## Was

Seit dem ersten Dependabot-Update der AndroidX- und Compose-Bibliotheken (PR #10: Compose 1.12, hilt-navigation-compose 1.4) meldet der Kotlin-Compiler beim Android-Build Veraltungswarnungen im App-Code. Danach baut die App wieder ohne diese Warnungen, und alle betroffenen Bildschirme verhalten sich wie vorher.

## Warum

Veraltete APIs verschwinden in späteren Bibliotheksversionen. Dependabot bringt diese Versionen jetzt jeden Monat als Pull Request. Werden die Warnungen nicht zeitnah behoben, scheitert irgendwann ein Update-PR am Build, und der Bruch vermischt sich mit dem eigentlichen Update. Ohne Altlasten sind neue Warnungen außerdem sofort sichtbar.

---

## Akzeptanzkriterien

- [ ] Der Android-Build meldet keine Veraltungswarnungen mehr für den App-Code
- [ ] Timer, Timer-Fokus, Intervall-Editor, Auswahl der Vorbereitungszeit, Soundscape-Auswahl und Gong-Auswahl öffnen weiterhin und zeigen die gespeicherten Einstellungen
- [ ] Im Dialog „Keine Mail-App“ (Rückmeldung → „Schreib uns“ ohne Mail-App) kopiert ein Tippen auf die Adresse sie weiterhin in die Zwischenablage, und die Bestätigung erscheint
- [ ] In den Einstellungen für geführte Meditationen öffnet sich die Auswahl der Vorbereitungszeit weiterhin, und die gewählte Dauer wird übernommen

---

## Manueller Test

1. Android-Build ausführen und die Compiler-Ausgabe nach `deprecated` durchsuchen
2. Alle oben genannten Timer-Bildschirme nacheinander öffnen und eine Einstellung ändern
3. Auf einem Gerät ohne Mail-App Einstellungen → „Schreib uns“ tippen, im Dialog die Adresse kopieren und irgendwo einfügen
4. Einstellungen für geführte Meditationen → Vorbereitungszeit einschalten, die Dauer auf 30 s ändern
5. Erwartung: keine Veraltungswarnungen; alle Bildschirme, das Kopieren und die Auswahl funktionieren wie vorher

---

## Hinweise

- Beobachtete Warnungen (lokaler Build am 2026-10-10; erfasst sind nur die letzten Zeilen der Ausgabe, die Liste kann unvollständig sein):
  - `hiltViewModel` ist in ein anderes Package umgezogen. Betroffen sind die sechs Timer-Bildschirme aus dem Akzeptanzkriterium.
  - `LocalClipboardManager` ist veraltet (Dialog „Keine Mail-App“).
  - `MenuAnchorType` ist umbenannt (Auswahl der Vorbereitungszeit für geführte Meditationen).
- Voraussetzung ist, dass die App mit den neuen Bibliotheken überhaupt baut. Dafür muss PR #12 (compileSdk 37) gemergt sein.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->

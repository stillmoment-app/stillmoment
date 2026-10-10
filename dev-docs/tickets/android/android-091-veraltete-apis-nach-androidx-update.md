---
id: android-091
title: "Veraltete AndroidX-/Compose-APIs nach dem Dependabot-Update ersetzen"
status: in-progress
phase: 5-QA
priority: niedrig
depends_on: []
---

# Ticket android-091: Veraltete AndroidX-/Compose-APIs nach dem Dependabot-Update ersetzen

## Was

Seit den ersten Dependabot-Updates (PRs #9 und #10: Compose 1.12, hilt-navigation-compose 1.4, mockito-kotlin 6) meldet der Kotlin-Compiler beim Android-Build Veraltungswarnungen und fehlende Opt-ins, im App-Code wie in den Tests. Nach diesem Ticket sind alle Warnungen behoben, die sich durch einen direkten Ersatz lösen lassen. Alle betroffenen Bildschirme verhalten sich wie vorher.

## Warum

Veraltete APIs verschwinden in späteren Bibliotheksversionen. Dependabot bringt diese Versionen jetzt jeden Monat als Pull Request. Werden die Warnungen nicht zeitnah behoben, scheitert irgendwann ein Update-PR am Build, und der Bruch vermischt sich mit dem eigentlichen Update. Ohne Altlasten sind neue Warnungen außerdem sofort sichtbar.

---

## Akzeptanzkriterien

- [ ] Der Android-Build (App, Unit-Tests, UI-Tests; Debug und Release) meldet keine Veraltungswarnungen und keine fehlenden Opt-ins mehr. Ausgenommen sind nur die beiden Fälle aus „Nicht Teil dieses Tickets“.
- [ ] Bibliothek, Player, Trim-Editor, Timer, Timer-Fokus, Intervall-Editor, Auswahl der Vorbereitungszeit, Soundscape-Auswahl und Gong-Auswahl öffnen weiterhin und zeigen die gespeicherten Daten bzw. Einstellungen
- [ ] Im Dialog „Keine Mail-App“ (Rückmeldung → „Schreib uns“ ohne Mail-App) kopiert „Adresse kopieren“ die Adresse weiterhin in die Zwischenablage und schließt den Dialog
- [ ] In den Einstellungen für geführte Meditationen öffnet sich die Auswahl der Vorbereitungszeit weiterhin, und die gewählte Dauer wird übernommen
- [ ] Der Bearbeiten-Dialog einer Meditation zeigt seine Titelleiste unverändert
- [ ] Alle Unit-Tests und alle UI-Tests auf dem Emulator laufen grün

---

## Manueller Test

1. Android-Build ausführen und die Compiler-Ausgabe nach `w:` durchsuchen
2. Alle oben genannten Bildschirme nacheinander öffnen und eine Einstellung ändern
3. Im Dialog „Keine Mail-App“ die Adresse kopieren und irgendwo einfügen
4. Einstellungen für geführte Meditationen → Vorbereitungszeit einschalten, die Dauer auf 30 s ändern
5. Erwartung: Es bleiben nur die Warnungen aus den Folgetickets; alle Bildschirme, das Kopieren und die Auswahl funktionieren wie vorher

---

## Nicht Teil dieses Tickets

- Wischen-zum-Löschen in Bibliothek und Suche: Die veraltete Möglichkeit, eine Wischgeste per Rückfrage abzubrechen, hat keinen direkten Ersatz. Folgeticket android-093.
- Steuerung auf dem Sperrbildschirm und Wiedergabe-Benachrichtigung über die alte MediaSession-Kompatibilitätsbibliothek. Der Umstieg ist eine Architekturänderung am Kern-Anwendungsfall. Folgeticket android-094.

---

## Hinweise

- Vollständige Warnungsliste aus einem Build mit `--rerun-tasks` am 2026-10-10: 76 Veraltungswarnungen und 50 fehlende Opt-ins, davon 37 in den beiden ausgenommenen Fällen.
- Entscheidung (2026-10-10): Was einen direkten Ersatz hat, gehört in dieses Ticket, auch die Umstellung der UI-Test-Regeln auf die v2-API. Wischen-zum-Löschen und MediaSession kommen in eigene Tickets.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->

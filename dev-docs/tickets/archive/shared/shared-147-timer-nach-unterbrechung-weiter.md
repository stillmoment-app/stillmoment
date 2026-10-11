---
id: shared-147
title: "Timer läuft nach einer Unterbrechung vollständig weiter"
status:
  ios: done
  android: done
phase: 1-Quick Fix
priority: mittel
depends_on: []
---

# Ticket shared-147: Timer läuft nach einer Unterbrechung vollständig weiter

**Plan iOS**: `dev-docs/tickets/plans/shared-147-ios.md`
**Plan Android**: `dev-docs/tickets/plans/shared-147-android.md`

## Was

**Beobachtet:** Laut Code, nicht am Gerät beobachtet (2026-10-11, beim Abgleich für ios-065):
- **Unterbrechung während des Start-Gongs (iOS):** Die Zeit läuft weiter, und am Ende kommt der End-Gong. Die eigentliche Meditation beginnt aber nie: Hintergrundklang und Intervall-Gongs fehlen für die ganze Sitzung, ohne Hinweis. Ursache: Der Timer wartet auf das Ende des Start-Gongs, und ein unterbrochener Gong meldet kein Ende.
- **Unterbrechung während des End-Gongs (iOS):** Der Timer bleibt beim End-Gong stehen. Die Abschlussansicht erscheint nicht, und die App hält den Ton im Hintergrund weiter aktiv, bis man den Timer zurücksetzt.
- **Unterbrechung während der Meditation (Android):** Der Hintergrundklang bleibt nach dem Anruf aus.
- Wie sich der Start- und End-Gong auf Android und der Hintergrundklang auf iOS nach einer Unterbrechung verhalten, ist nicht geprüft.

**Erwartet:** Der Timer zählt während einer Unterbrechung weiter wie bisher. Gibt das System den Ton danach wieder frei, klingt alles wieder wie vorher: Hintergrundklang, Intervall-Gongs, End-Gong. Ein unterbrochener Gong hält den Ablauf nicht an. Beide Plattformen verhalten sich gleich.
**Umstände:** Jede Unterbrechung durch Anruf, Siri oder Wecker während einer stillen Meditation.

## Warum

Standardfall: Meditation starten, Telefon weglegen. Ein kurzer Anruf darf die Sitzung nicht unbemerkt verändern: keine fehlenden Intervall-Gongs, kein ausbleibender Hintergrundklang, kein Timer, der nach dem Ende im Hintergrund weiterläuft und Akku kostet.

---

## Akzeptanzkriterien

- [ ] Nach einer Unterbrechung während des Start-Gongs läuft die Meditation mit Hintergrundklang und Intervall-Gongs weiter
- [ ] Nach einer Unterbrechung während des End-Gongs erscheint die Abschlussansicht, und im Hintergrund läuft kein Ton mehr
- [ ] Nach einer Unterbrechung während der Meditation klingt der Hintergrundklang wieder, sobald das System den Ton freigibt
- [ ] Die Restzeit stimmt nach der Unterbrechung, der Timer hat während des Anrufs weitergezählt
- [ ] Ohne Unterbrechung klingen Gongs und Hintergrundklang wie bisher, auch bei gesperrtem Bildschirm
- [ ] iOS und Android verhalten sich in allen Fällen gleich

---

## Manueller Test

Anrufe lassen sich im Simulator bzw. Emulator nicht zuverlässig auslösen. Pro Plattform am Gerät, mit Hintergrundklang und Intervall-Gongs (z. B. jede Minute):

1. Timer starten, Bildschirm sperren, während des Start-Gongs anrufen lassen, nicht rangehen
2. Erwartung: Danach klingen Hintergrundklang und Intervall-Gongs
3. Kurze Meditation (1 Minute), während des End-Gongs anrufen lassen
4. Erwartung: Danach zeigt die App die Abschlussansicht
5. Während der Meditation anrufen lassen, rangehen, auflegen
6. Erwartung: Der Hintergrundklang klingt wieder, die Restzeit stimmt

---

## Hinweise

- Gleiche Regel wie für die geführte Meditation (shared-146): Eine Unterbrechung hält den Ton an; gibt das System ihn wieder frei, läuft weiter, was lief. Keine Anruf-Erkennung, keine zusätzliche Berechtigung.
- Die geführte Meditation löst das Problem des unterbrochenen Start-Gongs bereits (shared-143): Dort gilt ein unterbrochener Gong als beendet.
- Erst die Verdachtsfälle mit Tests belegen, die fehlschlagen; was sich nicht bestätigt, im Ticket vermerken.

### Befunde der Umsetzung

Per fehlschlagendem Unit-Test belegt, nicht am Gerät:
- **iOS:** Alle drei Verdachtsfälle bestätigt. Start- und End-Gong meldeten nach einer Unterbrechung kein Ende; der Hintergrundklang pausierte nicht und kam nicht wieder. Zusätzlich: Die Restzeit ging um die Dauer verloren, in der iOS die App angehalten hatte (der Timer zählte Takte statt Zeit).
- **Android:** Hintergrundklang bleibt nach dem Anruf aus: bestätigt. Timer hängt im Start- oder End-Gong: nicht bestätigt; die Gongs liefen bisher weiter und meldeten ihr Ende. Zusätzlich gefunden: Endete der Start-Gong während eines Anrufs, verweigerte Android den Ton, die App zeigte „Klang konnte nicht abgespielt werden“, und der Hintergrundklang fehlte die ganze Sitzung. Gongs klangen in den Anruf hinein.
- **Beide Plattformen:** Nach einem dauerhaften Verlust des Tons (eine andere App spielt Musik) bleibt der Timer bis zum Ende still, auch ohne End-Gong; er zählt weiter, und die Abschlussansicht erscheint.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->

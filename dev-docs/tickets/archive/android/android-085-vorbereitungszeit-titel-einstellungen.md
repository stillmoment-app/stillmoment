---
id: android-085
title: "Vorbereitungszeit in den Einstellungen mit Titel und Untertitel wie auf iOS"
status: done
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket android-085: Vorbereitungszeit in den Einstellungen mit Titel und Untertitel wie auf iOS

## Was

**Beobachtet:** In den Einstellungen, Abschnitt „Geführte Meditationen“, zeigt Android neben dem Schalter nur einen kleinen, grauen Text „Zeit zum Ankommen bevor das Audio startet“ (EN „Time to settle in before the audio starts“). Die Überschrift „Vorbereitungszeit“ fehlt.

**Erwartet:** Wie auf iOS steht dort der Titel „Vorbereitungszeit“ (EN „Preparation Time“) und darunter der Untertitel „Zeit zum Einstimmen, bevor die Meditation beginnt“ (EN „Time to settle before the meditation starts“).

**Umstände:** Immer, in beiden Sprachen. Aufgefallen beim Screenshot-Vergleich zu shared-135.

## Warum

Ohne Titel ist nicht auf einen Blick erkennbar, was der Schalter einstellt; die Zeile sieht anders aus als alle anderen Einträge in den Einstellungen. Außerdem weichen iOS und Android im Text voneinander ab, obwohl beide Plattformen identisch sein sollen.

---

## Akzeptanzkriterien

- [ ] Die Zeile zur Vorbereitungszeit im Abschnitt „Geführte Meditationen“ zeigt den Titel „Vorbereitungszeit“ / „Preparation Time“ und darunter den Untertitel „Zeit zum Einstimmen, bevor die Meditation beginnt“ / „Time to settle before the meditation starts“
- [ ] Titel und Untertitel sehen aus wie Titel und Untertitel der Einträge im Abschnitt „Rückmeldung“ (Titel in normaler Textgröße, Untertitel kleiner und in der Sekundärfarbe)
- [ ] Der Text „Zeit zum Ankommen bevor das Audio startet“ / „Time to settle in before the audio starts“ erscheint nirgends mehr
- [ ] TalkBack sagt beim Schalter weiterhin an, worum es geht und ob die Vorbereitungszeit an oder aus ist
- [ ] Ein- und Ausschalten sowie die Auswahl der Dauer funktionieren wie bisher

---

## Manueller Test

1. Einstellungen öffnen
2. Abschnitt „Geführte Meditationen“ ansehen
3. Erwartung: Titel „Vorbereitungszeit“, darunter „Zeit zum Einstimmen, bevor die Meditation beginnt“, rechts der Schalter — wie auf iOS
4. Schalter einschalten → Auswahl der Dauer erscheint wie bisher
5. Sprache auf Englisch → „Preparation Time“ / „Time to settle before the meditation starts“

---

## Hinweise

- Maßstab ist der heutige iOS-Stand (Wortlaut und Aufbau). iOS bleibt unverändert.

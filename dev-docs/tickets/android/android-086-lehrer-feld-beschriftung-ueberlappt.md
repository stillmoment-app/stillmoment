---
id: android-086
title: "Bearbeiten-Blatt: Beschriftung des Lehrer-Felds liegt über dem vorausgefüllten Namen"
status: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket android-086: Bearbeiten-Blatt: Beschriftung des Lehrer-Felds liegt über dem vorausgefüllten Namen

## Was

**Beobachtet:** Im Bearbeiten-Blatt steht die Beschriftung "Teacher" (bzw. "Lehrer") im Feld übereinander mit dem vorausgefüllten Wert, z.B. "Deutschlandfunk Nova". Beides ist schwer lesbar. Das Feld "Name" darunter zeigt seine Beschriftung korrekt oben am Rahmen.
**Erwartet:** Ist das Lehrer-Feld ausgefüllt, sitzt seine Beschriftung oben am Rahmen wie beim Feld "Name"; Beschriftung und Wert überlappen nie.
**Umstände:** Emulator, App auf Englisch, 2026-10-09. Podcast-Folge aus Chrome (podcasts.apple.com) geteilt; Still Moment öffnet das Bearbeiten-Blatt mit vorausgefülltem Lehrer. Ob es auch bei anderen Wegen ins Bearbeiten-Blatt auftritt (Datei-Import, Bearbeiten einer vorhandenen Meditation), ist nicht geprüft.

## Warum

Das Bearbeiten-Blatt ist nach jedem Import der erste Eindruck. Übereinanderliegender Text wirkt kaputt und ist schwer zu lesen, gerade im Moment, in dem man die Angaben prüfen soll.

---

## Akzeptanzkriterien

- [ ] Nach dem Teilen einer Podcast-Folge mit bekanntem Lehrer zeigt das Lehrer-Feld den Wert im Feld und die Beschriftung oben am Rahmen, ohne Überlappung
- [ ] Dasselbe gilt für jeden anderen Weg ins Bearbeiten-Blatt, bei dem das Lehrer-Feld ausgefüllt ist (Link-Import, Datei-Import mit Lehrer aus den Dateiangaben, Bearbeiten einer vorhandenen Meditation)
- [ ] Ist das Lehrer-Feld leer und nicht ausgewählt, zeigt es weiterhin nur die Beschriftung im Feld
- [ ] Die Vorschläge für Lehrer:innen beim Tippen erscheinen weiterhin

---

## Manueller Test

1. In Chrome eine Folge auf podcasts.apple.com öffnen, z.B. https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344
2. Teilen → Still Moment
3. Erwartung: Bearbeiten-Blatt, im Lehrer-Feld "Deutschlandfunk Nova", Beschriftung oben am Rahmen, keine Überlappung
4. Eine vorhandene Meditation mit Lehrer zum Bearbeiten öffnen
5. Erwartung: wie in 3

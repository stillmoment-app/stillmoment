---
id: ios-061
title: "Geteilter Link ohne Pfad: „Fast geschafft“, aber die App übernimmt nichts"
status: todo
phase: 1-Quick Fix
priority: mittel
depends_on: []
---

# Ticket ios-061: Geteilter Link ohne Pfad: „Fast geschafft“, aber die App übernimmt nichts

## Was

**Beobachtet:** Wird eine Adresse ohne Pfad an Still Moment geteilt, z. B. `https://www.example.com/` oder `https://www.example.com/?id=1`, zeigt die Teilen-Ansicht „Fast geschafft“. Beim Öffnen der App passiert nichts: kein Ladefenster, kein Bearbeiten-Blatt, keine Meldung. Der Eintrag bleibt unsichtbar liegen und wird auch nach 24 Stunden nicht weggeräumt.

**Erwartet:** Die App behandelt eine solche Adresse wie jeden anderen geteilten Link, so wie Android: Liegt dort eine Aufnahme, wird sie importiert. Liegt dort eine Webseite, erscheint „Keine Aufnahme gefunden“.

**Umstände:** Nur iOS. Betroffen sind Adressen, deren Pfad leer ist oder nur aus „/“ besteht, auch mit Abfrage-Teil.

## Warum

Die Teilen-Ansicht verspricht, dass die App den Eintrag übernimmt. Bleibt danach alles still, weiß der Nutzer nicht, was schiefging. Android verhält sich bereits wie erwartet.

---

## Akzeptanzkriterien

- [ ] `https://www.example.com/` geteilt: Beim Öffnen der App erscheint das Ladefenster und danach „Keine Aufnahme gefunden“.
- [ ] Eine Adresse ohne Pfad, die direkt eine MP3 ausliefert, wird importiert. Das Bearbeiten-Blatt erscheint.
- [ ] `https://www.example.com/?id=1` verhält sich wie `https://www.example.com/`.
- [ ] Erhalt: Links mit Pfad (z. B. `https://www.audiodharma.org/talks/25401/download`) werden wie bisher importiert, einschließlich „Schon da“ und der Regel „der zuletzt geteilte gewinnt“ aus shared-132.
- [ ] Erhalt: Geteilte Einträge, die nie übernommen werden, werden weiterhin nach 24 Stunden weggeräumt.

---

## Manueller Test

1. Still Moment schließen.
2. In Safari `https://www.example.com/` an Still Moment teilen. Die Teilen-Ansicht zeigt „Fast geschafft“.
3. Still Moment öffnen.
4. Erwartung: Ladefenster, dann „Keine Aufnahme gefunden“.

---

## Hinweise

- Entscheidung des Users: normal laden wie Android, nicht schon in der Teilen-Ansicht ablehnen. Sonst ließe sich eine Aufnahme unter so einer Adresse nie importieren.
- „Schon da“ erkennt Duplikate an Dateiname und Größe. Bei Adressen ohne Pfad gibt es keinen sprechenden Dateinamen. Android nennt solche Dateien ersatzweise „audio.mp3“ bzw. „audio.m4a“, verschiedene Aufnahmen dürfen dadurch nicht fälschlich als „Schon da“ gelten.

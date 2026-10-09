---
id: ios-060
title: "Import: Bearbeiten-Blatt öffnet nicht, wenn die App in einem anderen Tab steht"
status: todo
phase: 1-Quick Fix
priority: hoch
depends_on: []
---

# Ticket ios-060: Import: Bearbeiten-Blatt öffnet nicht, wenn die App in einem anderen Tab steht

## Was

**Beobachtet:** Der User teilt eine Folge aus Apple Podcasts an Still Moment. Die App lädt die Datei und wechselt in die Bibliothek, aber das Bearbeiten-Blatt mit Titel und Lehrer erscheint nicht. Der Import ist damit verloren. Teilt der User dieselbe Folge noch einmal, öffnet sich das Blatt.

**Erwartet:** Das Bearbeiten-Blatt öffnet sich beim ersten Import, egal in welchem Tab die App vorher stand.

**Umstände:** Die App steht im Timer- oder Einstellungen-Tab, und die Bibliothek wurde seit dem Start der App noch nicht angezeigt. Das gilt für einen Kaltstart durch das Teilen ebenso wie für eine schon laufende App. Nachgestellt auf einem iPhone 13 mini: App starten, Einstellungen-Tab offen, Podcast-Folge teilen.

## Warum

Der Import ist der Weg in die Bibliothek, das Kernfeature. Scheitert er beim ersten Versuch ohne jede Meldung, hält der User das Teilen für kaputt.

---

## Akzeptanzkriterien

- [ ] Steht die App im Einstellungen- oder Timer-Tab und wurde die Bibliothek seit dem Start noch nicht angezeigt, öffnet ein Podcast-Import das Bearbeiten-Blatt mit den Vorschlägen für Titel und Lehrer
- [ ] Dasselbe gilt für den Link-Import, für eine geteilte Audiodatei und für „Öffnen mit"
- [ ] Gilt sowohl, wenn das Teilen die App startet, als auch bei bereits laufender App
- [ ] Ein Import öffnet das Bearbeiten-Blatt genau einmal: Nach Speichern oder Abbrechen öffnet es sich beim nächsten Wechsel in die Bibliothek nicht erneut
- [ ] Steht die App bereits in der Bibliothek, öffnet sich das Bearbeiten-Blatt weiterhin wie bisher

---

## Manueller Test

1. Still Moment starten, in den Einstellungen-Tab wechseln
2. App beenden (aus dem App-Umschalter wischen)
3. In Apple Podcasts eine einzelne Folge an Still Moment teilen
4. Erwartung: Die App lädt die Folge, wechselt in die Bibliothek, und das Bearbeiten-Blatt mit Titel und Lehrer öffnet sich beim ersten Versuch

---

## Hinweise

- Die Geräte-Logs des nachgestellten Fehlers zeigen: Folge gefunden, Datei geladen, Vorschläge gelesen. Erst danach geht es schief. Nur das Bearbeiten-Blatt öffnet sich nicht, weil die Bibliothek beim Eintreffen des Imports noch nicht aufgebaut ist.
- Android ist nicht betroffen: Dort übernimmt die Bibliothek einen ausstehenden Import auch dann, wenn sie erst danach aufgebaut wird.

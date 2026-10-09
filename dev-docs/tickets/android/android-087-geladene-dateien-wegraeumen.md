---
id: android-087
title: "Beim Link- und Podcast-Import geladene Dateien werden weggeräumt"
status: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket android-087: Beim Link- und Podcast-Import geladene Dateien werden weggeräumt

## Was

**Beobachtet:** Beim Link-Import und Podcast-Import lädt die App die Aufnahme herunter. Nach dem Import legt sie eine eigene Kopie in der Bibliothek ab. Die heruntergeladene Datei bleibt trotzdem dauerhaft auf dem Gerät liegen, ebenso nach verworfenem Bearbeiten-Blatt, nach „Schon da“, nach einem Fehler beim Auslesen und wenn ein fertig geladener Import durch einen neuer geteilten abgelöst wird. Weggeräumt wird nur ein Download, der während des Ladens abbricht oder scheitert. Jeder Import belegt so den Speicherplatz der Aufnahme doppelt, bei Podcast-Folgen oft 50 bis 100 MB.

**Erwartet:** Ist ein Import abgeschlossen, egal wie (gespeichert, verworfen, „Schon da“, Fehler, abgelöst), ist die heruntergeladene Datei weg. Reste aus früheren Versionen oder aus Abstürzen räumt die App beim Start weg.

**Umstände:** Nur Android. iOS legt geladene Dateien im temporären Ordner ab, den das System selbst leert.

## Warum

Der Speicherverbrauch wächst unbemerkt mit jedem Import. In den Systemeinstellungen sieht der Nutzer eine Meditations-App, die ein Vielfaches ihrer Bibliothek belegt.

---

## Akzeptanzkriterien

- [ ] Nach dem Speichern eines Link-Imports belegt die App nur noch den Speicher der Kopie in der Bibliothek, nicht den doppelten.
- [ ] Gleiches nach verworfenem Bearbeiten-Blatt, nach „Schon da“, nach „Keine Aufnahme gefunden“ und nach einem abgelösten Import (shared-132).
- [ ] Beim App-Start sind Reste früherer Downloads weg, auch solche aus Versionen vor diesem Ticket.
- [ ] Erhalt: Importierte Meditationen spielen weiterhin ab, auch nach einem App-Neustart.
- [ ] Erhalt: Ein Import, der gerade lädt oder dessen Bearbeiten-Blatt offen ist, bleibt intakt, auch über einen Wechsel von Dunkelmodus oder Schriftgröße hinweg. Speichern danach funktioniert.
- [ ] Erhalt: „Erneut versuchen“ nach einem Fehler lädt wie bisher neu.
- [ ] Erhalt: Per „Öffnen mit“ oder Teilen übergebene Dateien anderer Apps werden nie gelöscht.

---

## Manueller Test

1. In den Android-Einstellungen unter Apps → Still Moment → Speicher den Cache-Wert notieren.
2. `https://www.audiodharma.org/talks/25401/download` an Still Moment teilen, speichern.
3. Erwartung: Der Cache-Wert ist nicht um rund 12 MB gewachsen. Die Meditation spielt ab.
4. Denselben Link noch einmal teilen („Schon da“) und einen weiteren teilen, das Bearbeiten-Blatt verwerfen. Erwartung: Der Cache-Wert bleibt gleich.

---

## Hinweise

- Entscheidung des Users: zusätzlich beim App-Start aufräumen, damit auch Altbestände bestehender Nutzer verschwinden.
- Zwei fast gleichzeitige Downloads (zweimal schnell geteilt) dürfen sich beim Ablegen und Wegräumen nicht in die Quere kommen.

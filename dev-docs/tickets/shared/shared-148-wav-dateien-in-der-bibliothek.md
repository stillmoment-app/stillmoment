---
id: shared-148
title: "WAV-Dateien in der Bibliothek importieren"
status:
  ios: todo
  android: todo
phase: 3-Feature
priority: mittel
depends_on: []
---

# Ticket shared-148: WAV-Dateien in der Bibliothek importieren

## Was

WAV-Dateien lassen sich auf beiden Plattformen über jeden Importweg der Bibliothek importieren und abspielen: Dateiauswahl, Teilen an Still Moment, „Öffnen in“ / „Öffnen mit“, Link-Import und Podcast-Import. Vor dem Import sehr großer Dateien weist die App auf die Größe hin.

## Warum

Kursleiter verteilen Kurs-Audios als Dateien, die Teilnehmer selbst in die App bringen müssen. Wer heute eine WAV-Datei hat, scheitert je nach Weg und Plattform unterschiedlich: Auf iOS klappt die Dateiauswahl zufällig, Teilen wird abgelehnt, „Öffnen in“ bietet Still Moment gar nicht an; auf Android wird WAV überall abgelehnt. Für eigene Soundscapes des Timers kann die App WAV auf beiden Plattformen bereits. Unkomprimiertes WAV ist etwa zehnmal so groß wie MP3 (eine Stunde ≈ 600 MB); ohne Hinweis füllt ein einzelner Import unbemerkt den Speicher.

---

## Akzeptanzkriterien

### Importwege
- [ ] Eine WAV-Datei aus der Dateiauswahl der Bibliothek öffnet das Bearbeiten-Blatt und landet nach dem Speichern in der Bibliothek
- [ ] Teilen einer WAV-Datei an Still Moment (z.B. aus Dateien, Mail, Messenger) importiert sie wie eine MP3
- [ ] Bei einer WAV-Datei bietet das System Still Moment unter „Öffnen in“ / „Öffnen mit“ an; der Import läuft wie bei MP3
- [ ] Link-Import nimmt zusätzlich die Server-Dateitypen `audio/wav`, `audio/x-wav`, `audio/wave` und `audio/vnd.wave` an, auf beiden Plattformen dieselbe Liste
- [ ] Eine per Link geladene WAV-Datei wird als WAV übernommen und spielt ab, auch wenn der Server `application/octet-stream` oder gar keinen Dateityp meldet und die Adresse auf `.wav` endet
- [ ] Podcast-Import verhält sich bei einer WAV-Folge wie der Link-Import
- [ ] Meldungen der Bibliothek-Importwege, die unterstützte Formate nennen, nennen „MP3, M4A und WAV“

### Große Dateien
- [ ] Ist eine Datei größer als 300 MB (beliebiges Format), sieht der Nutzer vor dem Übernehmen in die Bibliothek einen Hinweis mit der Dateigröße und wählt „Trotzdem importieren“ oder „Abbrechen“
- [ ] „Abbrechen“ legt keinen Eintrag an und hinterlässt keine Kopie der Datei in der App
- [ ] Dateien bis 300 MB werden ohne Hinweis importiert

### WAV in der Bibliothek
- [ ] Eine importierte WAV-Meditation zeigt ihre Dauer an und erscheint in der passenden Stufe des Dauer-Filters
- [ ] Der Zuschnitt-Editor zeigt für eine WAV-Meditation eine Wellenform
- [ ] Ohne ID3-Angaben schlägt das Bearbeiten-Blatt den Titel aus dem Dateinamen vor, wie bei MP3 ohne Tags

### Soundscape-Import (Android)
- [ ] Beim Import eines eigenen Soundscapes in einem nicht unterstützten Format zeigt Android dieselbe übersetzte Meldung wie iOS: „Format nicht unterstützt: .xyz. Unterstützt: MP3, M4A, WAV.“

### Erhalt
- [ ] Die iOS-Dateiauswahl der Bibliothek nimmt weiterhin auch andere Audioformate an, die sie heute annimmt (z.B. AIFF, FLAC)
- [ ] Link- und Podcast-Import lehnen andere Dateitypen (z.B. `audio/ogg`, `audio/x-mpegurl`) weiterhin ab, bevor die Datei vollständig geladen ist
- [ ] Lange Podcast-Folgen (mehrere Stunden, MP3) lassen sich weiterhin ohne Hinweis importieren, solange sie 300 MB nicht überschreiten
- [ ] Import von MP3 und M4A über alle Wege verhält sich unverändert

---

## Manueller Test

Teilen und „Öffnen in“ aus fremden Apps sowie die Wiedergabe bei gesperrtem Bildschirm lassen sich nur am Gerät prüfen.

1. WAV-Datei (ca. 30 Minuten, > 300 MB) in Dateien ablegen, an Still Moment teilen
2. Erwartung: Hinweis mit Dateigröße; „Trotzdem importieren“ öffnet das Bearbeiten-Blatt
3. Meditation speichern, starten, Bildschirm sperren
4. Erwartung: Wiedergabe läuft bis zum Ende weiter, Start- und End-Gong spielen
5. Kleine WAV-Datei (< 300 MB) über „Öffnen in“ / „Öffnen mit“ importieren
6. Erwartung: kein Hinweis, Import wie bei MP3

---

## Nicht Teil dieses Tickets

- Umwandeln von WAV in ein kleineres Format beim Import
- Beschränken der iOS-Dateiauswahl auf MP3, M4A und WAV
- Ablehnen großer Dateien oder eine Prüfung des freien Speichers

---

## Hinweise

- Entscheidung: Die iOS-Dateiauswahl bleibt bewusst offen für weitere Formate; iOS darf dort großzügiger sein als Android.
- Entscheidung: Der Größenhinweis gilt für alle Formate, nicht nur WAV. Bei 300 MB bleiben lange MP3-Podcasts (3 Stunden ≈ 170 MB) unberührt.
- Erweitert die Annahme-Liste aus shared-131; deren Hinweis „welche Formate die Bibliothek abspielen kann (MP3, M4A), bleibt unverändert“ ist damit überholt.
- Eigene Soundscapes (shared-065) unterstützen WAV bereits; dort ändert sich außer der Android-Meldung nichts.
- WAV-Dateien tragen meist keine ID3-Angaben; Lehrer bleibt dann leer.
- Anlass ist die App-Store-Analyse vom Oktober 2026 (Kurs-Audios als Kernszenario). In der Stichprobe öffentlicher Kursseiten wurden nur MP3 und M4A verteilt; WAV ist eine Vorsorge für eigene Aufnahmen und Ausnahmen, kein belegter Massenfall.

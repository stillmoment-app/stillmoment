# Ticket shared-046: Share Extension ("Teilen")

**Status**: [~] IN PROGRESS
**Plan**: [Implementierungsplan](../plans/shared-046.md)
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~1.5d (URL-Download aus Chrome, Intent-Filter, Download-UX)
**Phase**: 3-Feature

---

## Was

Audio-Dateien koennen ueber das System-Share-Sheet ("Teilen") an Still Moment gesendet werden — z.B. direkt aus Safari, Mail, WhatsApp oder Telegram.

## Warum

"Oeffnen mit" (shared-045) deckt nur die Files-App und direkte Datei-Oeffnung ab. Wer eine MP3 im mobilen Browser oeffnet, muss sie erst in Dateien speichern und dann in Still Moment importieren. Das Share Sheet wuerde diesen Umweg eliminieren.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-045, shared-073 |
| Android   | [ ]    | shared-045, shared-073 (ACTION_SEND fuer Dateien existiert, URL-Share aus Chrome fehlt — neuer Code noetig) |

---

## Scope

- **Nur Share Sheet ("Teilen").** File Association ("Oeffnen mit") ist shared-045.
- **Einzeldatei-Import.** Mehrere Dateien gleichzeitig sind nicht in-scope (siehe shared-044 Batch Import).
- **Unterstuetzte Formate: MP3 und M4A.** Registrierung nur fuer diese spezifischen Typen, nicht `audio/*`.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] MP3- und M4A-Dateien koennen ueber das System-Share-Sheet an Still Moment gesendet werden
- [ ] Still Moment erscheint im Teilen-Dialog mit App-Icon
- [ ] Import erfolgt ueber den bestehenden Import-Flow (Datei kopieren, Metadaten extrahieren, Library aktualisieren)
- [ ] Import-Typ-Auswahl (Meditation / Klangatmosphaere / Einstimmung) wird angezeigt — gleicher Flow wie bei "Oeffnen mit" (shared-045/shared-073)
- [ ] Erfolgs-Feedback nach Import
- [ ] Funktioniert wenn App nicht laeuft, im Hintergrund, oder im Vordergrund
- [ ] Lokalisiert (DE + EN)

### Fehlerfaelle

- [ ] Unerwartetes Format: Fehlermeldung ("Format nicht unterstuetzt")
- [ ] Korrupte/unlesbare Audio-Datei: Fehlermeldung ("Datei konnte nicht importiert werden")
- [ ] Duplikat (Datei bereits importiert): Hinweis ("Meditation bereits in der Bibliothek")

### Tests
- [ ] Unit Tests iOS (Inbox-Handling, URL-Validierung, Download, Fehlerfaelle)
- [ ] Unit Tests Android (nur falls neuer Code noetig — siehe Plan)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Oeffne Safari/Chrome und lade eine MP3-Datei herunter
2. Tippe auf "Teilen" → waehle "Still Moment"
3. Erwartung: Typ-Auswahl erscheint, Datei wird importiert, Meditation erscheint in Library
4. Wiederhole aus einer anderen App (z.B. Mail-Anhang, WhatsApp Audio)
5. Teste App-Kaltstart: App beenden, dann Datei teilen → App startet und importiert
6. Teile eine bereits importierte Datei → Erwartung: Duplikat-Hinweis
7. **Android-spezifisch:** Chrome → MP3 im Player oeffnen → Drei-Punkte-Menue → Teilen → Still Moment waehlen → Erwartung: Download-Indikator, dann Typ-Auswahl
8. **Android-spezifisch:** Chrome → beliebige Webseite teilen → Still Moment waehlen → Erwartung: App schliesst sich still (kein Fehler)
9. **Android-spezifisch:** Dateimanager → MP3 teilen → Still Moment → Erwartung: direkter Import ohne Download

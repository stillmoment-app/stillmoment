# Ticket ios-042: Share-Import immer als Meditation

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Geringer Aufwand, betrifft aber den Share-Eintrittspfad (Share Extension, "Oeffnen mit", URL-Download via Inbox) und den anschliessenden Library-Flow inkl. Edit-Sheet — Regressionen waeren sofort fuer User sichtbar.
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Datei-Import via Share / "Oeffnen mit" fragt nicht mehr nach dem Typ. Geteilte Audiodateien werden immer als Meditation in die Library uebernommen. Die Typ-Auswahl ("Meditation" vs. "Hintergrund-Sound") aus shared-073 entfaellt vollstaendig.

## Warum

Hintergrund-Sounds werden inzwischen direkt im Settings-Menue bei der Sound-Auswahl importiert. Beim Share via App-Sheet ist der Fall "Meditation" der Standardfall — die Typ-Auswahl ist ein zusaetzlicher Klick ohne Mehrwert und stoert den schnellen Import-Flow.

---

## Akzeptanzkriterien

### Feature
- [ ] Eine via Share oder "Oeffnen mit" empfangene MP3/M4A erscheint ohne Zwischenfrage in der Library als Meditation.
- [ ] Direkt nach dem Import oeffnet sich das Edit-Sheet fuer die importierte Meditation, der Library-Tab ist aktiv.
- [ ] Eine doppelte Datei (gleicher Name + Groesse wie eine bereits importierte Meditation) wird mit der bestehenden "bereits importiert"-Meldung abgelehnt — Titel und Lehrer werden genannt, wenn bekannt.
- [ ] Eine nicht unterstuetzte Datei (kein MP3/M4A) zeigt den bestehenden Format-Fehler-Alert.
- [ ] Geteilter Link → Download → Import funktioniert wie zuvor; liefert der Link keine Audio-Datei, erscheint weiterhin der "kein Audio gefunden"-Alert.
- [ ] Die Auswahl-Halbblende ("Worum handelt es sich?" mit Meditation/Hintergrund-Sound) ist aus der App vollstaendig verschwunden — auch im Code (View, Domain-Typ, Tests, ungenutzte Localization-Keys).
- [ ] Lokalisiert (DE + EN): keine waisen `import.type.*`-Keys mehr.

### Tests
- [ ] Unit-Test deckt ab: Share-Import einer gueltigen Datei fuehrt direkt zu einem Meditation-Eintrag (ohne dass eine Typ-Auswahl-Property gesetzt werden muss).
- [ ] Unit-Test deckt ab: Duplikat-Erkennung greift beim direkten Share-Import.
- [ ] Unit-Test deckt ab: Format-Fehler beim Share-Import.
- [ ] Tests, die ausschliesslich den entfernten Typ-Auswahl-Pfad oder den Soundscape-Zweig im Share-Flow abdecken, sind geloescht.

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Vereinfachung des Share-Flows).

---

## Manueller Test

1. App starten, sicherstellen dass mindestens eine Meditation in der Library liegt (fuer Duplikat-Test).
2. In der Dateien-App eine neue MP3 (oder M4A) per "Teilen" → "Still Moment" auswaehlen.
3. Erwartung: Kein Auswahl-Sheet, App wechselt zum Library-Tab, Edit-Sheet fuer die neue Meditation oeffnet sich.
4. Edit-Sheet abbrechen oder speichern → Meditation ist in der Library sichtbar.
5. Dieselbe Datei nochmal teilen.
6. Erwartung: Alert "bereits importiert" mit Titel/Lehrer-Hinweis.
7. Eine PDF-Datei per Share zu Still Moment senden.
8. Erwartung: Alert "nicht unterstuetztes Format".
9. Audio-URL aus Safari teilen → Download laeuft → Import erfolgt wie unter Schritt 3.

---

## Referenz

- Vorgaenger-Ticket: [shared-073 — Datei-Import mit Typ-Auswahl](../shared/shared-073-import-typ-auswahl.md) (wird durch dieses Ticket fachlich abgeloest)
- Share-Pipeline: [shared-046 — Share Extension](../shared/shared-046-share-extension.md), [shared-045 — File Association](../shared/shared-045-share-sheet-file-association.md)
- iOS-Code-Bereich: `ios/StillMoment/Application/` (Share-/Inbox-Eintrittspfad), `ios/StillMoment/Presentation/Views/Shared/` (zu entfernende View)

---

## Hinweise

- Der bestehende Library-Mechanismus zum Oeffnen des Edit-Sheets nach Import (shared-031) bleibt unveraendert — der direkte Import muss nur weiterhin den "importierte Meditation"-Hinweis publizieren, damit die Library das Sheet automatisch zeigt.
- Der InboxHandler nutzt heute den Sheet-Anzeige-Zustand als "Datei akzeptiert?"-Indikator fuer den Download-Fehlerpfad (`notAnAudioUrl`). Bei der Umstellung muss ein gleichwertiger Akzeptanz-Check erhalten bleiben, sonst geht der "kein Audio gefunden"-Alert verloren.
- Soundscape-Import bleibt ueber den Settings-Pfad bestehen (separater Code-Pfad, nicht Teil dieses Tickets).

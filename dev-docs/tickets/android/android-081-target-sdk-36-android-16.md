# Ticket android-081: Target API Level 36 (Android 16) fuer Google Play

**Status**: [ ] TODO
**Prioritaet**: KRITISCH
**Komplexitaet**: Der Bump selbst ist klein, das Risiko liegt in den Verhaltensaenderungen von Android 16 — vor allem darin, dass der feste Portrait-Modus auf grossen Displays nicht mehr greift. Verifikation braucht einen echten API-36-Emulator, Unit-Tests fangen davon nichts.
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Die Android-App muss auf Android 16 (API Level 36) zielen statt auf Android 15 (API 35), inklusive der dafuer noetigen Anpassungen an Android-16-Verhaltensaenderungen. Der bestehende Portrait-Only-Modus soll dabei erhalten bleiben.

Ausdruecklich **nicht** Teil dieses Tickets: adaptive Querformat-Layouts fuer Tablets und Foldables. Das ist ein eigenes Thema und braucht Entwurfsarbeit, nicht Termindruck.

## Warum

Google Play verlangt, dass der Target API Level nicht mehr als ein Jahr hinter dem aktuellen Android-Release liegt. Ab **31. August 2026** koennen wir mit API 35 kein App-Update mehr veroeffentlichen — auch keinen Bugfix. Die bereits veroeffentlichte App bleibt installierbar, aber wir waeren bis zur Umsetzung releaseunfaehig.

Google hat uns dazu am 31. Juli 2026 in der Play Console benachrichtigt. Es bleibt also rund ein Monat.

---

## Akzeptanzkriterien

### Feature
- [ ] Die App wird gegen Android 16 gebaut und zielt auf Android 16
- [ ] Ein signierter Release-Build laesst sich in der Play Console hochladen, ohne dass die Target-API-Warnung erscheint
- [ ] Die App bleibt im Hochformat — auch auf einem Tablet und einem aufgefalteten Foldable mit Android 16
- [ ] Zurueck-Navigation funktioniert unveraendert: Meditations-Editor mit Verwerfen-Schutz, Trim-Editor, Content-Guide
- [ ] Eine laufende Meditation und ein laufender Timer spielen auf Android 16 weiter, wenn das Display gesperrt wird; die Gongs kommen zur richtigen Zeit
- [ ] Datei-Import funktioniert auf Android 16: Auswahl aus dem Dateisystem, "Oeffnen mit" aus einer anderen App, "Teilen" einer Audiodatei und eines Links
- [ ] Die Anforderung von Google Play zur 16-KB-Speicherseitengroesse ist geprueft — erfuellt oder mit benanntem Handlungsbedarf dokumentiert

### Tests
- [ ] Bestehende Unit-Test-Suite ist gruen
- [ ] Bestehende Instrumented Tests laufen auf einem Android-16-Emulator gruen
- [ ] `make check` ist gruen

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `android/CLAUDE.md` — die dort dokumentierten SDK-Werte stimmen wieder

---

## Manueller Test

1. Android-16-Emulator starten (Telefon-Format), Release-Build installieren
2. Timer auf 1 Minute stellen, starten, Display sperren
3. Erwartung: Start-Gong, Intervall-Gong und End-Gong kommen bei gesperrtem Display
4. Eine gefuehrte Meditation importieren (aus einer anderen App via "Teilen"), abspielen, Display sperren
5. Erwartung: Wiedergabe laeuft weiter, Lock-Screen-Steuerung ist vorhanden und bedienbar
6. Meditations-Editor oeffnen, etwas aendern, mit der System-Zurueck-Gestensteuerung verlassen
7. Erwartung: Der Verwerfen-Schutz greift wie bisher
8. Tablet-Emulator mit Android 16 starten, App oeffnen, Geraet drehen
9. Erwartung: Die App bleibt im Hochformat

---

## Referenz

- shared-012 — Portrait-Only-Modus, die bewusste Produktentscheidung, die hier verteidigt wird
- shared-045 / shared-046 — File Association und Share-Import, die auf Android 16 nachzuprueben sind
- shared-080 — Danke-Screen ueberlebt App-Termination; Android 16 erzeugt bei Konfigurationsaenderungen haeufiger Neuerstellungen
- Doku: [Behavior changes: Apps targeting Android 16](https://developer.android.com/about/versions/16/behavior-changes-16)

---

## Hinweise

**Portrait-Only auf grossen Displays:** Ab Target API 36 ignoriert Android die Orientierungs- und Groessenbeschraenkungen einer Activity auf Displays ab 600dp Breite. Es gibt dafuer einen offiziellen, temporaeren Opt-out ueber die Manifest-Property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`. Der greift bei Target API 36 noch, bei 37 nicht mehr — wir kaufen damit Zeit, keine Loesung. Wichtig, das im Ticket-Abschluss so zu vermerken, damit beim naechsten Pflicht-Bump niemand ueberrascht ist.

**Was uns nicht betrifft:** Der Edge-to-Edge-Zwang kam bereits mit Target API 35 und ist erledigt. Die neuen Health-Permissions, die Local-Network-Permission und die Bluetooth-Aenderungen beruehren die App nicht.

**Vorhersagbare Zurueck-Gesten** sind ab Target API 36 standardmaessig aktiv. Die App nutzt nirgends die alte Zurueck-Behandlung, funktional ist damit nichts zu erwarten. Was fehlt, ist die Wisch-Vorschau-Animation an den drei Stellen mit eigener Zurueck-Behandlung (Editor, Trim-Editor, Content-Guide) — kosmetisch, und nur anfassen, wenn es ohne Risiko geht. Sonst eigenes Ticket.

**16-KB-Speicherseitengroesse** ist eine separate Play-Anforderung, kein Teil der Target-API-Regel — schlaegt aber beim selben Upload zu. Betrifft nur native Bibliotheken, bei uns kaeme sie ueber Media3 herein.

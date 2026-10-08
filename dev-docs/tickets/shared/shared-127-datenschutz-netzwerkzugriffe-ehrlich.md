# Ticket shared-127: Datenschutzerklaerung und Offline-Versprechen ehrlich formulieren

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Komplexitaet**: Rein textlich, kein App-Code. Das Risiko liegt in der Formulierung: Die Aussage muss ehrlich sein, ohne das tatsaechlich starke Datenschutz-Versprechen zu verwaessern. Mehrere Stellen (Website, Store-Texte, README) in zwei Sprachen muessen konsistent bleiben.
**Phase**: 1-Quick Fix

---

## Was

Alle oeffentlichen Aussagen zu Datenschutz und Offline-Betrieb sollen beschreiben, wann die App tatsaechlich eine Internetverbindung nutzt: ausschliesslich dann, wenn der Nutzer selbst eine Aufnahme aus einem Link importiert. Das schliesst den kommenden Podcast-Import (shared-128, shared-129) bereits ein, bei dem die App zur Suche der Folge einmalig bei Apple nachfragt.

## Warum

Die Datenschutzerklaerung sagt heute "Sendet keine Daten an externe Server" und "operates entirely offline", Store-Texte und README werben mit "100% offline — kein Internet erforderlich". Seit dem Link-Import (shared-046, shared-091) stimmt das nicht mehr: Die App laedt Dateien vom Server des Anbieters. Mit dem Podcast-Import kommt ein Abruf bei Apple hinzu. Privacy ist ein Grundwert der App — gerade deshalb muss die Beschreibung genau stimmen. Das eigentliche Versprechen bleibt unveraendert: kein Tracking, keine eigenen Server, keine Kennungen, nichts ohne Nutzeraktion.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

Betrifft keinen App-Code. Die Spalten stehen fuer die Store-Texte der jeweiligen Plattform; Website und README gelten fuer beide.

---

## Akzeptanzkriterien

### Datenschutzerklaerung (DE + EN)
- [ ] Beschreibt, dass die App nur dann eine Internetverbindung nutzt, wenn der Nutzer selbst eine Aufnahme aus einem Link importiert
- [ ] Nennt, wer dabei was sieht: der Anbieter der Aufnahme (IP-Adresse, wie bei jedem Download im Browser) und beim Podcast-Import zusaetzlich Apple (welcher Podcast nachgeschlagen wird)
- [ ] Stellt klar, dass dabei keine Geraete- oder Nutzerkennungen uebertragen werden und Still Moment selbst keine Server betreibt und nichts erfasst
- [ ] Stellt klar, dass Meditieren (Timer, Wiedergabe der Bibliothek) vollstaendig ohne Internet funktioniert
- [ ] Enthaelt keine Aussage mehr, die dem tatsaechlichen Verhalten widerspricht ("keine Daten an externe Server", "entirely offline")
- [ ] Aktualisierungsdatum angepasst

### Weitere oeffentliche Aussagen
- [ ] App-Store-Beschreibung (iOS, alle Sprachen) und Play-Store-Beschreibung (Android, alle Sprachen): "100% offline — kein Internet erforderlich" durch eine zutreffende Aussage ersetzt (z.B. Meditieren ohne Internet)
- [ ] Website-Startseite und README: Offline-Aussagen auf dieselbe zutreffende Formulierung gebracht
- [ ] Formulierungen in nicht-technischer Sprache, DE und EN inhaltlich deckungsgleich

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Datenschutzerklaerung auf der Website in DE und EN lesen
2. Erwartung: Ein nicht-technischer Leser versteht, wann die App ins Internet geht, wer dabei was erfaehrt, und dass beim Meditieren nichts uebertragen wird
3. Store-Texte, Website-Startseite und README durchsuchen
4. Erwartung: Keine Stelle verspricht mehr "100% offline" oder "kein Internet erforderlich" ohne Einschraenkung

---

## Hinweise

- Die App-Store-Datenschutzangabe ("Keine Daten erfasst") bleibt korrekt: Apple definiert "erfassen" als Uebertragung an den Entwickler oder Dritte zur Speicherung/Auswertung. Trotzdem beim Release pruefen.
- Bewusst vor dem Podcast-Import umsetzen: Die Korrektur ist wegen des Link-Imports ohnehin faellig und soll nicht auf das Feature warten. Den Apple-Abruf direkt mit aufnehmen, damit die Texte nicht zweimal angefasst werden.
- Hintergrund und Entscheidungen: `dev-docs/concepts/podcast-import.md`

---

## Referenz

- Datenschutzerklaerung: `docs/privacy.html`
- Store-Texte: Fastlane-Metadaten beider Plattformen

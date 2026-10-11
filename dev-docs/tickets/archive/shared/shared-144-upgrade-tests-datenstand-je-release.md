---
id: shared-144
title: "Upgrade-Pfad automatisch prüfen: Datenstand jeder Release-Version bleibt lesbar"
status:
  ios: done
  android: done
phase: 5-QA
priority: hoch
depends_on: []
---

# Ticket shared-144: Upgrade-Pfad automatisch prüfen: Datenstand jeder Release-Version bleibt lesbar

## Was

Ein automatischer Test belegt vor jedem Release, dass die neue Version die gespeicherten Daten jeder
bisher veröffentlichten Version vollständig übernimmt: Bibliothek, Praxis, eigene Klänge und Einstellungen.
Dafür wird der Datenstand jeder Release-Version eingefroren und als Testdaten aufbewahrt.

## Warum

Datenverlust nach einem Update ist der schwerste Fehler, den die App machen kann — die Bibliothek ist die
persönliche Sammlung des Nutzers. Früher prüfte das ein manueller Upgrade-Test in den Release-Testplänen;
er wurde zuletzt nicht durchgeführt und war auf Android kaum machbar (abweichende Signatur gegenüber der
Store-Version). Die Testpläne sind inzwischen auf einen kurzen Gerätetest gekürzt, der Upgrade-Pfad ist
seitdem ungeprüft. Dieses Ticket schließt die Lücke automatisch.

---

## Akzeptanzkriterien

- [ ] Für die aktuelle Store-Version (2.6.0) liegt ein eingefrorener Datenstand als Testdaten vor, so wie diese Version ihn auf dem Gerät hinterlässt: erzeugt vom Code dieser Version über ihre echten Speicherwege und als Rohdaten abgelegt (Schlüsselnamen und Format unverändert), nicht von Hand nachgebaut
- [ ] Der Datenstand enthält mindestens: eine Meditation mit Lehrer, Titel, gesetztem Wiedergabe-Bereich, eingeschaltetem Gong am Anfang und Gong am Ende; eine Praxis mit Dauer, Vorbereitungszeit, Gong, Intervall-Gongs und Hintergrundklang; einen eigenen Klang unter „Meine Klänge“; Darstellung „Hell“ und Vorbereitungszeit für geführte Meditationen
- [ ] Die aktuelle Version liest jeden aufbewahrten Datenstand über ihre Speicherwege und erhält alle Werte unverändert: Meditation mit Lehrer, Titel, Wiedergabe-Bereich und beiden Gong-Schaltern, alle Praxis-Werte, den eigenen Klang, Darstellung und Vorbereitungszeit
- [ ] Geht beim Lesen eines aufbewahrten Datenstands ein Wert verloren oder ändert sich, schlägt der Testlauf fehl und nennt Version und betroffenen Wert
- [ ] Die Release-Vorbereitung erzeugt den Datenstand der neuen Version selbst und nimmt ihn in den Release-Commit auf, ohne manuellen Schritt; lässt er sich nicht erzeugen, bricht sie mit einer klaren Meldung ab

---

## Manueller Test

1. In den Testdaten einen Wert eines aufbewahrten Datenstands so verändern, wie ihn eine fehlerhafte neue Version falsch lesen würde (oder in der App den Lesecode für den Wiedergabe-Bereich testweise brechen)
2. Unit-Tests der Plattform ausführen
3. Erwartung: Der Testlauf ist rot und nennt Version und Wert. Nach dem Zurücksetzen ist er grün.

---

## Nicht Teil dieses Tickets

- Installation der neuen Version über die Store-Version auf einem Gerät oder Emulator
- Datenstände von Versionen vor 2.6.0 nachträglich erzeugen (bestehende Migrationstests mit älteren Formaten bleiben, wie sie sind)

---

## Hinweise

- Entscheidung: Datenstände sammeln sich an. Jede neue Version muss **alle** bisher aufbewahrten lesen, nicht nur den der letzten Store-Version — Nutzer überspringen Updates.
- Heutige Migrationstests arbeiten mit handgeschriebenen Daten im alten Format. Sie belegen einzelne Migrationen, nicht „so hat Version X.Y tatsächlich gespeichert“. Genau diese Lücke schließt das Ticket.
- Rohdaten heißt: auf iOS der Inhalt der UserDefaults, auf Android die DataStore-Dateien. Nur so fallen auch umbenannte Schlüssel oder geänderte Formate auf. Den 2.6.0-Stand erzeugt man aus dem Tag `ios-v2.6.0` bzw. `android-v2.6.0`.
- Die nächste Version ändert bereits, was gespeichert wird (u. a. android-079, android-099, ios-062, ios-064). Das Ticket sollte deshalb vor dem nächsten Release umgesetzt sein.
- Die bestehenden Migrationstests für ältere Formate (z. B. ehemals kombinierter Gong-Schalter, Praxis aus den alten Timer-Einstellungen) bleiben unverändert und müssen grün bleiben.
- Die Audiodateien selbst gehören nicht zum Datenstand. Es genügt, dass die Verweise auf sie erhalten bleiben.
- Plattform-Asymmetrie: iOS kennt einen Rückfall für den ehemals kombinierten Gong-Schalter, Android nicht. Das Ticket ändert daran nichts, die Tests sollen es aber nicht verdecken.

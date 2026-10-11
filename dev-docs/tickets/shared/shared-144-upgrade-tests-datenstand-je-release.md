---
id: shared-144
title: "Upgrade-Pfad automatisch prüfen: Datenstand jeder Release-Version bleibt lesbar"
status:
  ios: todo
  android: todo
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

- [ ] Für die aktuelle Store-Version (2.6.0) liegt ein eingefrorener Datenstand als Testdaten vor, so wie diese Version ihn auf dem Gerät hinterlässt
- [ ] Der Datenstand enthält mindestens: eine Meditation mit Lehrer, Titel, gesetztem Wiedergabe-Bereich, eingeschaltetem Gong am Anfang und Gong am Ende; eine Praxis mit Dauer, Vorbereitungszeit, Gong, Intervall-Gongs und Hintergrundklang; einen eigenen Klang unter „Meine Klänge“; Darstellung „Hell“ und Vorbereitungszeit für geführte Meditationen
- [ ] Die aktuelle Version liest jeden aufbewahrten Datenstand und zeigt danach alle Werte unverändert an: Meditation mit Lehrer, Titel, Wiedergabe-Bereich und beiden Gong-Schaltern, alle Praxis-Werte, den eigenen Klang, Darstellung und Vorbereitungszeit
- [ ] Geht beim Lesen eines aufbewahrten Datenstands ein Wert verloren oder ändert sich, schlägt der Testlauf fehl und nennt Version und betroffenen Wert
- [ ] Bei jedem Release kommt der Datenstand der neuen Version zu den Testdaten hinzu; fehlt er, bricht die Release-Vorbereitung mit einer klaren Meldung ab
- [ ] Bestehende Migrationen älterer Formate (z. B. ehemals kombinierter Gong-Schalter, Praxis aus den alten Timer-Einstellungen) bleiben wirksam: ältere Daten werden weiterhin übernommen

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
- Die Audiodateien selbst gehören nicht zum Datenstand. Es genügt, dass die Verweise auf sie erhalten bleiben.
- Plattform-Asymmetrie: iOS kennt einen Rückfall für den ehemals kombinierten Gong-Schalter, Android nicht. Das Ticket ändert daran nichts, die Tests sollen es aber nicht verdecken.

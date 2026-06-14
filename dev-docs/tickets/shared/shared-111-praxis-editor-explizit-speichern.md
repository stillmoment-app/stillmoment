# Ticket shared-111: Praxis-Editor mit explizitem Speichern/Abbrechen

**Status**: [-] WONTFIX
**Prioritaet**: MITTEL
**Komplexitaet**: Verhaltensaenderung der Speicher-Semantik; revidiert die bewusste Auto-Save-Entscheidung aus android-073. Risiko liegt darin, dass das automatische Speichern an mehreren Stellen verdrahtet sein kann.
**Phase**: 4-Polish

---

## WONTFIX

Das Ticket setzte voraus, es gaebe einen Praxis-Editor, dem man nur die Speicher-Semantik
auf "explizit" aendert. Tatsaechlich existiert ein solcher Editor nicht: Auf iOS gibt es
keinen Praxis-Editor-Screen, auf Android nur einen nicht erreichbaren toten `PraxisEditorScreen`.
Die Praxis ist eine **Einzelkonfiguration**, die inline auf dem Timer-Screen bearbeitet und
sofort gespeichert wird (Auto-Save) — und das ist bewusst so gewollt.

`dev-docs/reference/ux-conventions.md` §2 wurde entsprechend praezisiert: Massgeblich fuer
"explizit Save vs. Auto-Save" ist die Flaeche/Absicht (dedizierter Editor fuer ein benanntes
Objekt wie eine Meditation vs. Einstellungen auf einem Nutzungs-Screen wie dem Timer), nicht
der Inhaltstyp. Der Timer faellt damit korrekt unter Auto-Save.

Der tote Code (Android-Screen, irrefuehrender `PraxisEditorViewModel`-Name) wird in
**shared-113** aufgeraeumt.

---

## Was

Der Praxis-/Timer-Editor speichert nicht mehr automatisch beim Zurueck-Navigieren, sondern verlangt ein explizites Speichern. Abbrechen verwirft die Aenderungen. Bei ungespeicherten Aenderungen erscheint beim Verlassen eine Rueckfrage.

## Warum

`dev-docs/reference/ux-conventions.md` §2 legt fest: ein benanntes Objekt aus mehreren Feldern (wie eine Praxis) wird ueber explizites Save/Cancel bestaetigt — gleiche Semantik wie der Meditation-Editor. Heute speichert v.a. Android automatisch beim Back (android-073), was zwei "Editoren" mit gegensaetzlichem Verhalten erzeugt. §3 ergaenzt den Schutz vor stillem Datenverlust.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Der Praxis-Editor hat einen expliziten Speichern-Button; nur dieser persistiert.
- [ ] Abbrechen verwirft die Aenderungen, ohne zu speichern.
- [ ] Verlassen ohne Aenderungen schliesst sofort und kommentarlos.
- [ ] Verlassen mit ungespeicherten Aenderungen zeigt eine Rueckfrage mit "Verwerfen" / "Weiter bearbeiten".
- [ ] Save/Cancel-Platzierung konsistent mit dem Meditation-Editor (Cancel links, Save rechts).
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell und im Verhalten konsistent zwischen iOS und Android.

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Praxis-Editor oeffnen, ein Feld aendern, zurueck-navigieren.
2. Erwartung: Rueckfrage; "Verwerfen" verwirft die Aenderung (Praxis unveraendert), "Weiter bearbeiten" kehrt zurueck.
3. Aenderung machen, explizit speichern → Aenderung ist persistiert.
4. Editor oeffnen, nichts aendern, verlassen → schliesst sofort ohne Rueckfrage.
5. Erwartung: identisches Verhalten auf iOS und Android.

---

## Referenz

- Soll: `dev-docs/reference/ux-conventions.md` §2, §3
- Vorgaenger-Entscheidung (wird revidiert): android-073 (PraxisEditor Auto-Save)
- iOS: Praxis-Editor unter `ios/StillMoment/Presentation/Views/`
- Android: Praxis-Editor unter `android/app/src/main/kotlin/com/stillmoment/presentation/ui/`

---

## Hinweise

- Bewusste Umkehr von android-073: Auto-Save beim Zurueck war dort gewollt. Begruendung fuer die Umkehr ist die einheitliche Editor-Semantik (ux-conventions.md §2) und der Discard-Schutz (§3).
- Verhaelt sich nach Umsetzung wie der Meditation-Editor (shared-110) — beide Editoren teilen dann dieselbe Save/Cancel/Discard-Logik.

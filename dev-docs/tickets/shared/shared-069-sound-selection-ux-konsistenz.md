# Ticket shared-069: Sound-Auswahl UX-Konsistenz (Overflow-Menü + Icon-Selektor)

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2d | Android ~1d (nach shared-065 Android)
**Phase**: 4-Polish

---

## Was

In den Auswahllisten für Einstimmungen und Hintergrundklänge erhält jede Custom-Audio-Row ein Overflow-Menü (3 Punkte, rechts) mit den Aktionen "Bearbeiten" und "Löschen". Alle Rows (eingebaut + custom) zeigen ein permanentes Icon links, das bei Auswahl farblich hervorgehoben wird. Außerdem wird Preview-Playback für Einstimmungen beim Antippen ergänzt (fehlt aktuell).

## Warum

Die bisherige Darstellung von Pencil- und Trash-Icons direkt in der Row ist visuell unruhig und inkonsistent mit dem Overflow-Menü-Pattern der Guided Meditations Library. Custom Sounds haben kein visuelles Gewicht (kein Icon, kein klarer Selektor). Das Fehlen von Preview-Playback bei Einstimmungen ist eine Inkonsistenz gegenüber Hintergrundklängen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | shared-065 Android |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Custom-Audio-Rows haben kein direktes Pencil/Trash-Icon mehr
- [ ] Custom-Audio-Rows zeigen rechts ein Overflow-Menü (3 Punkte / `ellipsis`) mit den Aktionen "Bearbeiten" und "Löschen"
- [ ] Eingebaute Sound-Rows und Stille/Keine-Row haben kein Overflow-Menü
- [ ] Alle Sound-Rows haben ein permanentes Icon links:
  - Eingebaute Sounds: ihr bestehendes `iconName`
  - Custom Sounds (Klanglandschaften + Einstimmungen): generisches `waveform`-Icon
  - Stille/Keine-Einstimmung-Row: passendes Icon (z.B. `speaker.slash` / `minus.circle`)
- [ ] Icon-Farbe wechselt bei Auswahl von `textSecondary` → `interactive`, Icon wechselt zur filled-Variante
- [ ] Tap auf eine Einstimmungs-Row spielt eine Hörprobe ab (analog zu Hintergrundklängen)
- [ ] Lokalisiert (DE + EN) — Menü-Aktionen bereits vorhanden, ggf. prüfen
- [ ] Accessibility-Labels auf dem Overflow-Menü (analog zu GuidedMeditationsListView)

### Tests

- [ ] Unit Tests iOS: ViewModel-seitig keine Änderungen erwartet — reine View-Änderung
- [ ] Unit Tests Android: analog

### Dokumentation

- [ ] CHANGELOG.md

---

## Manueller Test

1. Praxis-Editor öffnen → Hintergrundklang antippen
2. Einen eingebauten Sound antippen → Icon links wird farbig (filled), kein Menü rechts
3. Einen Custom Sound antippen → Icon wird farbig, Hörprobe startet
4. Drei-Punkte-Menü eines Custom Sounds tippen → "Bearbeiten" und "Löschen" erscheinen
5. Zurück → Praxis-Editor → Einstimmung antippen
6. Eine Custom-Einstimmung antippen → Hörprobe startet (neu!)
7. Drei-Punkte-Menü → "Bearbeiten" und "Löschen" erscheinen
8. Erwartung: Identisches Verhalten auf beiden Plattformen

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/BackgroundSoundSelectionView.swift`
- iOS: `ios/StillMoment/Presentation/Views/Timer/IntroductionSelectionView.swift`
- iOS Referenz-Pattern: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` → `overflowMenu(for:)`
- Android: analog nach shared-065 Android

---

## Hinweise

- Android-Subtask erst umsetzbar wenn shared-065 (Custom Audio Import) auf Android abgeschlossen ist
- iOS-Referenz `overflowMenu(for:)` in `GuidedMeditationsListView` zeigt das exakte Pattern (Menu mit Label-Buttons, ellipsis-Icon, accessibilityIdentifier)
- Preview-Playback für Einstimmungen: das ViewModel hat `playBackgroundPreview` — für Einstimmungen fehlt eine analoge Methode, diese muss ergänzt werden

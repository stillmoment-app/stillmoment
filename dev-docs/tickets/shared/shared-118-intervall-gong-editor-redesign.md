# Ticket shared-118: Intervall-Gong-Editor an Klang-Auswahl-Vorlage angleichen

**Status**: [x] DONE
**Plan**: [iOS](../plans/shared-118-ios.md) · [Android](../plans/shared-118-android.md)
**Prioritaet**: NIEDRIG
**Komplexitaet**: UI-Redesign eines bestehenden Editors; Risiko liegt in der Layout-Umstellung (Form → Karten/ScrollView) und der korrekten Wiederverwendung bestehender Komponenten ohne Verhaltensregression (Preview, Auto-Save, Vibration, Lautstärke).
**Phase**: 4-Polish

---

## Was

Der Intervall-Gong-Konfigurations-Screen wird visuell an die gehobene Klang-Auswahl-Vorlage angeglichen, die der Start-/Ende-Gong-Screen bereits umsetzt (shared-115): Karten-Layout mit Eyebrow-Sektions-Überschriften und einer Klang-Auswahl als Karten-Liste mit Vorhör-Button, charaktertragender Mini-Wellenform und Häkchen für die getönte Auswahl. Stepper (Intervall-Minuten), Modus-Auswahl und Lautstärke-Regler werden in das gleiche Karten-Layout überführt.

## Warum

Der Start-/Ende-Gong-Screen wurde mit shared-115 auf die neue Klang-Auswahl umgestellt; der Intervall-Gong-Screen blieb beim alten Dropdown/Listen-Stil zurück (iOS: Menü-Picker im Form-Layout; Android: Listenzeilen ohne Wellenform und ohne getönte Karten-Auswahl). Das ist eine sichtbare Inkonsistenz zwischen zwei eng verwandten Screens. Die Vereinheitlichung lässt die Klang-Auswahl überall gleich anfühlen und macht den Charakter jedes Gongs auch im Intervall-Editor erlebbar.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-115    |
| Android   | [x]    | shared-115    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Der Intervall-Gong-Screen verwendet das gleiche Karten-/ScrollView-Layout mit Eyebrow-Sektions-Überschriften wie der Start-/Ende-Gong-Screen.
- [ ] Die Klang-Auswahl ist eine Karten-Liste: jede Zeile zeigt einen Vorhör-Button, den Klang-Namen, eine charaktertragende Mini-Wellenform und (bei Auswahl) ein Häkchen mit getönter Zeile.
- [ ] Tippen auf eine Zeile wählt den Klang aus und spielt eine Vorschau ab; Tippen nur auf den Vorhör-Button spielt ausschließlich die Vorschau ab (gleiche Interaktion wie Start-/Ende-Gong).
- [ ] Toggle (Intervall-Gongs an/aus), Intervall-Minuten, Modus-Auswahl und Lautstärke-Regler bleiben funktional erhalten und fügen sich ins neue Karten-Layout ein.
- [ ] Die Vibrations-Option verhält sich wie auf dem Start-/Ende-Gong-Screen (kein Lautstärke-Regler, keine Wellenform, ggf. erklärender Hinweistext); auf Geräten ohne Vibration ist die Option weiterhin ausgeblendet.
- [ ] Lautstärke-Regler erscheint nur, wenn der gewählte Klang nicht „Vibration" ist.
- [ ] Auto-Save-Verhalten bleibt unverändert (Änderungen werden wie bisher sofort persistiert).
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell konsistent zwischen iOS und Android.

### Tests
- [ ] Unit Tests iOS (bestehende Tests grün; ggf. angepasste Selektoren/Logik)
- [ ] Unit Tests Android (bestehende Tests grün; ggf. angepasste Selektoren/Logik)

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare UI-Änderung)

---

## Manueller Test

1. Timer-Tab öffnen → Intervall-Gongs-Einstellung öffnen.
2. Intervall-Gongs aktivieren.
3. Erwartung: Klang-Auswahl erscheint als Karten-Liste mit Vorhör-Buttons, Mini-Wellenformen und Häkchen — optisch identisch zum Start-/Ende-Gong-Screen.
4. Einen anderen Klang antippen → Zeile wird getönt + Häkchen, Vorschau spielt.
5. Nur den Vorhör-Button einer nicht gewählten Zeile antippen → nur Vorschau, keine Auswahländerung.
6. „Vibration" wählen → Lautstärke-Regler verschwindet, Verhalten wie Start-/Ende-Gong.
7. Screen verlassen und erneut öffnen → gewählter Klang, Minuten, Modus und Lautstärke sind erhalten (Auto-Save).
8. Identisches Verhalten auf iOS und Android verifizieren.

---

## Referenz

- iOS Vorlage (Ziel-Optik): `ios/StillMoment/Presentation/Views/Timer/GongSelectionView.swift` + Komponenten unter `Presentation/Views/Timer/Components/` (`GongSoundRow`, `GongWaveform`, `GongPreviewButton`, `GongCardBackground`, `GongVolumeCard`, `GongSelectionLogic`)
- iOS umzubauen: `ios/StillMoment/Presentation/Views/Timer/IntervalGongsEditorView.swift`
- Android Vorlage (Ziel-Optik): `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/` GongSoundCard + `components/GongWaveform.kt`
- Android umzubauen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/IntervalGongsEditorScreen.kt`
- Handoff-Vorlage: `handoffs/gong-intervall/` (Design-Referenz der Klang-Auswahl)

---

## Hinweise

- Die benötigten Komponenten existieren bereits aus shared-115/116 und sollen wiederverwendet werden — kein Neuaufbau der Wellenform- oder Vorhör-Logik.
- Die Klang-Auswahl-Liste nutzt `GongSound.allIntervalSounds` (inkl. „Sanfter Intervallton" und Vibration), nicht `GongSound.allSounds` des Start-/Ende-Gongs.
- Anders als die Handoff-Vorlage für gefuehrte Meditationen (automatische Lautstärke aus der Sprach-Lautheit) behält der Intervall-Gong seinen manuellen Lautstärke-Regler — beim stillen Timer gibt es keine Stimme, aus der eine Lautstärke abgeleitet werden könnte.
- iOS: Wellenform-Charakter (`GongWaveform.waveEnvelopes`) und Android (`GongWaveformEnvelope`) sind cross-platform synchron — nicht divergieren lassen.
- Bestehende Accessibility-Identifier/Labels für die Intervall-Controls erhalten oder konsistent migrieren (UI-Tests/Selektoren prüfen).

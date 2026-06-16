# Ticket shared-116: Meditation-Editor — Klang-Auswahl als Karten-Picker + Section-Überschriften

**Status**: [x] DONE (iOS + Android)
**Prioritaet**: MITTEL
**Komplexitaet**: Gering auf iOS (Wiederverwendung der shared-115-Komponenten + Form-Section-Header). Auf Android abhaengig davon, dass der per-Meditation-Gong ueberhaupt existiert (shared-106 ist dort offen).
**Phase**: 4-Polish
**Plan (iOS)**: [Implementierungsplan](../plans/shared-116-ios.md)

---

## Was

Im „Meditation bearbeiten"-Screen wird die Gong-Klang-Auswahl vom schlichten Text-mit-Haekchen
auf das Karten-Picker-Muster des Timer-Screens „Start & Ende" (shared-115) umgestellt:
Vorhör-Button mit Ring-Animation, charakteristische Mini-Wellenform, Auswahl-Haekchen.
Zusaetzlich erhalten die Abschnitte des Editors echte Section-Ueberschriften im Serif-Stil
(„Informationen", „Wiedergabebereich", „Zusaetzlicher Gong").

## Warum

Die Gong-Klang-Auswahl sieht heute an zwei Stellen unterschiedlich aus (Timer vs. Meditation-
Editor). Das Handoff vereinheitlicht beide auf dasselbe, ruhigere Muster, sodass dieselbe
Auswahl ueberall gleich aussieht und sich gleich anfuehlt. Die Section-Ueberschriften geben dem
Editor eine klarere, ruhigere Gliederung.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-115 (vorhanden) |
| Android   | [x]    | Karten-Picker + Section-Header „Informationen"/„Zusätzlicher Gong" in Android-Parität Phase B; Section-Header „Wiedergabebereich" mit dem Trim-Editor in Phase C (2026-06-16) |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Im Meditation-Editor erscheint die Klang-Liste nur, wenn „Gong am Anfang" oder „Gong am Ende" aktiv ist.
- [ ] Jede Klang-Zeile zeigt einen Vorhör-Button, den Klangnamen und eine statische Mini-Wellenform, die den Charakter des Klangs abbildet.
- [ ] Die ausgewaehlte Zeile ist hervorgehoben und traegt ein Haekchen.
- [ ] Tippen auf eine Zeile waehlt den Klang aus *und* spielt eine kurze Vorschau (echte Gong-Audiodatei).
- [ ] Tippen nur auf den Vorhör-Button spielt die Vorschau, *ohne* die Auswahl zu aendern.
- [ ] Der Vorhör-Button zeigt waehrend der Vorschau eine kurze Ring-Animation (respektiert „Bewegung reduzieren").
- [ ] Die Klang-Auswahl sieht im Meditation-Editor und im Timer „Start & Ende" identisch aus (gleiche Komponenten/Tokens).
- [ ] Die Vibrations-Option erscheint im Meditation-Editor **nicht** (nur hoerbare Gongs).
- [ ] Im Meditation-Editor gibt es **keinen** Lautstaerke-Regler; die Gong-Lautstaerke folgt den Timer-Gong-Einstellungen.
- [ ] Die Editor-Abschnitte tragen Section-Ueberschriften im Serif-Stil (`.section` / Newsreader): „Informationen", „Wiedergabebereich", „Zusaetzlicher Gong".
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell konsistent zwischen iOS und Android.

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Eine Meditation in der Bibliothek oeffnen und „Bearbeiten" waehlen.
2. „Gong am Anfang" aktivieren — die Klang-Liste erscheint.
3. Eine Zeile antippen: Auswahl wechselt, Haekchen wandert, kurze Vorschau spielt, Ring-Animation laeuft.
4. Nur den Vorhör-Button einer *anderen* Zeile antippen: Vorschau spielt, die Auswahl bleibt unveraendert.
5. Beide Gong-Schalter ausschalten: Die Klang-Liste verschwindet.
6. Erwartung: Optik und Verhalten sind identisch zum Timer-Screen „Start & Ende" — auf iOS und Android gleich.

---

## UX-Konsistenz

Layout-Entscheidung iOS: Der Editor bleibt ein `Form`. Die wiederverwendbaren shared-115-
Komponenten werden in der Form-Section **ohne eigene Kartenflaeche** genutzt (die Form-Section
liefert bereits Hintergrund und Insets) — sonst entstuende eine Karte-in-Karte. Android setzt
dasselbe Ergebnis mit seinen etablierten Editor-/Listen-Mustern um.

---

## Referenz

- Handoff: `handoffs/design_handoff_gong_klang_auswahl/` (README, `gong-app.jsx`, `gong-sheet.jsx`, `gong.css`)
- Timer-Vorlage (shared-115): iOS `ios/StillMoment/Presentation/Views/Timer/` (`GongSelectionView`, `Components/GongSoundRow`, `GongPreviewButton`, `GongWaveform`)
- iOS Editor: `ios/StillMoment/Presentation/Views/GuidedMeditations/` (`GuidedMeditationEditSheet`, `MeditationGongSoundPicker`)
- Klang-Liste fuer den Editor: `GongSound.allMeditationGongSounds` (ohne Vibration)

---

## Hinweise

- Die Mini-Wellenform ist **statisch** (feste Huellkurve je Klang, bereits in shared-115 als Cross-Platform-Spec hinterlegt) — nicht aus dem echten Sample berechnet.
- Wichtig fuer Android: Der per-Meditation-Gong (shared-106) und der gesamte Meditation-Editor-
  Umbau (shared-105/107/108/109/112) sind dort noch nicht umgesetzt. Der Android-Subtask kann
  erst nach bzw. zusammen mit shared-106 erfolgen; ggf. groesserer Scope als auf iOS.
- Section-Ueberschriften: den vorhandenen Typography-Token `.section` (Newsreader) verwenden, keine neuen Tokens einfuehren.

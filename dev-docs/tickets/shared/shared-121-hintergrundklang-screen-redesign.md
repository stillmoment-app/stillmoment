# Ticket shared-121: Hintergrundklang-Screen an Klang-Auswahl-Vorlage angleichen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Cross-Platform-UI-Redesign. Risiko liegt im bewussten Verhaltens-Delta zum Gong (Loop statt Einmal-Wiedergabe): Vorhör-Button als Play/Stop-Toggle mit atmendem Glow als Wiedergabe-Indikator. Wiederverwendung der vorhandenen Gong-Komponenten gegen Soundscape-spezifische Varianten abwägen (Planung).
**Phase**: 4-Polish
**Plan**: [iOS](../plans/shared-121-ios.md) · [Android](../plans/shared-121-android.md)

---

## Was

Der Timer-Screen **„Hintergrundklang"** (Timer → Einstellungen → Hintergrundklang) wird auf das gehobene Karten-Picker-Muster umgestellt — wie zuvor „Start & Ende" (shared-115) und „Intervall-Gongs" (shared-118/120). Statt der schlichten Icon-Listenzeilen erscheint die Klang-Auswahl als Karte mit rundem Vorhör-Button und Auswahl-Häkchen.

> **Update 2026-06-17 (User-Entscheidung):** Die Mini-Wellenform wird auf diesem Screen **weggelassen** (bringt wenig Mehrwert, kostet Platz) — abweichend vom Handoff. Der Wiedergabe-Indikator ist allein der Play/Stop-Vorhör-Button mit atmendem Glow. Außerdem: eigene Dateien behalten **Umbenennen + Entfernen** über ein Kebab-Menü (⋮), gemäß aktualisiertem Handoff.

## Warum

Die Klang-Auswahl soll **überall in der App gleich aussehen**. Der Hintergrundklang-Screen ist der letzte verbliebene Klang-Picker im alten Listen-Stil. Konsistenz schafft Ruhe und Vertrautheit.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen. Nur Nacht-Theme (dunkel) gefragt. -->

### Layout (beide Plattformen)
- [ ] Oben ein **Intro-Text** (serif, sekundär): „Lege einen sanften Klang unter deine Sitzung — oder wähle *Stille* für vollkommene Ruhe."
- [ ] Eyebrow **KLANG** → eingebaute Klänge als **Karten-Picker** (eine Karte, Zeilen mit Divider).
- [ ] Eyebrow **MEINE KLÄNGE** → eigene importierte Dateien als Karten-Zeilen **oder** Leer-Zustand (gestrichelte Karte); darunter **Import-Button** „Eigene Datei importieren".
- [ ] Eyebrow **LAUTSTÄRKE** → Lautstärke-Karte (Slider). Entfällt bei „Stille"; stattdessen Hinweistext.

### Klang-Zeile / Karten-Picker (beide Plattformen)
- [ ] Jede Zeile: runder **Vorhör-Button** (links) + Name + (sekundäre) Beschreibung + Häkchen bei Auswahl. **Keine Mini-Wellenform** (bewusst weggelassen, s.o.).
- [ ] Name + Beschreibung einzeilig mit Ellipsis (lange Namen werden abgeschnitten).
- [ ] Ausgewählte Zeile: getönter Hintergrund, Name hervorgehoben.
- [ ] **Zeile antippen** wählt den Klang und startet (bei echtem Klang) sofort die Loop-Vorschau. „Stille" stoppt jede Wiedergabe.
- [ ] **Vorhör-Button antippen** toggelt Play/Stop der Loop-Vorschau, **ohne** die Auswahl zu ändern. Es spielt immer nur **ein** Klang gleichzeitig.

### Loop-spezifisches Verhalten (bewusste Abweichung zum Gong)
- [ ] Vorhör-Button ist ein **Play/Stop-Schalter** (Glyph wechselt zu Stop, solange abgespielt wird) — nicht der einmalige Gong-Ring.
- [ ] Während des Abspielens zeigt der Button einen **ruhigen, atmenden Glow** (dauerhaft, ~1.6s-Zyklus) als Wiedergabe-Indikator.
- [ ] Bei `reduce motion` / reduzierter Bewegung steht der Glow still.

### „Stille"-Zeile
- [ ] Statt Play ein **Mute-Glyph** (durchgestrichener Lautsprecher); der Button spielt nichts ab.
- [ ] Bei Auswahl von „Stille": keine Lautstärke-Karte, stattdessen Hinweis „Stille bedeutet vollkommene Ruhe — nur deine Atmung und der Raum um dich."

### Eigene Klänge
- [ ] Importierte Dateien erscheinen als Karten-Zeilen (Vorhören + Name/Dauer + Häkchen).
- [ ] Eigene Zeilen zeigen rechts ein **Kebab-Menü (⋮)** mit **Umbenennen** (Dialog) und **Entfernen** (destruktiv, Bestätigungsdialog „Datei entfernen?"). Das Menü ändert die Auswahl nicht.
- [ ] Import-Button öffnet den Dateiimport; danach erscheint die Datei unter „Meine Klänge".

### Allgemein
- [ ] Lokalisiert (DE + EN).
- [ ] Visuell konsistent zwischen iOS und Android und mit „Start & Ende" / „Intervall-Gongs".
- [ ] Semantische Farb-/Type-Tokens (keine hartkodierten Werte).
- [ ] Accessibility-Labels auf allen interaktiven Elementen.

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Änderung)

---

## Manueller Test

1. Timer → Einstellungen → Hintergrundklang öffnen.
2. Eine Klang-Zeile (z.B. Waldatmosphäre) antippen → Auswahl + Loop-Vorschau startet, Button zeigt Stop + atmenden Glow.
3. Vorhör-Button erneut antippen → Vorschau stoppt, Auswahl bleibt.
4. „Stille" wählen → jede Wiedergabe stoppt, Lautstärke-Karte verschwindet, Hinweistext erscheint.
5. Lautstärke-Slider ziehen (bei echtem Klang) → bei laufender Vorschau ändert sich der Pegel sofort.
6. Eigene Datei importieren → erscheint unter „Meine Klänge"; Kebab-Menü (⋮) bietet Umbenennen + Entfernen.
7. Erwartung: identisches Verhalten und identische Optik auf iOS und Android.

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_soundscape/` (README.md, Hintergrundklang.html, soundscape.css, soundscape-app.jsx)
- Referenz-Implementierungen (gleiche Optik): shared-115 (Gong-Auswahl), shared-118/120 (Intervall-Gongs)
- iOS: `ios/StillMoment/Presentation/Views/Timer/` (BackgroundSoundSelectionView, Components/Gong*)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/` (SelectBackgroundSoundScreen, components/Gong*)

---

## Hinweise

- **Nur Nacht-Theme** (dunkel) gefragt — der helle „Kerzenschein"-Pfad ist für diesen Screen nicht aktiviert (existiert aber im System; nicht brechen).
- **Loop vs. Einmal-Wiedergabe** ist der bewusste Unterschied zum Gong-Picker: Audio-Vorschau loopt bereits (`playBackgroundPreview`); der Vorhör-Button ist ein Play/Stop-Toggle mit atmendem Glow als Wiedergabe-Indikator.
- **Mini-Wellenform entfällt** (User-Entscheidung 2026-06-17, abweichend vom Handoff): kein `ScapeWaveform`, keine SWAVE-Hüllkurven, keine Equalizer-Animation, keine flache Linie für „Stille".
- Wiederverwendung der Gong-Komponenten vs. Soundscape-Varianten ist eine Architektur-Entscheidung der Planung.

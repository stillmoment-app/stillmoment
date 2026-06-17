# Ticket shared-121: Hintergrundklang-Screen an Klang-Auswahl-Vorlage angleichen

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Cross-Platform-UI-Redesign. Risiko liegt im bewussten Verhaltens-Delta zum Gong (Loop statt Einmal-Wiedergabe): Vorhör-Button als Play/Stop-Toggle, dauerhaft animierte Wellenform, atmender Glow. Wiederverwendung der vorhandenen Gong-Komponenten gegen Soundscape-spezifische Varianten abwägen (Planung).
**Phase**: 4-Polish
**Plan**: [iOS](../plans/shared-121-ios.md) · [Android](../plans/shared-121-android.md)

---

## Was

Der Timer-Screen **„Hintergrundklang"** (Timer → Einstellungen → Hintergrundklang) wird auf das gehobene Karten-Picker-Muster umgestellt — wie zuvor „Start & Ende" (shared-115) und „Intervall-Gongs" (shared-118/120). Statt der schlichten Icon-Listenzeilen erscheint die Klang-Auswahl als Karte mit rundem Vorhör-Button, charakteristischer Mini-Wellenform und Auswahl-Häkchen.

## Warum

Die Klang-Auswahl soll **überall in der App gleich aussehen**. Der Hintergrundklang-Screen ist der letzte verbliebene Klang-Picker im alten Listen-Stil. Konsistenz schafft Ruhe und Vertrautheit.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen. Nur Nacht-Theme (dunkel) gefragt. -->

### Layout (beide Plattformen)
- [ ] Oben ein **Intro-Text** (serif, sekundär): „Lege einen sanften Klang unter deine Sitzung — oder wähle *Stille* für vollkommene Ruhe."
- [ ] Eyebrow **KLANG** → eingebaute Klänge als **Karten-Picker** (eine Karte, Zeilen mit Divider).
- [ ] Eyebrow **MEINE KLÄNGE** → eigene importierte Dateien als Karten-Zeilen **oder** Leer-Zustand (gestrichelte Karte); darunter **Import-Button** „Eigene Datei importieren".
- [ ] Eyebrow **LAUTSTÄRKE** → Lautstärke-Karte (Slider). Entfällt bei „Stille"; stattdessen Hinweistext.

### Klang-Zeile / Karten-Picker (beide Plattformen)
- [ ] Jede Zeile: runder **Vorhör-Button** (links) + Name + **Mini-Wellenform** (rechts) + Häkchen bei Auswahl.
- [ ] Ausgewählte Zeile: getönter Hintergrund, Name hervorgehoben.
- [ ] **Zeile antippen** wählt den Klang und startet (bei echtem Klang) sofort die Loop-Vorschau. „Stille" stoppt jede Wiedergabe.
- [ ] **Vorhör-Button antippen** toggelt Play/Stop der Loop-Vorschau, **ohne** die Auswahl zu ändern. Es spielt immer nur **ein** Klang gleichzeitig.

### Loop-spezifisches Verhalten (bewusste Abweichung zum Gong)
- [ ] Vorhör-Button ist ein **Play/Stop-Schalter** (Glyph wechselt zu Stop, solange abgespielt wird) — nicht der einmalige Gong-Ring.
- [ ] Während des Abspielens zeigt der Button einen **ruhigen, atmenden Glow** (dauerhaft, ~1.6s-Zyklus).
- [ ] Während des Abspielens **animiert die Wellenform als Equalizer**.
- [ ] Bei `reduce motion` / reduzierter Bewegung stehen Glow und Equalizer still.

### „Stille"-Zeile
- [ ] Statt Play ein **Mute-Glyph** (durchgestrichener Lautsprecher); der Button spielt nichts ab.
- [ ] Statt Wellenform eine **ruhige, flache Linie**.
- [ ] Bei Auswahl von „Stille": keine Lautstärke-Karte, stattdessen Hinweis „Stille bedeutet vollkommene Ruhe — nur deine Atmung und der Raum um dich."

### Eigene Klänge
- [ ] Importierte Dateien erscheinen als Karten-Zeilen mit Vorhören + Wellenform + Häkchen.
- [ ] Nicht-ausgewählte eigene Zeilen zeigen rechts ein **Entfernen-Symbol** (Papierkorb). Antippen öffnet einen Bestätigungsdialog „Datei entfernen?" (vgl. Handoff). Umbenennen entfällt auf diesem Screen (Vorlage 1:1).
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
2. Eine Klang-Zeile (z.B. Waldatmosphäre) antippen → Auswahl + Loop-Vorschau startet, Wellenform animiert, Button zeigt Stop + atmenden Glow.
3. Vorhör-Button erneut antippen → Vorschau stoppt, Auswahl bleibt.
4. „Stille" wählen → jede Wiedergabe stoppt, Lautstärke-Karte verschwindet, Hinweistext erscheint, flache Linie statt Wellenform.
5. Lautstärke-Slider ziehen (bei echtem Klang) → bei laufender Vorschau ändert sich der Pegel sofort.
6. Eigene Datei importieren → erscheint unter „Meine Klänge" mit Vorhör + Wellenform; Entfernen-Aktion verfügbar.
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
- **Loop vs. Einmal-Wiedergabe** ist der einzige bewusste Unterschied zum Gong-Picker: Audio-Vorschau loopt bereits (`playBackgroundPreview`), aber die UI-Komponenten (Preview-Button-Ring, Wellenform) sind aktuell auf Einmal-Wiedergabe ausgelegt → Soundscape-Varianten nötig.
- **SWAVE-Hüllkurven** (13 Werte, Loop-Muster, nicht abklingend) aus dem Handoff übernehmen — abweichend von den 11-Balken-Gong-Hüllkurven.
- Wiederverwendung der Gong-Komponenten vs. Soundscape-Varianten ist eine Architektur-Entscheidung der Planung.

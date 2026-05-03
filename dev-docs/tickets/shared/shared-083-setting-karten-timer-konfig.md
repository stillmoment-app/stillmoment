# Ticket shared-083: Setting-Karten auf Timer-Konfig statt versteckter Pills

**Status**: [~] IN PROGRESS
**Plan**: [Implementierungsplan](../plans/shared-083.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel-hoch. Mehrere parallele Aenderungen: Layout-Umbau Idle-Screen, neue Detail-View fuer Vorbereitungszeit, Wegfall des Praxis-Editor-Index, Wechsel des Speicher-Patterns von Save-on-Dismiss zu Live-Schreiben. Risiko: Custom-Audio-Import-Flow ist heute am Editor-Index aufgehaengt und muss neu verkabelt werden.
**Phase**: 3-Feature

---

## Was

Die fuenf Sitzungs-Settings (Vorbereitung, Einstimmung, Hintergrund, Gong, Intervall) werden direkt auf dem Timer-Konfigurations-Screen als sichtbar tippbare Karten dargestellt. Jede Karte zeigt Label, Icon und aktuellen Wert; ein Tap oeffnet die zugehoerige Detail-Auswahl. Der bisherige Praxis-Editor-Index-Screen entfaellt.

Schritt 1 von drei geplanten Schritten in Richtung "H2-Final". Number-Picker und Sitzungs-Engine bleiben unveraendert; geaendert wird ausschliesslich, *wo* und *wie* die fuenf Sitzungs-Settings angezeigt und geoeffnet werden.

## Warum

Heute liegen unter dem Minuten-Picker drei kleine Pillen, die wie dekorative Tags aussehen, aber Buttons sind. Tester verstehen nicht, dass sie tippbar sind. Vorbereitung und Einstimmung sind nur ueber den Praxis-Editor-Index erreichbar — also doppelt versteckt. Sichtbare, klar tippbare Karten machen die aktuelle Sitzungs-Konfiguration auf einen Blick verstaendlich und reduzieren die Anzahl der Taps fuer eine Aenderung.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)

**Karten-Layout auf Timer-Konfig-Screen**
- [ ] Unter dem Minuten-Picker erscheinen fuenf Karten in der Reihenfolge: Vorbereitung · Einstimmung · Hintergrund · Gong · Intervall
- [ ] Reihe 1: drei Karten (Vorbereitung, Einstimmung, Hintergrund); Reihe 2: zwei Karten (Gong, Intervall)
- [ ] Jede Karte zeigt: Label (uppercase, Letter-Spacing), Icon, aktuellen Wert in einer Zeile (Ellipsis bei Ueberlauf)
- [ ] Karten wirken sichtbar tippbar (Border, Press-State beim Druecken)
- [ ] Unter den Karten erscheint der Hinweis "Tippen, um anzupassen"

**Off-State per Opazitaet**
- [ ] Vorbereitung-Karte ist gedimmt, wenn Vorbereitungszeit aus ist (Wert: "Aus")
- [ ] Einstimmung-Karte ist gedimmt, wenn keine Einstimmung gewaehlt ist (Wert: "Ohne")
- [ ] Intervall-Karte ist gedimmt, wenn Intervall-Gongs aus sind (Wert: "Aus")
- [ ] Hintergrund-Karte ist nie gedimmt — "Stille" ist eine bewusste Auswahl, kein Aus-Zustand
- [ ] Gong-Karte ist nie gedimmt (immer aktiv)

**Navigation**
- [ ] Tap auf Vorbereitung-Karte oeffnet die neue Detail-Auswahl fuer Vorbereitungszeit
- [ ] Tap auf Einstimmung-Karte oeffnet die bestehende Einstimmungs-Auswahl
- [ ] Tap auf Hintergrund-Karte oeffnet die bestehende Hintergrund-Auswahl
- [ ] Tap auf Gong-Karte oeffnet die bestehende Gong-Auswahl
- [ ] Tap auf Intervall-Karte oeffnet die bestehende Intervall-Editor-Auswahl

**Vorbereitungszeit-Detail-View (neu)**
- [ ] Eigene Push-Detail-Auswahl im selben Stil wie die anderen vier Detail-Views
- [ ] Erste Option: "Aus" (entspricht Toggle off)
- [ ] Weitere Optionen: 5 Sek., 10 Sek., 15 Sek., 20 Sek., 30 Sek., 45 Sek.
- [ ] Aktuell aktive Option ist visuell markiert
- [ ] Auswahl wirkt sofort (kein "Speichern"-Schritt)

**Live-Schreiben statt Save-on-Dismiss**
- [ ] Aenderungen in den Detail-Views werden sofort in der laufenden Session-Konfiguration wirksam
- [ ] Beim Zuruecknavigieren zeigt die Karte sofort den neuen Wert (keine Race-Condition)

**Wegfall des Editor-Index**
- [ ] Der bisherige Praxis-Editor-Index-Screen (Liste mit allen fuenf Settings) ist nicht mehr erreichbar
- [ ] Die alten tag-artigen Pillen unter dem Picker sind entfernt
- [ ] Custom-Audio-Import (z.B. Share Sheet, File-Open) navigiert weiterhin nach dem Import in die richtige Detail-Auswahl (Soundscape oder Einstimmung)

**Idle-Screen-Aufraeumen**
- [ ] Der Text "Wie viel Zeit schenkst du dir?" ist vom Idle-Screen entfernt
- [ ] Das HandsHeart-Bild ist vom Idle-Screen entfernt
- [ ] Auf iPhone SE (kompakte Hoehe) passt der gesamte Idle-Inhalt ohne Scrollen auf den Screen

**Theming**
- [ ] Neue semantische Farb-Tokens fuer Karten-Hintergrund und Karten-Border existieren
- [ ] Tokens sind in allen drei Themes (warm, sage, dusk) definiert
- [ ] Karten respektieren Light- und Dark-Mode korrekt

**Konsistenz**
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Karten verwenden dieselben Icons wie die heutigen Pills (Sanduhr, Sparkle, Wind, Glocke, Refresh)

### Tests

- [ ] Unit-Tests iOS fuer die Karten-Logik (Wert-Anzeige, Off-State pro Karte)
- [ ] Unit-Tests Android fuer die Karten-Logik (Wert-Anzeige, Off-State pro Karte)
- [ ] Unit-Tests fuer die neue Vorbereitungszeit-Detail-View (Auswahl-Persistenz, Aus-Option)
- [ ] Unit-Tests fuer Live-Schreiben (Aenderung in Detail-View ist sofort in der Session-Konfiguration sichtbar)

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)
- [ ] Glossar-Update falls "Praxis-Editor" entfaellt

---

## Manueller Test

1. Timer-Tab oeffnen — Idle-Screen
2. Erwartung: Unter dem Minuten-Picker fuenf Karten in zwei Reihen (3+2). Vorbereitung links oben, Intervall rechts unten.
3. Wert auf einer Karte pruefen: zeigt aktuelle Auswahl der jeweiligen Option (z.B. "Tempelglocke" auf Gong).
4. Eine Off-Setting-Karte pruefen (z.B. Einstimmung auf "Ohne" stellen): Karte ist sichtbar gedimmt.
5. Tap auf eine Karte: oeffnet die zugehoerige Detail-Auswahl.
6. In der Detail-View etwas aendern, Zurueck-Geste: Karte zeigt sofort den neuen Wert.
7. Vorbereitung-Karte tappen: zeigt eine Liste mit "Aus", "5 Sek.", "10 Sek.", "15 Sek.", "20 Sek.", "30 Sek.", "45 Sek.".
8. Custom-Audio-Import via Share Sheet: nach Import landet User direkt in der richtigen Detail-Auswahl (Soundscape oder Einstimmung), nicht im Editor-Index.
9. Auf iPhone SE: alles passt ohne Scrollen.
10. Theme-Wechsel (warm → sage → dusk) und Locale-Wechsel (DE ↔ EN): Karten sehen in allen Kombinationen korrekt aus.

Erwartung: Auf iOS und Android identisches Verhalten (visuell und funktional).

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Karten-Tap | Push im NavigationStack | Push im NavGraph |
| Detail-View-Layout | Form/Insetgrouped-Liste | LazyColumn mit Cards |
| Auswahl-Markierung | Native iOS-Settings-Stil | Material-Stil |

Beide Plattformen verwenden ihre nativen Listen-Patterns fuer die Detail-Views — visuell darf es sich anfuehlen wie die jeweilige Plattform, das Verhalten ist identisch.

---

## Referenz

- iOS Idle-Screen heute: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` (configurationPillsRow)
- Android Idle-Screen heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt` (ConfigurationPills)
- Bestehende Detail-Views (iOS): AttunementSelectionView, BackgroundSoundSelectionView, GongSelectionView, IntervalGongsEditorView
- Bestehende Detail-Screens (Android): SelectAttunementScreen, SelectBackgroundSoundScreen, SelectGongScreen, IntervalGongsEditorScreen
- Praxis-Editor-Index (entfaellt): `PraxisEditorView.swift` / `PraxisEditorScreen.kt`
- Design-Handoff: `handoffs/design_handoff_h2final_step1/`

---

## Hinweise

**Nicht im Scope (kommt in spaeteren Schritten):**
- Number-Picker → Atemkreis-Umstellung (Schritt 2)
- Atmosphaerische Politur (Sternenhimmel, Halos, 2-zeilige Werte) (Schritt 3)
- Neue Settings einfuehren
- Sitzungs-Engine anfassen — alle Phasen sind bereits implementiert
- Detail-Views fuer Einstimmung, Hintergrund, Gong, Intervall neu bauen — existieren bereits

**Speicher-Pattern-Wechsel:**
Heute speichert der Praxis-Editor-Flow auf "Zurueck-Navigieren" (Save-on-Dismiss). Mit dem Wegfall des Index-Screens wird auf Live-Schreiben umgestellt: Aenderungen in den Detail-Views landen sofort in der Session-Konfiguration. Damit verschwindet die Race-Condition zwischen Pop-Animation und State-Update.

**Custom-Audio-Import:**
Der bisherige Flow nutzt den Praxis-Editor-Index als Einstiegspunkt nach dem Import. Mit dessen Wegfall muss der File-Open-/Share-Sheet-Handler direkt in die richtige Detail-View navigieren (Soundscape oder Einstimmung — abhaengig vom Audio-Typ).

**Kleine Geraete:**
Durch Wegfall des HandsHeart-Bildes und des Texts "Wie viel Zeit schenkst du dir?" passt das neue Layout auch auf iPhone SE ohne Scrollen.

**Plattform-Reihenfolge:**
Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz.

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS komplett
3. Portiert auf Android mit Referenz
-->

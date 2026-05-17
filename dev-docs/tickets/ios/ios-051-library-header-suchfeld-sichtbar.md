# Ticket ios-051: Library-Header — Such-Trigger immer sichtbar, Titel raus

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-051.md)
**Prioritaet**: MITTEL
**Komplexitaet**: mittel — Toolbar-Umbau und Wechsel weg von `.searchable()` hin zu einer eigenen Header-Bar; die Such-Logik aus ios-041 bleibt unveraendert
**Abhaengigkeiten**: ios-041 (Library-Suche)
**Phase**: 4-Polish

---

## Was

Im Library-Tab verschwindet die Toolbar-Ueberschrift "Bibliothek". Stattdessen sitzt eine eigene, immer sichtbare Header-Bar oben mit zwei Pillen: links ein Such-Feld, rechts eine kombinierte Aktion-Pille mit "+" (Import) und "i" (Content-Guide). Die bestehende Such-Logik (History/Idle/Results/Empty, Engine, Highlight, Persistenz) aus ios-041 bleibt vollstaendig erhalten — nur der Trigger wandert aus der versteckbaren `.searchable()`-Leiste in die fest sichtbare Header-Bar.

## Warum

Die heutige Toolbar zeigt den Title "Bibliothek" — bei groesseren Dynamic-Type-Einstellungen oder in einigen Sprachen wird er abgeschnitten, und der Wert ist gering: der Tab-Bar-Eintrag sagt bereits, wo der User ist. Die `.searchable()`-Leiste klappt beim Scrollen weg und ist deshalb nicht zuverlaessig sofort erreichbar. Ein dauerhaft sichtbares Suchfeld macht die Suche als zweite Primaeraktion sofort entdeckbar und entlastet den Titel-Slot, ohne die bestehende Such-Logik anzufassen.

---

## Akzeptanzkriterien

### Header-Layout

- [ ] Im Library-Tab ist kein NavigationBar-Title "Bibliothek" mehr sichtbar
- [ ] Stattdessen sitzt direkt unter der StatusBar eine eigene Header-Bar mit zwei Elementen in einer Zeile:
  - links eine Such-Pille (fuellt den verfuegbaren Raum, "flex")
  - rechts eine kombinierte Aktion-Pille mit zwei Buttons: "+" und "i" (visuell verbunden, durch eine duenne vertikale Trennlinie geteilt)
- [ ] Die Header-Bar bleibt beim Scrollen der Bibliothek immer an der gleichen Position (kein Verstecken/Wiedererscheinen)
- [ ] Hoehe der Pillen: 40 pt; Beruehrungsflaeche pro Button mindestens 44 pt (durch Tap-Erweiterung, nicht durch Vergroesserung der sichtbaren Pille)
- [ ] Optik der Pillen folgt dem Handoff `handoffs/Library Header - Mit Suche.html` (Capsule-Form, `.regularMaterial`-aehnlicher Hintergrund, leichter Schatten in Light, Stroke-Border in Dark)
- [ ] Bei leerer Bibliothek (Empty-State) ist die Header-Bar nicht sichtbar — der bestehende Empty-State bleibt unveraendert (inklusive Import-Button im Empty-State)

### Such-Pille — Idle-Zustand

- [ ] Such-Pille zeigt links eine Lupe (16 pt), daneben den Platzhalter-Text "Suchen" / "Search" in Sekundaerfarbe (gekuerzt gegenueber dem ios-041-Prompt, weil der laengere Text in der 40-pt-Pille neben Lupe und Clear-X abgeschnitten wurde)
- [ ] Tap auf die Such-Pille setzt den Fokus ins Suchfeld, blendet die Tastatur ein und zeigt den History-State (wie bisher in ios-041)
- [ ] Tap-Flaeche bedeckt die gesamte Pille (Lupe + Platzhalter)

### Such-Pille — aktiver Zustand

- [ ] Sobald das Suchfeld fokussiert ist, erscheint rechts neben der Pille (ausserhalb der Aktion-Pille, an deren Stelle) ein "Abbrechen"-Button in Akzentfarbe — die Aktion-Pille wird im aktiven Zustand ausgeblendet
- [ ] Tap auf "Abbrechen" entfernt den Fokus, leert die Eingabe und kehrt in den Idle-Zustand (Aktion-Pille wieder sichtbar) zurueck
- [ ] Solange Text in der Pille steht, erscheint rechts in der Pille ein Clear-X — Tap leert die Eingabe ohne den Fokus zu verlieren
- [ ] Eingabe aktualisiert die Treffer wie bisher live (Live-Suche aus ios-041 unveraendert)
- [ ] Bei aktiver Such-Pille bleibt die Pille selbst breiter — sie expandiert in den frei gewordenen Raum der ausgeblendeten Aktion-Pille

### Aktion-Pille (+ / i)

- [ ] "+" oeffnet den DocumentPicker (wie heute)
- [ ] "i" oeffnet den Content-Guide-Sheet (wie heute)
- [ ] Die beiden Icons sitzen in derselben Capsule, getrennt durch eine duenne vertikale 1 pt-Trennlinie in subtiler Farbe (siehe Handoff)
- [ ] Im Idle-Zustand der Library ist die Aktion-Pille sichtbar; bei aktivem Such-Fokus blendet sie sich aus (siehe oben)

### Such-Verhalten (unveraendert aus ios-041)

- [ ] Tap-Tap-Tap durch idle ↔ history ↔ results ↔ empty fuehlt sich identisch an wie heute
- [ ] Suchhistorie wird bei Tap auf einen Treffer oder bei Submit (Return-Taste) gespeichert (wie ios-041)
- [ ] Suchen ohne Treffer landen NICHT in der Historie (wie ios-041)
- [ ] Match-Highlight, Treffer-Anzahl-Eyebrow, Empty-State der Suche bleiben unveraendert
- [ ] Beim Scrollen in der Trefferliste klappt die Tastatur ein
- [ ] Beim Verlassen des Library-Tabs wird die Eingabe zurueckgesetzt; die Historie bleibt
- [ ] Beim Oeffnen eines Treffers (Tap) wird die Eingabe ebenfalls zurueckgesetzt; nach Rueckkehr ist die Library im Idle

### Design / Theme

- [ ] Theme-Wechsel (Kupfer / Salbei / Daemmerung) trifft Such-Pille (Hintergrund, Lupe, Platzhalter), Aktion-Pille (Hintergrund, Icons, Trennlinie) und "Abbrechen"-Button (Akzentfarbe) korrekt
- [ ] Light- und Dark-Mode lesbar; im Dark-Mode greift die Border-Strategie statt Shadow (siehe Memory-Notiz zu Dark Mode Shadows)
- [ ] Typografie folgt Typografie 2.1: Platzhalter und Such-Eingabe nutzen `.body`-Token; "Abbrechen" nutzt `.body`

### Lokalisierung

- [ ] Such-Prompt aus ios-041 wird gekuerzt: `library.search.prompt` wird auf "Suchen" / "Search" reduziert (war "Nach Titel oder Sprecher suchen" / "Search by title or teacher" — passt nicht in die 40-pt-Pille neben Lupe und Clear-X, war abgeschnitten)
- [ ] "Abbrechen" / "Cancel" — falls noch nicht vorhanden, neuer String `common.cancel` (Wiederverwendung pruefen)
- [ ] Der entfallende Toolbar-Title "Bibliothek" bleibt im String-Catalog (`guided_meditations.title`) als TabBar-Label erhalten — nur die Verwendung in der Toolbar entfaellt

### Accessibility

- [ ] Such-Pille im Idle traegt das VoiceOver-Label "Bibliothek durchsuchen" (uebernommen aus ios-041)
- [ ] Aktion-Pille: "+"-Button behaelt Label "Meditation hinzufuegen", "i"-Button behaelt "Anleitung oeffnen" (Labels aus dem heutigen Toolbar-Code)
- [ ] "Abbrechen"-Button traegt das Label "Suche abbrechen"
- [ ] VoiceOver-Fokus-Reihenfolge im Header: Such-Pille zuerst, dann "+", dann "i" (bzw. "Abbrechen" im aktiven Zustand)
- [ ] Bei Dynamic Type AX1+ skalieren Pillen-Hoehe und Schriftgroesse mit; falls der Header in zwei Zeilen umbricht (sehr grosse Typo + langer Platzhalter), ist das akzeptabel — Pillen duerfen nicht clippen
- [ ] Tastatur-Fokus-Indikator (Hardware-Keyboard, externe Tastatur) ist sichtbar auf den Buttons der Aktion-Pille

### Tests

- [ ] ViewModel-Tests bleiben gruen — die `isSearching`-Logik wird jetzt direkt vom Header-Fokus gesetzt statt aus `@Environment(\.isSearching)` gelesen
- [ ] UI-Test (XCUITest) verifiziert: Header sichtbar nach Scroll, Tap auf Such-Pille zeigt History, "Abbrechen" kehrt in Idle zurueck, "+" oeffnet DocumentPicker, "i" oeffnet Guide-Sheet
- [ ] Snapshot/Visueller Check (manuell): Theme-Wechsel im Library-Tab — Pillen-Optik korrekt in allen drei Themes, Light + Dark

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Library mit mind. 3 Meditationen oeffnen → kein Titel "Bibliothek" mehr sichtbar; oben sitzt eine Header-Bar mit Such-Pille (links, breit) und kombinierter +/i-Pille (rechts)
2. Liste scrollen → Header-Bar bleibt sichtbar an gleicher Position
3. Tap auf die Such-Pille → Tastatur erscheint, "Abbrechen" loest die +/i-Pille rechts ab, "Zuletzt gesucht"-State erscheint (oder leerer History-Container, wenn noch keine Historie)
4. "tara" eintippen → Trefferliste flach mit Highlights; "Abbrechen" weiterhin rechts
5. Auf Treffer tippen → Player oeffnet sich; zurueck → Library wieder im Idle, Header-Bar zeigt wieder +/i-Pille rechts
6. "+" antippen → DocumentPicker oeffnet sich
7. "i" antippen → Content-Guide-Sheet oeffnet sich
8. Such-Pille antippen, leerer Eingabe → "Tara" aus Historie tippen → Treffer erscheinen sofort
9. "Abbrechen" antippen → Eingabe leer, Tastatur weg, +/i wieder sichtbar
10. Library leeren (alle Meditationen loeschen) → Empty-State wie heute, ohne Header-Bar
11. Eine Meditation importieren → Empty-State weg, Header-Bar wieder sichtbar
12. Theme wechseln (Kupfer/Salbei/Daemmerung) und in Light + Dark testen → Pillen-Optik bleibt konsistent
13. Dynamic Type auf AX2 stellen → Pillen skalieren, kein Clipping, ggf. zweizeiliger Header

---

## Referenz

- Design-Handoff: `handoffs/Library Header - Mit Suche.html`
- Library-View: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` (Toolbar + `.searchable()`)
- Such-Bridge: `ios/StillMoment/Presentation/Views/GuidedMeditations/LibrarySearchContentView.swift` (liest heute `@Environment(\.isSearching)` — muss umverdrahtet werden)
- ViewModel: `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift` (`searchQuery`, `isSearching`, `searchState`)
- Vorgaenger: `dev-docs/tickets/ios/ios-041-library-search.md`

---

## Hinweise

- **Kein `.searchable()` mehr.** Das System-Suchfeld klappt beim Scrollen weg und ist deshalb fuer dieses Ticket der falsche Container. Stattdessen ein eigenes `TextField` in einer Capsule, gesetzt in den Header. Den heute von SwiftUI gestellten "Abbrechen"-Button manuell nachbauen.
- **Header als `safeAreaInset(edge: .top)`** auf dem Library-Content. So bleibt der Header ueber dem ScrollView fixiert, ohne dass die Content-Hoehe falsch berechnet wird.
- **`@FocusState`** auf das `TextField` setzen — `isSearching` im ViewModel wird ueber `onChange(of: focused)` gesetzt, ersetzt damit die `@Environment(\.isSearching)`-Verdrahtung in `LibrarySearchContentView`.
- **Toolbar ausblenden:** `.toolbar(.hidden, for: .navigationBar)` auf den NavigationStack-Wurzel-Inhalt der Library. Vorsicht: das blendet auch die Navigation in den Player aus — die Player-Detail-View setzt ihre Toolbar selbst, das sollte sauber bleiben, aber manuell verifizieren.
- **Aktion-Pille als eigenes Subview** (`LibraryActionPill`), damit der Header-Code klein bleibt und die Pille zentral testbar ist.
- **Trennlinie zwischen + und i** in der Aktion-Pille via `.overlay(Divider().frame(width: 1, height: 16))` oder eine `Rectangle().fill(theme.divider.opacity(0.18))` zwischen den Buttons.
- **Dynamic Type-Verhalten** vorab in AX1, AX2 pruefen — wenn der Header zu hoch wird, lieber zweizeilig umbrechen statt clippen. iPad nicht im Scope (App ist Portrait-Only auf iPhone).
- **Vibration/Haptic** beim Tap auf Buttons: nicht hinzufuegen — die Such-Pille und Aktion-Buttons sind Standard-Buttons ohne Haptic-Bedarf. Konsistent mit dem heutigen Toolbar-Verhalten.
- **Android folgt in einem separaten Ticket** (Material 3 SearchBar mit dauerhafter Sichtbarkeit). Cross-Platform-Konsistenz wird dort nachgezogen.

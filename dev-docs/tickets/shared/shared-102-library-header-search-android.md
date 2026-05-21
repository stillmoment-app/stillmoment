# Ticket shared-102: Library-Header mit immer sichtbarem Suchfeld (Android-Sync)

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel — Toolbar-Umbau und Wechsel von eingebettetem Suchfeld (`shared-101`) hin zu einer eigenen Header-Bar mit zwei Pillen; die Such-Logik aus `shared-101` bleibt unveraendert.
**Phase**: 4-Polish

---

## Was

Im Library-Tab verschwindet die Top-App-Bar-Ueberschrift "Bibliothek". Stattdessen sitzt eine eigene, immer sichtbare Header-Bar oben mit zwei Pillen: links ein Such-Feld, rechts eine kombinierte Aktion-Pille mit "+" (Import) und "i" (Content-Guide). Die bestehende Such-Logik (History/Idle/Results/Empty, Engine, Highlight, Persistenz) aus `shared-101` bleibt vollstaendig erhalten — nur der Trigger wandert aus dem klassischen Toolbar-Slot in die fest sichtbare Header-Bar.

## Warum

Die heutige Top-App-Bar zeigt den Title "Bibliothek" — bei groesserer Font-Scale-Einstellung oder in einigen Sprachen wird er abgeschnitten, und der Wert ist gering: der Tab-Bar-Eintrag sagt bereits, wo der User ist. Ein dauerhaft sichtbares Suchfeld macht die Suche als zweite Primaeraktion sofort entdeckbar und entlastet den Titel-Slot.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `ios-051` |
| Android   | [x]    | -                               |

**Abhaengigkeit**: shared-101 (Library-Suche Android)

---

## Akzeptanzkriterien

### Header-Layout

- [ ] Im Library-Tab ist kein Top-App-Bar-Title "Bibliothek" mehr sichtbar
- [ ] Stattdessen sitzt direkt unter der StatusBar eine eigene Header-Bar mit zwei Elementen in einer Zeile:
  - links eine Such-Pille (fuellt den verfuegbaren Raum, "flex")
  - rechts eine kombinierte Aktion-Pille mit zwei Buttons: "+" und "i" (visuell verbunden, durch eine duenne vertikale Trennlinie geteilt)
- [ ] Die Header-Bar bleibt beim Scrollen der Bibliothek immer an der gleichen Position
- [ ] Hoehe der Pillen: 40 dp; Beruehrungsflaeche pro Button mindestens 48 dp (durch Ripple-Erweiterung, nicht durch Vergroesserung der sichtbaren Pille)
- [ ] Optik der Pillen: Capsule-Form, in Light Mode mit dezenten Schatten, in Dark Mode mit subtilem Border (entspricht der Card-Border-Strategie aus `shared-094`)
- [ ] Bei leerer Bibliothek (Empty-State) ist die Header-Bar nicht sichtbar — der bestehende Empty-State bleibt unveraendert (inklusive Import-Button im Empty-State)

### Such-Pille — Idle-Zustand

- [ ] Such-Pille zeigt links eine Lupe (16 dp), daneben den Platzhalter-Text "Suchen" / "Search" in Sekundaerfarbe (verkuerzt gegenueber dem `shared-101`-Prompt, weil der laengere Text in der 40-dp-Pille neben Lupe und Clear-X abgeschnitten wuerde)
- [ ] Tap auf die Such-Pille setzt den Fokus ins Suchfeld, blendet die Tastatur ein und zeigt den History-State (wie in `shared-101`)
- [ ] Tap-Flaeche bedeckt die gesamte Pille (Lupe + Platzhalter)

### Such-Pille — aktiver Zustand

- [ ] Sobald das Suchfeld fokussiert ist, erscheint rechts neben der Pille ein "Abbrechen"-Button in Akzentfarbe — die Aktion-Pille wird im aktiven Zustand ausgeblendet
- [ ] Tap auf "Abbrechen" entfernt den Fokus, leert die Eingabe und kehrt in den Idle-Zustand (Aktion-Pille wieder sichtbar) zurueck
- [ ] Solange Text in der Pille steht, erscheint rechts in der Pille ein Clear-X — Tap leert die Eingabe ohne den Fokus zu verlieren
- [ ] Eingabe aktualisiert die Treffer live (Such-Logik aus `shared-101` unveraendert)
- [ ] Bei aktiver Such-Pille bleibt die Pille selbst breiter — sie expandiert in den frei gewordenen Raum der ausgeblendeten Aktion-Pille

### Aktion-Pille (+ / i)

- [ ] "+" oeffnet den SAF-File-Picker (Storage Access Framework, wie heute)
- [ ] "i" oeffnet das Content-Guide-Sheet (wie heute)
- [ ] Die beiden Icons sitzen in derselben Capsule, getrennt durch eine duenne vertikale 1 dp-Trennlinie in subtiler Farbe
- [ ] Im Idle-Zustand der Library ist die Aktion-Pille sichtbar; bei aktivem Such-Fokus blendet sie sich aus

### Such-Verhalten (unveraendert aus shared-101)

- [ ] Tap-Tap-Tap durch idle ↔ history ↔ results ↔ empty fuehlt sich identisch an wie heute
- [ ] Suchhistorie wird bei Tap auf einen Treffer oder bei IME-Action gespeichert
- [ ] Suchen ohne Treffer landen NICHT in der Historie
- [ ] Match-Highlight, Treffer-Anzahl-Eyebrow, Empty-State der Suche bleiben unveraendert
- [ ] Beim Scrollen in der Trefferliste klappt die Tastatur ein
- [ ] Beim Verlassen des Library-Tabs wird die Eingabe zurueckgesetzt; die Historie bleibt
- [ ] Beim Oeffnen eines Treffers (Tap) wird die Eingabe ebenfalls zurueckgesetzt

### Design / Theme

- [ ] Theme (Kerzenschein 2.0 aus `shared-094`) trifft Such-Pille, Aktion-Pille und "Abbrechen"-Button korrekt
- [ ] Light- und Dark-Mode lesbar; im Dark-Mode greift die Border-Strategie statt Shadow
- [ ] Typografie folgt `shared-099`: Platzhalter und Such-Eingabe nutzen `.body`-Token; "Abbrechen" nutzt `.body`

### Lokalisierung

- [ ] Such-Prompt-Variante "Suchen" / "Search" (kuerzere Variante als in `shared-101`) — der Long-Variante-Key bleibt im String-Catalog, falls weiter benoetigt
- [ ] "Abbrechen" / "Cancel"
- [ ] Der entfallende Toolbar-Title "Bibliothek" bleibt im String-Catalog als TabBar-Label erhalten — nur die Verwendung in der Toolbar entfaellt

### Accessibility

- [ ] Such-Pille im Idle traegt das TalkBack-Label "Bibliothek durchsuchen" (uebernommen aus `shared-101`)
- [ ] "+"-Button behaelt Label "Meditation hinzufuegen", "i"-Button behaelt "Anleitung oeffnen"
- [ ] "Abbrechen"-Button traegt das Label "Suche abbrechen"
- [ ] TalkBack-Fokus-Reihenfolge im Header: Such-Pille zuerst, dann "+", dann "i" (bzw. "Abbrechen" im aktiven Zustand)
- [ ] Bei sehr grosser Font-Scale skalieren Pillen-Hoehe und Schriftgroesse mit; falls der Header in zwei Zeilen umbricht, ist das akzeptabel — Pillen duerfen nicht clippen
- [ ] Hardware-Keyboard-Fokus-Indikator ist sichtbar auf den Buttons der Aktion-Pille

### Tests

- [ ] ViewModel-Tests bleiben gruen — `isSearching`-Logik wird vom Header-Fokus gesetzt
- [ ] UI-Test (Compose) verifiziert: Header sichtbar nach Scroll, Tap auf Such-Pille zeigt History, "Abbrechen" kehrt in Idle zurueck, "+" oeffnet SAF-Picker, "i" oeffnet Guide-Sheet

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. Library mit mind. 3 Meditationen oeffnen → kein Titel "Bibliothek" mehr sichtbar; oben sitzt eine Header-Bar mit Such-Pille (links, breit) und kombinierter +/i-Pille (rechts)
2. Liste scrollen → Header-Bar bleibt sichtbar an gleicher Position
3. Tap auf die Such-Pille → Tastatur erscheint, "Abbrechen" loest die +/i-Pille rechts ab, "Zuletzt gesucht"-State erscheint
4. "tara" eintippen → Trefferliste flach mit Highlights; "Abbrechen" weiterhin rechts
5. Auf Treffer tippen → Player oeffnet sich; zurueck → Library wieder im Idle, Header-Bar zeigt wieder +/i-Pille rechts
6. "+" antippen → SAF-Picker oeffnet sich
7. "i" antippen → Content-Guide-Sheet oeffnet sich
8. Such-Pille antippen, leere Eingabe → "Tara" aus Historie tippen → Treffer erscheinen sofort
9. "Abbrechen" antippen → Eingabe leer, Tastatur weg, +/i wieder sichtbar
10. Library leeren (alle Meditationen loeschen) → Empty-State wie heute, ohne Header-Bar
11. Eine Meditation importieren → Empty-State weg, Header-Bar wieder sichtbar
12. System-Font-Scale auf "Largest" stellen → Pillen skalieren, kein Clipping, ggf. zweizeiliger Header

---

## Referenz

- iOS-Pendant: [ios-051](../ios/ios-051-library-header-suchfeld-sichtbar.md)
- iOS-Design-Handoff: `handoffs/Library Header - Mit Suche.html`
- Vorgaenger: [shared-101](shared-101-library-search-android.md) (Library-Suche)

---

## Hinweise

- **Kein integriertes Material 3 SearchBar mehr.** Die SearchBar klappt sich nicht in dem geforderten "immer sichtbaren" Modus dar — stattdessen eigener Header mit einem `TextField` in einer Capsule. Den Abbrechen-Button manuell rendern.
- **Header als `Scaffold(topBar = { ... })`** oder als fixierter Header oberhalb der `LazyColumn`. Wichtig: beim Scrollen der Inhaltsliste darf der Header nicht mitscrollen.
- **`FocusRequester`** auf das `TextField` setzen — `isSearching` im ViewModel wird ueber `onFocusChanged` gesetzt.
- **Toolbar ausblenden:** Wenn der Library-Tab eine eigene `topBar`-Implementierung bekommt, muss die globale Tab-Toolbar entweder weg oder transparent gestellt sein. Manuell verifizieren, dass die Player-Detail-View ihre eigene Toolbar nicht verliert.
- **Aktion-Pille als eigenes Composable** (`LibraryActionPill`), damit der Header-Code klein bleibt und die Pille zentral testbar ist.
- **Trennlinie zwischen + und i** via `Box(Modifier.width(1.dp).fillMaxHeight().background(theme.divider.copy(alpha = 0.18f)))`.
- **Font-Scale-Verhalten** vorab in "Large" und "Largest" pruefen — wenn der Header zu hoch wird, lieber zweizeilig umbrechen statt clippen.
- **Haptic** beim Tap auf Buttons: nicht hinzufuegen — die Such-Pille und Aktion-Buttons sind Standard-Buttons. Konsistent mit iOS.

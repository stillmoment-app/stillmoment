# Ticket shared-114: Top-Bar-Navigations-Boilerplate zentralisieren

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: NIEDRIG
**Komplexitaet**: Reines internes Refactoring ohne User-sichtbare Aenderung. Risiko liegt allein in unbeabsichtigten optischen Abweichungen (Titel-Farbe, Back-Icon, Insets) — abgesichert durch bestehende Tests/Screenshots. Breite (viele Screens), aber pro Stelle mechanisch.
**Phase**: 4-Polish

---

## Was

Wiederkehrende Top-Bar-/Navigations-Bausteine, die heute in vielen Screens kopiert
sind, in je eine gemeinsame Stelle pro Plattform zusammenfuehren — auf iOS den
Screen-Titel-Workaround, auf Android das Standard-Zurueck-Icon der bestehenden
Top-Bar-Komponente. Das sichtbare Verhalten bleibt exakt gleich.

## Warum

Dieselbe Top-Bar-Konstruktion ist auf iOS in 7 und auf Android in 5 Screens nahezu
identisch dupliziert. Jede kuenftige Aenderung an Titel-Darstellung oder Zurueck-Knopf
muss heute an jeder Stelle einzeln nachgezogen werden. Auf iOS kapselt die Duplizierung
zudem einen bekannten Fallstrick: `.navigationTitle()` ignoriert die Theme-Farbe
(UIKit-Bridge), weshalb ueberall manuell der `.principal`-Workaround steht — wird er
einmal vergessen, kehrt der Theme-Bug stillschweigend zurueck. Eine zentrale Stelle
macht die richtige Loesung zum Default und verhindert diese Regression.

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
- [ ] Der wiederkehrende Top-Bar-Baustein ist in genau eine wiederverwendbare Stelle pro Plattform gebuendelt; die betroffenen Screens nutzen diese statt eigener Kopien.
- [ ] iOS: Setzen eines Screen-Titels geht ueber einen gemeinsamen Weg, der die Theme-Farbe (`textPrimary`) und `inline`-Darstellung garantiert — kein direkter `.navigationTitle()`-Aufruf mehr in den betroffenen Screens.
- [ ] Android: Das Standard-Zurueck-Icon der gemeinsamen Top-Bar-Komponente wird zentral gerendert; die betroffenen Screens uebergeben nur noch die Zurueck-Aktion.
- [ ] Keine optische oder verhaltensseitige Aenderung: Titel, Farbe, Zurueck-Icon, Abstaende und Accessibility-Label bleiben identisch zu vorher.
- [ ] Visuell konsistent zwischen iOS und Android (unveraendert gegenueber heute).

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android
- [ ] Bestehende UI-Tests / Screenshot-Tests bleiben gruen (Beleg fuer Null-Regression)

### Dokumentation
- [ ] Kein CHANGELOG-Eintrag noetig (keine user-sichtbare Aenderung)

---

## Manueller Test

1. Mehrere betroffene Screens oeffnen (iOS: Einstellungen, Gong-Auswahl, Hintergrund-Auswahl; Android: Gong-Auswahl, Hintergrund-Auswahl, Intervall-Editor).
2. Titel-Text, Titel-Farbe (auch im Dark Mode und bei Theme), Zurueck-Icon und Zurueck-Funktion pruefen.
3. Erwartung: alles unveraendert gegenueber dem Stand vor dem Refactoring — auf beiden Plattformen.

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/` (Screens mit `.toolbar(.principal)`-Titel)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/` (`StillMomentTopAppBar` + nutzende Screens)
- Verwandt: Memory-Notiz „`.navigationTitle()` ist eine UIKit-Bridge" (Theme-Farb-Fallstrick)

---

## Hinweise

Befund aus der Code-Analyse nach shared-110 (Stand der Duplizierung):

**iOS — Screen-Titel-Workaround (7 Stellen, praktisch identisch):**
Jeweils `.navigationBarTitleDisplayMode(.inline)` + `ToolbarItem(placement: .principal)`
mit `Text(...).textStyle(.screenTitle, color: \.textPrimary)`. Vorkommen:
GongSelectionView, PreparationTimeSelectionView, BackgroundSoundSelectionView,
IntervalGongsEditorView, SettingsView, AppSettingsView, SoundAttributionsView.
Ein ViewModifier (z. B. `.screenTitleBar("key")`) kapselt den Workaround an einer Stelle.

**Android — Standard-Zurueck-Icon (5 Stellen, identisch):**
`StillMomentTopAppBar` existiert bereits, aber 5 Screens wiederholen dasselbe
`navigationIcon`-Lambda mit `Icons.AutoMirrored.Filled.ArrowBack` (+ `button_back`-
contentDescription, `onSurfaceVariant`-Tint). Vorkommen: SelectBackgroundSoundScreen,
SelectGongScreen, IntervalGongsEditorScreen, PreparationTimeSelectionScreen,
SoundAttributionsScreen. Ein optionaler Zurueck-Parameter an `StillMomentTopAppBar`,
der das Standard-Icon selbst rendert, entfernt die Kopien. (Alle 5 sind eigene
Navigations-Routen und bleiben von shared-113 unberuehrt.)

**Bewusst NICHT im Scope:**
- Editor-Top-Bar (X + Save) wird *nicht* gebuendelt: Der einzige zweite Kandidat
  (`PraxisEditorScreen`) ist toter Code und wird in shared-113 entfernt — es bliebe nur
  ein Nutzer (Meditation-Editor), eine Abstraktion waere verfrueht.
- iOS X-Schliessen-Button und Save/Done-Buttons: Platzierung und Sichtbarkeits-Bedingungen
  divergieren zu stark (Placement `.cancellationAction` vs `.navigationBarLeading`,
  conditional rendering) — eine gemeinsame Komponente spart dort nichts.
- Confirm-/Discard-`AlertDialog` (Android, ~3 Stellen): moderater Gewinn mit subtilen
  Varianten (destructive-Flag, optionaler Warntext) — bewusst ausgelassen, kann bei
  Bedarf separat aufgegriffen werden.

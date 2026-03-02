# shared-072-android Implementation Log

---

## IMPLEMENT
Status: DONE
Commits:
- cf90038 feat(android): #shared-072 add introductionEnabled field to MeditationSettings and update persistence/reducer
- c00e20b feat(android): #shared-072 replace Introduction Picker with Toggle + conditional Dropdown in SettingsSheet
- f8ca73d test(android): #shared-072 add tests for introductionEnabled toggle behavior

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Einstimmungs-Picker durch Toggle + bedingten Inhalts-Picker ersetzt. `introductionEnabled: Boolean` zu `MeditationSettings` hinzugefuegt mit DataStore-Persistenz. `TimerReducer` beruecksichtigt `introductionEnabled` beim Start-Gong-Handling. SettingsSheet zeigt `IntroductionSection` analog zu `PreparationTimeSection`. 4 ViewModel-Tests und erweiterte Reducer-Tests fuer den `introductionEnabled`-Pfad.

---

## CLOSE
Status: DONE
Commits:
- 32e09d8 docs: #shared-072 Close ticket (Android)
- f69d86c docs: #shared-072 add Android CHANGELOG entry


---

## REVIEW 1
Verdict: PASS

make check: OK
make test-unit: OK

DISCUSSION:
<!-- DISCUSSION_START -->
- android/app/src/main/res/values/strings.xml:58 und values-de/strings.xml:58 - `settings_introduction_none` ("None" / "Keine") ist orphaned. Der alte Picker hatte "None" als erste Option; das Toggle-Pattern braucht diesen Key nicht mehr. Kein Laufzeitproblem, aber Dead Code in beiden Resource-Dateien.
- android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt:618-619 - `IntroductionToggle` verwendet `TypographyRole.SettingsLabel` (17sp, TextPrimary) fuer den Toggle-Label, waehrend der analoge `PreparationTimeToggle` (Zeile 278-279) und `IntervalGongsToggleRow` (Zeile 790-791) beide `TypographyRole.SettingsDescription` (13sp, TextSecondary) verwenden. Geringer visueller Unterschied, aber Inkonsistenz zum Referenz-Pattern das das Ticket herstellen will.
<!-- DISCUSSION_END -->

Summary:
Alle Akzeptanzkriterien sind erfuellt. Toggle an/aus ist korrekt implementiert. Inhalts-Picker erscheint bedingt. Default auf erste verfuegbare Einstimmung beim ersten Aktivieren funktioniert. `introductionId` bleibt erhalten wenn Toggle ausgeschaltet wird (DataStore-Logik korrekt, Tests bestaetigen). Der Edge Case leerer Introductions-Liste ist sauber behandelt: die gesamte Section wird via `Introduction.hasAvailableIntroductions` versteckt. `TimerReducer` prueft korrekt `introductionEnabled && introductionId != null` vor dem Starten der Intro-Phase. `make check` und alle 855 Unit-Tests sind gruen. Zwei minor DISCUSSION-Punkte: ein verwaister String-Key und eine typografische Inkonsistenz zwischen Introduction- und PreparationTime-Toggle.

---

## FIX 1
Status: DONE
Commits:
- f496fb1 fix(android): #shared-072 use SettingsDescription typography in IntroductionToggle for consistency

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
IntroductionToggle Typography von SettingsLabel (17sp, TextPrimary) auf SettingsDescription (13sp, TextSecondary) geaendert, konsistent mit PreparationTimeToggle und IntervalGongsToggleRow. Adressiert DISCUSSION-Punkt 2 aus REVIEW 1.

---

## REVIEW 2
Verdict: PASS

make check: OK
make test-unit: OK

DISCUSSION:
<!-- DISCUSSION_START -->
- Drei Cleanup-Findings, alle behoben in FIX 3.
<!-- DISCUSSION_END -->

Summary:
Alle FIX 1 und FIX 2 Änderungen korrekt. Drei Cleanup-Findings: (1) `settings_introduction_none`-String-Keys noch vorhanden — orphaned, da kein Kotlin-Code referenziert; (2) `onSelectBuiltIn: (String?) -> Unit` akzeptiert null, aber null wird nach Entfernung der "None"-Option nie übergeben — Dead Code; (3) KDoc in `SelectIntroductionScreen` noch veraltet ("No Introduction option"). Alle drei in FIX 3 behoben.

---

## FIX 3
Status: DONE
Commits: TBD

Summary:
Orphaned String-Keys `settings_introduction_none` aus values/strings.xml und values-de/strings.xml entfernt. `onSelectBuiltIn`-Callback von `(String?)` auf `(String)` geändert, null-Guard in der Lambda und in `IntroductionSelectionCard` entfernt. KDoc in `SelectIntroductionScreen` aktualisiert (Toggle statt "No Introduction option").

---

## FIX 2
Status: DONE
Commits:
- c4ecdd5 feat(android): #shared-072 add introduction toggle to PraxisEditorScreen, remove "Ohne Einstimmung" from SelectIntroductionScreen

Challenges:
<!-- CHALLENGES_START -->
- strings.xml enthielt unveroffentlichte Aenderungen aus anderem Feature (cozy rain). Musste Staging sorgfaeltig nur auf die eigenen String-Aenderungen beschraenken, um keinen fremden Code mitzucommiten.
<!-- CHALLENGES_END -->

Summary:
Toggle-Pattern aus SettingsSheet auf PraxisEditorScreen portiert. Praxis.kt um introductionEnabled-Feld erweitert (inkl. create(), fromMeditationSettings(), toMeditationSettings(), builder). PraxisEditorViewModel um setIntroductionEnabled() erweitert mit Auto-Select der ersten verfuegbaren Einstimmung. AudioSection im PraxisEditorScreen zeigt jetzt IntroductionToggleRow + bedingte NavigationRow statt einer einzelnen NavigationRow. "Ohne Einstimmung"-Zeile aus SelectIntroductionScreen entfernt. TimerScreen introductionPillLabel prueft nun auch introductionEnabled. 6 neue Tests (2 Domain, 4 ViewModel), alle 861 Tests gruen.

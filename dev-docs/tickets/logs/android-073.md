# android-073: PraxisEditor Auto-Save beim Zuruecknavigieren

---

## IMPLEMENT
Status: DONE
Commits:
- 8b82ed8 feat(android): #android-073 auto-save PraxisEditor on back navigation

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Replaced Cancel/Done TextButtons in PraxisEditorScreen with a back arrow IconButton. Added BackHandler for system back gesture. Both back arrow and system back now call viewModel.save() before navigating back, matching the iOS auto-save pattern. NavGraph simplified from onCancel/onSave to single onNavigateBack callback.

---

## CLOSE
Status: DONE
Commits:
- 0085382 docs: #android-073 Close ticket

---

## REVIEW 1
Verdict: PASS

make check: OK
make test: OK

BLOCKER:

DISCUSSION:
<!-- DISCUSSION_START -->
- android/app/src/main/res/values/strings.xml:257-260 und values-de/strings.xml:257-260 - Vier String-Keys sind nach der Umstellung auf Auto-Save orphaned und werden nirgends mehr referenziert: `accessibility_praxis_editor_cancel`, `accessibility_praxis_editor_cancel_hint`, `accessibility_praxis_editor_done`, `accessibility_praxis_editor_done_hint`. Kein Laufzeitproblem, aber Dead Code in den Ressourcen.
<!-- DISCUSSION_END -->

Summary:
Alle Akzeptanzkriterien erfuellt. Der TopAppBar zeigt korrekt einen Zurueck-Pfeil. System-Back (BackHandler) und der Back-Button im TopAppBar rufen beide `viewModel.save()` vor der Navigation auf. Die Implementierung entspricht dem iOS-Muster. `make check` und alle Unit-Tests sind grueen. Die ViewModel-Tests decken das Save-Verhalten ab (save persists via repository). Die fehlende direkte Test-Abdeckung des BackHandler-Triggers ist eine Eigenschaft der View-Schicht und akzeptabel auf ViewModel-Ebene. Einziger Hinweis: vier Accessibility-Strings der alten Cancel/Done-Buttons sind noch in beiden strings.xml-Dateien vorhanden, werden aber nicht mehr verwendet.

---

## FIX 1
Status: DONE
Commits:
- c7480f7 chore(android): #android-073 remove orphaned cancel/done accessibility strings

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Entfernte vier verwaiste Accessibility-Strings (cancel, cancel_hint, done, done_hint) aus values/strings.xml und values-de/strings.xml, die nach der Umstellung auf Auto-Save nicht mehr referenziert wurden. make check bestaetigte saubere Kompilierung und Lint.

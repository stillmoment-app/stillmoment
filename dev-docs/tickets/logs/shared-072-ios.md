---

## IMPLEMENT
Status: DONE
Commits:
- 883b5da feat(ios): #shared-072 toggle pattern in IntroductionSelectionView

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Replaced the "No Introduction" picker row in IntroductionSelectionView with a Toggle + conditional list pattern, mirroring the preparation time section. Added `introductionEnabled` to ViewModel with auto-select logic when enabling with no prior selection. Updated PraxisEditorView label to show "Ohne Einstimmung" when toggle is off. Added 7 unit tests covering toggle state, auto-selection, selection preservation, and persistence.

---

## CLOSE
Status: DONE
Commits:
- 3fdc960 docs: #shared-072 Close ticket

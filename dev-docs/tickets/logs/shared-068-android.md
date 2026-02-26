---

## IMPLEMENT
Status: DONE
Commits:
- 07a5f88 feat(android): #shared-068 remove delete button from PraxisEditorScreen

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Removed the Delete Practice button, its confirmation dialog, and all related code from the Android PraxisEditorScreen. Removed the onDeleteConfirm callback propagation through NavGraph, cleaned up the AlertDialog import, and removed 5 localized string entries (EN + DE). This aligns Android with the simplified single-configuration Praxis model that has no delete capability.

---

## CLOSE
Status: DONE
Commits:
- f58cb9b docs: #shared-068 Close ticket

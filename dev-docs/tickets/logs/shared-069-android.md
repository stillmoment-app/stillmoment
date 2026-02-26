## IMPLEMENT
Status: DONE
Commits:
- 7583acd feat(android): #shared-069 add introduction preview and rename to PraxisEditorViewModel

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
PraxisEditorViewModel um `playIntroductionPreview(introductionId)` erweitert, `stopPreviews()` um `stopIntroductionPreview()` ergaenzt, und `renameCustomAudio(id, newName)` hinzugefuegt. Alle drei Methoden delegieren an bestehende Domain-Interfaces (`AudioServiceProtocol`, `CustomAudioRepository`).

---

## FIX 1
Status: DONE
Commits:
- 5558071 feat(android): #shared-069 permanent icons and rename support in SelectBackgroundSoundScreen

Challenges:
<!-- CHALLENGES_START -->
- Icons.Filled.VolumeOff is deprecated -- must use Icons.AutoMirrored.Filled.VolumeOff instead
- Adding onRename to CustomAudioRow (internal) required cascading changes through SelectIntroductionScreen too, plus the same dialog extraction pattern there to satisfy detekt LongMethod
- Linter (likely another agent process) was concurrently modifying the same files during editing, requiring repeated re-reads of file state
<!-- CHALLENGES_END -->

Summary:
Updated SelectBackgroundSoundScreen and SelectIntroductionScreen with permanent icons (color change on selection instead of check/spacer switching), overflow menu with Edit+Delete actions, and a rename dialog wired through the composable hierarchy.

---

## CLOSE
Status: DONE
Commits:
- e4094bb docs: #shared-069 Close ticket

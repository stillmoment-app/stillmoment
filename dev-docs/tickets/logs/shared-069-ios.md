## IMPLEMENT
Status: DONE
Commits:
- 2f2156e feat(ios): #shared-069 BackgroundSoundSelectionView – overflow menu + icons
- 981e268 feat(ios): #shared-069 AudioService – add introduction preview
- 4ccfb5a feat(ios): #shared-069 PraxisEditorViewModel – add introduction preview

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
PraxisEditorViewModel um `playIntroductionPreview(introductionId:)` erweitert und `stopAllPreviews()` um `stopIntroductionPreview()` ergaenzt.

---

## FIX 1
Status: DONE
Commits:
- 218366d feat(ios): #shared-069 IntroductionSelectionView – overflow menu + icons + preview

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
IntroductionSelectionView auf das gleiche Pattern wie BackgroundSoundSelectionView aktualisiert: Overflow-Menue fuer Custom-Audio, permanente Icons links (minus.circle fuer "Keine", waveform fuer Einstimmungen), Preview-Playback bei Tap, und stopAllPreviews() bei onDisappear.

---

## CLOSE
Status: DONE
Commits:
- 58576c8 docs: #shared-069 Close ticket (iOS)

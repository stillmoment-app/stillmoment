---
name: ios-visual-verification
description: Wie iOS-Layout-Aenderungen ohne Unit-Test visuell verifiziert werden — Screenshots-Scheme als Fixture-Quelle, Simulator-Koordinaten in Punkten
metadata:
  type: feedback
---

Layout-Bugs auf iOS (Fades, Insets, Abstaende) haben keinen sinnvollen Unit-Test —
sie werden am laufenden Simulator verifiziert, mit Screenshot vorher/nachher.

**Why:** Ein Test auf `fadeZoneHeight == 140` prueft die Konstante gegen sich
selbst. Die Wurzel-`CLAUDE.md` verbietet solches Test-Theater ("No fallbacks.
No mocks. No theater."). Der Screenshot ist hier die einzige echte Evidenz.

**How to apply:**

- **Fixture-Bibliothek statt leerem Simulator.** Das Scheme
  `StillMoment-Screenshots` (Compile-Flag `SCREENSHOTS_BUILD`) seedet beim
  Start 5 Meditationen von 3 Lehrer:innen via `TestFixtureSeeder`. Damit laesst
  sich die Library-UI ohne Fastlane und ohne MP3-Import pruefen:
  `xcodebuild -scheme StillMoment-Screenshots -destination 'id=<UDID>' build`
  → `simctl install` → `simctl launch com.stillmoment.StillMoment.screenshots`.
  Bundle-ID unterscheidet sich von der normalen App.
- **5 Fixtures fuellen den Bildschirm nicht.** Um einen Scroll-Zustand zu
  erzwingen: `xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large`.
  Danach auf `large` zuruecksetzen, sonst bleibt der Simulator verstellt.
- **Koordinaten fuer `tap.sh`/`swipe.sh` sind logische Punkte, nicht Screenshot-Pixel.**
  iPhone 16 Plus = 430x932 pt, der Screenshot ist aber ~830x1800 px (shot.sh
  resized). Ein Swipe auf `y=1300` ist ausserhalb des Screens und passiert
  wirkungslos — es sieht dann so aus, als wuerde die Liste nicht scrollen.
- **Vorher-Bild via `git stash push -- <pfade>`.** Nur die geaenderten Dateien
  stashen, neu bauen, Screenshot, `stash pop`. Wichtig, wenn fremde
  uncommittete Arbeit im Working Tree liegt — siehe [[feedback-foreign-uncommitted-work]].

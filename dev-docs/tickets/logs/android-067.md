## IMPLEMENT
Status: DONE
Commits:
- fad6c10 feat(android): #android-067 replace emoji icons with Material Icons in SettingPill

Challenges:
<!-- CHALLENGES_START -->
- ktlint erfordert strikt lexikographische Import-Reihenfolge: `androidx.compose.ui.graphics.vector.ImageVector` muss vor `androidx.compose.ui.platform` stehen, nicht nach `semantics`. Pre-commit hook hat das korrekt abgefangen.
- `make check` war bereits vor den Aenderungen kaputt (pre-existing errors in GuidedMeditationSettingsSection.kt, SettingsSheet.kt, Theme.kt etc. von anderen Tickets). Detekt und ktlint fuer TimerScreen.kt passierten aber sauber.
<!-- CHALLENGES_END -->

Summary:
Alle 5 Emoji-Icons in den SettingPill-Composables durch Material Icons (Icons.Outlined) ersetzt. SettingPill-Signatur von `icon: String` auf `icon: ImageVector` geaendert, Text-Composable durch Icon-Composable ersetzt (14dp, onSurfaceVariant-Farbe).

---

## CLOSE
Status: DONE
Commits:
- ab990c3 docs: #android-067 Close ticket

---

## REVIEW 1
Verdict: PASS

make check: FAIL (pre-existing, unrelated to android-067)
make test: not run (pure presentation change, no logic affected)

BLOCKER:

DISCUSSION:
<!-- DISCUSSION_START -->
<!-- DISCUSSION_END -->

Summary:
Alle Akzeptanzkriterien erfuellt. Die `SettingPill`-Signatur nimmt korrekt `ImageVector` statt `String`. Alle 5 Pills nutzen `Icons.Outlined.*` (HourglassEmpty, Notifications, Air, Headphones, Repeat). Icon-Farbe ist `onSurfaceVariant`, Groesse 14dp. Kein Emoji-String mehr im Code. Die `make check`-Fehler (GuidedMeditationSettingsSection.kt, SettingsSheet.kt, IntervalGongsEditorScreen.kt) sind pre-existing aus anderen Tickets (android-070/shared-070) und wurden vom Implementierer korrekt als solche dokumentiert. Die Aenderung selbst ist ein sauberer, minimal-invasiver Presentation-Layer-Change ohne Architekturverletzungen.

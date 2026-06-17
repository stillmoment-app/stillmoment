# Ticket Implementer - Key Learnings

## Ticket-Referenzen

- **Ticket-Dateinamen nie raten.** Ticket-ID und Dateiname stimmen nicht immer ueberein (z.B. `shared-013-timer-focus-mode.md` statt erwartetem `shared-013-timer-state-machine.md`). Immer per `Glob("dev-docs/tickets/**/*shared-013*")` suchen statt Dateinamen zu konstruieren.

## Android/Kotlin Tests

- [Mockito thenThrow scheitert bei suspend-Mocks](feedback_mockito_suspend_thenthrow.md) — bei `suspend`-Funktionen mit Checked Exception `thenAnswer { throw ... }` statt `thenThrow(...)`.

## Feature-Entfernungen (Refactoring)

- **CLAUDE.md Code-Beispiele pruefen.** Bei Feature-Entfernungen (z.B. Pause-Funktionalitaet) auch `ios/CLAUDE.md` und `android/CLAUDE.md` auf veraltete Code-Beispiele pruefen. Diese Dateien enthalten oft Architektur-Snippets die das entfernte Feature referenzieren.

## Grosse mechanische Migrationen (>200 Aufrufstellen)

- **Bridge-Layer ist sicherer als Big-Bang-Delete.** Bei Migrationen wie shared-099 (209 TypographyRole-Aufrufstellen) erst die Implementierung der alten API auf die neue umstellen — alle Aufrufstellen bleiben gruen. Erst danach mit Python-Script auf neue API migrieren und am Ende den Bridge-Layer loeschen. So bleibt das System jeden Commit lang funktionsfaehig.
- **Python-Sed-Script statt manueller Edits.** Mechanische Pattern-Replacements (TypographyRole.X.textStyle() -> TextStyle.Y.toComposeTextStyle()) lassen sich in einem Python-Script mit Mapping-Dict + Regex-Substitution erledigen — 24 Dateien in einem Commit, alle Tests gruen. Danach `ktlintMainSourceSetFormat` fuer Import-Sortierung.
- **Ktlint single-line parameter format.** Compose-Composables mit 3+ Parametern in mehreren Zeilen brauchen Trailing-Komma — bei `(arg1, arg2, arg3)` einzeilig stehen lassen sonst ktlint-Fehler "Single whitespace expected before parameter".

## Compose-Detailwissen

- **MatchingDeclarationName triggered nach Loeschungen.** Wenn die erste Top-Level-Declaration einer Datei umgestellt wird (z.B. LocalIsDarkTheme entfernt, danach ist `data class StillMomentColors` zuoberst), kann detekt `MatchingDeclarationName` triggern. Loesung: `@file:Suppress("MatchingDeclarationName")` am Datei-Anfang.
- **Compose Material `Typography` ist nicht @Composable.** Du kannst Material's `Typography(...)` nicht im Composable-Kontext bauen, daher kann Bold-Text-Setting (`LocalConfiguration.fontWeightAdjustment`) dort nicht abgefragt werden. Bridge: an Material-Slots statische Tokens binden, an direkten `Text(..., style = TextStyle.body.toComposeTextStyle())`-Aufrufstellen reagiert Bold-Text live.
- **`fontWeightAdjustment` erst ab API 31.** Auf API 26-30 ist `Configuration.fontWeightAdjustment` immer `0` (oder die Property existiert nicht). Schwere Schrift wird daher dort nicht honoriert — wir dokumentieren das und bauen kein Backport.
- **Compose `TextStyle` und unser Token-Enum kollidieren.** Namens-Kollision zwischen `androidx.compose.ui.text.TextStyle` und unserem `enum class TextStyle`. Loesung: `import com.stillmoment.presentation.ui.theme.TextStyle as TextToken` in Dateien, die beide brauchen (Modifier-Impl, Material-Bindings, Debug-Screen).

## Cross-Platform-Migration (iOS Pendant existiert)

- **iOS-Referenz-Code lesen bevor angefangen wird.** Bei shared-Tickets mit iOS-Pendant (z.B. shared-099 / ios-048): die iOS-Implementierung ist die fachliche Quelle der Wahrheit. Erst `ios/StillMoment/Presentation/Views/Shared/TextStyle.swift` etc. lesen, dann Android nachziehen. Saemtliche Annahmen (Tokens-Anzahl, Bold-Mapping, Sample-Texte fuer Debug) werden 1:1 uebernommen — keine Erfindungen.
- **TTF-Dateien wiederverwenden.** Newsreader/Geist-Fonts unter `ios/StillMoment/Resources/Fonts/` lassen sich direkt nach `android/app/src/main/res/font/` kopieren (Naming: snake_case). Spart Asset-Bundle-Pflege auf beiden Plattformen.
- **Fixe Cross-Platform-Werte separat dokumentieren.** Bedeutungstragende, plattformidentische Daten (z.B. die Gong-WAVE-Envelopes aus shared-115) in eine eigene Spec-Datei legen, damit Android exakt spiegeln kann. Siehe [shared-115 Gong-WAVE-Spec](project_shared115_gong_wave_spec.md) — iOS ist Referenz, Werte stammen 1:1 aus dem Design-Handoff.

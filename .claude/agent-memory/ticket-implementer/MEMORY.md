# Ticket Implementer - Key Learnings

## Ticket-Referenzen

- **Ticket-Dateinamen nie raten.** Ticket-ID und Dateiname stimmen nicht immer ueberein (z.B. `shared-013-timer-focus-mode.md` statt erwartetem `shared-013-timer-state-machine.md`). Immer per `Glob("dev-docs/tickets/**/shared-013-*.md")` suchen (deckt aktiv + `archive/` ab, Treffer unter `plans/` ignorieren) statt Dateinamen zu konstruieren.

## Android/Kotlin Tests

- [Mockito thenThrow scheitert bei suspend-Mocks](feedback_mockito_suspend_thenthrow.md) — bei `suspend`-Funktionen mit Checked Exception `thenAnswer { throw ... }` statt `thenThrow(...)`.
- [Android im Worktree: local.properties fehlt](feedback_worktree_android_local_properties.md) — aus Main-Checkout kopieren; Basis gegen Feature-Branch pruefen; kleine Screens per `wm size/density`.
- [Emulator mit Parallel-Agenten geteilt](feedback_shared_emulator_parallel_agents.md) — dev-App kann unter dir neu installiert werden; lastUpdateTime prüfen, nicht gegeninstallieren; Scratchpad auch geteilt (Präfix); `am instrument` statt connected*.
- [Screengrab-Einzeltest: Sprachmix](project_android_screengrab_single_test_locale.md) — Einzelner Screenshot-Test liefert DE-UI mit EN-Quellen; Store-Bilder nur über vollen Lauf.
- [Doppelte Scaffold-Insets auf Android-Tabs](project_android_double_scaffold_insets.md) — innere Scaffold zieht Status-/Systemleiste nochmal ab (~65-70 dp); Timer gefixt, Library nicht.
- [runTest: backgroundScope braucht runCurrent](feedback_runtest_backgroundscope_runcurrent.md) — `advanceUntilIdle()` fuehrt backgroundScope-Arbeit nicht aus.
- [Worktree-Guard: Bash-Formen](feedback_worktree_guard_bash_shapes.md) — mehrere Heredocs / `git -C ..` werden abgelehnt; Write-Tool + absolute Pfade.
- [adb pm enable im Worktree blockiert](feedback_worktree_guard_adb_pm_enable.md) — Apps am Emulator nicht per `pm disable-user` abschalten; Wieder-Einschalten verweigert der Guard.
- [Worktree-Guard: git nicht in Ketten](feedback_worktree_guard_compound_git.md) — `git` allein aufrufen; lange Code-Einfügungen per Edit statt Python-Heredoc.

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

## Layout-Bugs ohne Unit-Test

- [iOS-Layout visuell verifizieren](feedback_ios_visual_verification.md) — Screenshots-Scheme seedet Fixtures, Simulator-Koordinaten sind Punkte (nicht Screenshot-Pixel), Vorher-Bild via gezieltem `git stash push -- <pfade>`.
- [Eigener Simulator bei Parallel-Agenten](feedback_dedicated_simulator_parallel_agents.md) — `simctl create` Wegwerf-Sim statt gebooteten fremden; danach löschen.
- [Simulator-Verifikation einrichten](feedback_simulator_verification_setup.md) — App mit `-AppleLanguages "(de)"` starten (DE-only-Features); Hell/Dunkel kommt aus den App-Einstellungen; Lade-/Fehlerbild per gepatchtem Bundle; Share-Import per ShareInbox + `openurl`.
- [tap_by_id trifft Offscreen-Elemente nicht](feedback_tap_by_id_offscreen.md) — meldet Erfolg auch bei y > Bildschirm; erst scrollen, dann tippen.
- [Fester Kopf über ScrollView](feedback_fixed_header_scrollview.md) — `VStack { kopf; ScrollView }` statt `.safeAreaInset`; nur `List` clippt am Kopf.

## iOS Build, Lint, Tests

- [BUILD_FAILED ohne error: = Runner-Bootstrap-Crash](feedback_ios_test_runner_bootstrap_crash.md) — Simulator-Flake bei parallelen Sims; einmal neu laufen lassen.
- [BUILD_FAILED diagnostizieren](feedback_build_failed_diagnose.md) — Ausgabe von `make test-*-agent` beim ersten Lauf in eine Datei umleiten und dort nach `error:` greppen, nicht wiederholen. Android: `FAIL` mit alten Zahlen = Compile-Fehler.
- [SwiftLint trailing_closure bei Closure als letztem Parameter](feedback_trailing_closure_last_param.md) — benannte Konstante oder Methodenreferenz statt Closure-Literal.
- [View in Type+Topic.swift aufteilen](feedback_view_extension_file_split.md) — verschachtelter `ViewModifier` mit Bindings, statt `private` zu lockern.
- [Echte Server-Antworten als Fixtures](feedback_real_world_fixtures_hooks.md) — Fixture-Ordner von Whitespace-Hooks ausnehmen; `// pragma: allowlist secret` in derselben Zeile.
- [Worktree-Build + UI-Test-Simulatorzustand](feedback_ios_worktree_and_ui_test_state.md) — Local.xcconfig in Worktree kopieren; LibraryFlowUITests-Empty-State-Fehler = alte Bibliothek auf Test-Simulator.
- [Share-Extension auf iOS 26](project_share_extension_ios26_presentation.md) — Vollbild-Key ignoriert, Sheet opak; App-Dateien per Exception-Set ins Extension-Target; Simulator-Testwege.
- [Fastlane-Screenshot im Worktree](feedback_worktree_fastlane_screenshot.md) — Gemfile.lock, .bundle/config, vendor-Symlink aus Main; Symlink danach löschen.
- [Test-Fixtures liegen flach im Bundle](project_test_fixtures_bundle_flat.md) — `url(forResource:withExtension:)` ohne `subdirectory:`.

## Cross-Platform-Migration (iOS Pendant existiert)

- **iOS-Referenz-Code lesen bevor angefangen wird.** Bei shared-Tickets mit iOS-Pendant (z.B. shared-099 / ios-048): die iOS-Implementierung ist die fachliche Quelle der Wahrheit. Erst `ios/StillMoment/Presentation/Views/Shared/TextStyle.swift` etc. lesen, dann Android nachziehen. Saemtliche Annahmen (Tokens-Anzahl, Bold-Mapping, Sample-Texte fuer Debug) werden 1:1 uebernommen — keine Erfindungen.
- **TTF-Dateien wiederverwenden.** Newsreader/Geist-Fonts unter `ios/StillMoment/Resources/Fonts/` lassen sich direkt nach `android/app/src/main/res/font/` kopieren (Naming: snake_case). Spart Asset-Bundle-Pflege auf beiden Plattformen.
- **Fixe Cross-Platform-Werte separat dokumentieren.** Bedeutungstragende, plattformidentische Daten (z.B. die Gong-WAVE-Envelopes aus shared-115) in eine eigene Spec-Datei legen, damit Android exakt spiegeln kann. Siehe [shared-115 Gong-WAVE-Spec](project_shared115_gong_wave_spec.md) — iOS ist Referenz, Werte stammen 1:1 aus dem Design-Handoff.
- [Store-/Mail-Links im Simulator](feedback_simulator_store_and_mail_links.md) — apps.apple.com = "Adresse ungueltig" (auch fremde Apps), mailto accepted=false, `simctl pbpaste`.

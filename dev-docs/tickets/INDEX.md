# Stillmoment Ticket-System

Unified Ticket-System fuer iOS und Android mit Cross-Platform Support.

## Status-Legende

- `[ ]` TODO
- `[~]` IN PROGRESS
- `[x]` DONE

## Phasen

| Phase | Beschreibung |
|-------|--------------|
| 1-Quick Fix | Kritische Bugs, sofort beheben |
| 2-Architektur | Strukturelle Grundlagen |
| 3-Feature | Neue Funktionalitaet |
| 4-Polish | UX-Verbesserungen, Feinschliff |
| 5-QA | Tests und Qualitaetssicherung |

---

## Cross-Platform Tickets

| Nr | Ticket | Phase | iOS | Android |
|----|--------|-------|-----|---------|
| [shared-001](shared/shared-001-ambient-sound-fade.md) | Ambient Sound Fade In/Out | 4-Polish | [x] | [x] |
| [shared-002](shared/shared-002-remember-last-tab.md) | Letzten Tab merken | 4-Polish | [x] | [x] |
| [shared-003](shared/shared-003-delete-confirmation.md) | Delete Confirmation Dialog | 4-Polish | [x] | [x] |
| [shared-004](shared/shared-004-play-icon-meditation-list.md) | Play-Icon in Meditationsliste | 4-Polish | [x] | [x] |
| [shared-005](shared/shared-005-empty-state-simplify.md) | Empty State vereinfachen | 4-Polish | [x] | [x] |
| [shared-006](shared/shared-006-timer-text-adjustments.md) | Timer-Texte anpassen | 4-Polish | [x] | [x] |
| [shared-007](shared/shared-007-dependency-injection.md) | Dependency Injection Architektur | 2-Architektur | [x] | [x] |
| [shared-008](shared/shared-008-overflow-menu-meditation-list.md) | Overflow-Menü statt Edit-Icon | 4-Polish | [x] | [x] |
| [shared-009](shared/shared-009-website-android-ready.md) | Website für iOS + Android | 4-Polish | [x] | [x] |
| [shared-010](shared/shared-010-silence-label-rename.md) | Stille-Option umbenennen | 4-Polish | [x] | [x] |
| [shared-011](shared/shared-011-edit-sheet-remove-reset.md) | Edit Sheet Reset-Button entfernen | 4-Polish | [x] | [x] |
| [shared-012](shared/shared-012-portrait-only.md) | Portrait-Only Modus | 4-Polish | [x] | [x] |
| [shared-013](shared/shared-013-timer-focus-mode.md) | Timer Focus Mode | 4-Polish | [x] | [x] |
| [shared-014](shared/shared-014-interval-sound-update.md) | Neuer Interval-Sound | 4-Polish | [x] | [x] |
| [shared-015](shared/shared-015-state-machine-test-coverage.md) | State-Machine Tests TimerReducer | 5-QA | [x] | [x] |
| [shared-016](shared/shared-016-konfigurierbare-gong-toene.md) | Konfigurierbarer Start/Ende-Gong | 3-Feature | [x] | [x] |
| [shared-017](shared/shared-017-background-audio-preview.md) | Background-Audio Preview in Settings | 3-Feature | [x] | [x] |
| [shared-018](shared/shared-018-lockscreen-artwork.md) | Lock Screen Artwork | 4-Polish | [x] | [x] |
| [shared-019](shared/shared-019-background-volume-slider.md) | Lautstaerkeregler Hintergrundsounds | 4-Polish | [x] | [x] |
| [shared-020](shared/shared-020-gong-volume-slider.md) | Lautstaerkeregler Gong-Sounds | 4-Polish | [x] | [x] |
| [shared-021](shared/shared-021-settings-icon-onboarding-hint.md) | Settings-Icon und Onboarding-Hint | 4-Polish | [x] | [x] |
| [shared-022](shared/shared-022-interval-gong-volume.md) | Lautstärkeregler Intervall-Gong | 3-Feature | [x] | [x] |
| [shared-023](shared/shared-023-guided-meditation-preparation-time.md) | Vorbereitungszeit gefuehrte Meditationen | 3-Feature | [x] | [x] |
| [shared-024](shared/shared-024-clean-architecture-review.md) | Clean Architecture Layer-Review | 2-Architektur | [ ] | [ ] |
| [shared-025](shared/shared-025-fastlane-integration.md) | Fastlane Screenshots | 2-Architektur | [x] | [x] |
| [shared-026](shared/shared-026-ios-store-publishing.md) | iOS Store Publishing | 2-Architektur | [ ] | - |
| [shared-027](shared/shared-027-android-store-publishing.md) | Android Store Publishing | 2-Architektur | - | [x] |
| [shared-028](shared/shared-028-ci-release-pipeline.md) | CI Release Pipeline | 2-Architektur | [ ] | [ ] |
| [shared-029](shared/shared-029-release-prepare-workflow.md) | Release Prepare Workflow | 2-Architektur | [ ] | [ ] |

---

## iOS Tickets

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [ios-001](ios/ios-001-headphone-playpause.md) | Play/Pause kabelgebundene Kopfhoerer | 1-Quick Fix | [x] | - |
| [ios-002](ios/ios-002-ios16-support.md) | iOS 16 Support | 3-Feature | [x] | - |
| [ios-003](ios/ios-003-test-performance-analysis.md) | Test-Performance Analyse | 5-QA | [x] | - |
| [ios-005](ios/ios-005-ui-test-optimization.md) | UI-Test Optimierung (~65s Einsparung) | 5-QA | [x] | - |
| [ios-008](ios/ios-008-domain-spm-extraction.md) | Domain-Layer SPM-Extraktion | 2-Architektur | [x] WONTFIX | - |
| [ios-009](ios/ios-009-parallel-testing-stabilization.md) | Parallel Testing Stabilisierung | 1-Quick Fix | [x] | - |
| [ios-010](ios/ios-010-parallel-testing-documentation.md) | Parallelisierung Best Practices Doku | 5-QA | [x] | ios-009 |
| [ios-011](ios/ios-011-separate-test-schemes.md) | Separate Test-Schemes | 2-Architektur | [x] | ios-009 |
| [ios-012](ios/ios-012-ui-tests-library-player.md) | UI Tests Library/Player | 5-QA | [x] | ios-022 |
| [ios-013](ios/ios-013-player-remove-stop-button.md) | Player Stop-Button entfernen | 4-Polish | [x] | - |
| [ios-015](ios/ios-015-player-skip-10s.md) | Player Skip 10s vereinheitlichen | 4-Polish | [x] | - |
| [ios-016](ios/ios-016-edit-sheet-accessibility-identifiers.md) | Edit Sheet accessibilityIdentifier | 4-Polish | [x] | - |
| [ios-017](ios/ios-017-edit-sheet-accessibility-hints.md) | Edit Sheet accessibilityHint | 4-Polish | [x] | - |
| [ios-018](ios/ios-018-edit-sheet-tests.md) | Edit Sheet Unit Tests | 5-QA | [x] | - |
| [ios-019](ios/ios-019-edit-sheet-remove-original-hint.md) | Edit Sheet Original-Hinweis entfernen | 4-Polish | [x] | - |
| [ios-020](ios/ios-020-timer-reducer-architecture.md) | Timer Reducer Architecture | 2-Architektur | [x] | - |
| [ios-021](ios/ios-021-hands-heart-image.md) | Haende-Herz-Bild statt Emoji | 4-Polish | [x] | - |
| [ios-022](ios/ios-022-library-accessibility-identifiers.md) | Library accessibilityIdentifier/Hint | 4-Polish | [x] | - |
| [ios-023](ios/ios-023-screenshot-test-fixtures.md) | Screenshot Test-Fixtures | 2-Architektur | [x] | - |
| [ios-024](ios/ios-024-file-storage-copy-approach.md) | File Storage Kopie-Ansatz | 2-Architektur | [x] | - |
| [ios-025](ios/ios-025-automated-screenshots.md) | Vollautomatische Screenshots | 5-QA | [x] | ios-023 |
| [ios-026](ios/ios-026-timer-responsive-layout.md) | Timer View Responsive Layout | 4-Polish | [x] | - |
| [ios-027](ios/ios-027-player-responsive-layout.md) | Player View Responsive Layout | 4-Polish | [x] | - |
| [ios-028](ios/ios-028-interval-gong-single-play-bug.md) | Intervall-Gong spielt nur einmal | 1-Quick Fix | [x] | - |
| [ios-029](ios/ios-029-konfigurierbare-vorbereitungszeit.md) | Konfigurierbare Vorbereitungszeit | 3-Feature | [x] | - |

---

## Android Tickets

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [android-001](android/android-001-affirmations-i18n.md) | Affirmationen lokalisieren | 1-Quick Fix | [x] | - |
| [android-002](android/android-002-audio-session-coordinator.md) | Audio Session Coordinator | 2-Architektur | [x] | - |
| [android-003](android/android-003-timer-repository-impl.md) | TimerRepository Impl | 2-Architektur | [x] | - |
| [android-003-2](android/android-003-2-timer-viewmodel-repository.md) | TimerVM Repository Integration | 2-Architektur | [x] | android-003 |
| [android-004](android/android-004-guided-meditation-models.md) | GuidedMeditation Models | 3-Feature | [x] | - |
| [android-005](android/android-005-guided-meditation-repository.md) | GuidedMeditation Repository | 3-Feature | [x] | android-004 |
| [android-006](android/android-006-guided-meditation-viewmodel.md) | GuidedMeditation ViewModel | 3-Feature | [x] | android-005 |
| [android-007](android/android-007-library-screen-ui.md) | Library Screen UI | 3-Feature | [x] | android-006 |
| [android-008](android/android-008-player-screen-ui.md) | Audio Player Screen UI | 3-Feature | [x] | android-006 |
| [android-009](android/android-009-tabview-navigation.md) | TabView Navigation | 3-Feature | [x] | android-007, android-008 |
| [android-010](android/android-010-mediasession-lockscreen.md) | MediaSession Lock Screen | 4-Polish | [x] | android-008 |
| [android-011](android/android-011-accessibility-audit.md) | Accessibility Audit | 5-QA | [x] | android-009 |
| [android-012](android/android-012-ui-tests.md) | UI Tests (Component-Tests) | 5-QA | [x] | android-009 |
| [android-014](android/android-014-setdatasource-fix.md) | setDataSource Failed Fix | 1-Quick Fix | [x] | android-008 |
| [android-015](android/android-015-player-remove-progress-ring.md) | Player Progress-Ring entfernen | 4-Polish | [x] | android-008 |
| [android-016](android/android-016-storage-documentation.md) | Storage-Unterschiede Dokumentation | 5-QA | [x] | android-014 |
| [android-017](android/android-017-ui-test-interactions.md) | UI Test Interaktions-Verifikation | 5-QA | [x] WONTFIX | android-012 |
| [android-018](android/android-018-player-remove-nowplaying.md) | Player "Now Playing" + Minus entfernen | 4-Polish | [x] | - |
| [android-019](android/android-019-player-loading-indicator.md) | Player Loading-Indikator | 4-Polish | [x] | - |
| [android-020](android/android-020-player-skip-15s.md) | Player Skip 10s vereinheitlichen | 4-Polish | [x] | - |
| [android-021](android/android-021-player-effective-name-bug.md) | Player effectiveName/Teacher Bug | 1-Quick Fix | [x] | - |
| [android-023](android/android-023-section-header-simplify.md) | Section Header vereinfachen | 4-Polish | [x] | - |
| [android-024](android/android-024-list-item-remove-play-icon.md) | List Item Play-Icon entfernen | 4-Polish | [x] | - |
| [android-025](android/android-025-timer-accessibility-improvements.md) | Timer Accessibility Verbesserungen | 4-Polish | [x] | - |
| [android-026](android/android-026-timer-preview-completeness.md) | Timer Preview Vollstaendigkeit | 5-QA | [x] | - |
| [android-027](android/android-027-timer-viewmodel-test-coverage.md) | Timer ViewModel Test-Coverage | 5-QA | [x] WONTFIX | obsolet durch android-036 |
| [android-028](android/android-028-edit-sheet-reset-button.md) | Edit Sheet Reset-Button | 4-Polish | [x] | - |
| [android-029](android/android-029-edit-sheet-autocomplete.md) | Edit Sheet Autocomplete Teacher | 4-Polish | [x] | - |
| [android-031](android/android-031-edit-sheet-file-info.md) | Edit Sheet File-Info Section | 4-Polish | [x] | - |
| [android-033](android/android-033-edit-sheet-heading-semantics.md) | Edit Sheet heading() Titel | 4-Polish | [x] | - |
| [android-034](android/android-034-edit-sheet-previews.md) | Edit Sheet Previews | 5-QA | [x] | - |
| [android-035](android/android-035-edit-sheet-tests.md) | Edit Sheet State Extraktion + Tests | 5-QA | [x] | - |
| [android-036](android/android-036-timer-reducer-architecture.md) | Timer Reducer Architecture | 2-Architektur | [x] | - |
| [android-037](android/android-037-unify-app-icon.md) | App-Icon an iOS angleichen | 4-Polish | [x] | - |
| [android-038](android/android-038-hands-heart-image.md) | Haende-Herz-Bild statt Emoji | 4-Polish | [x] | - |
| [android-039](android/android-039-library-viewmodel-tests.md) | Library ViewModel Tests | 5-QA | [x] | - |
| [android-040](android/android-040-timer-completion-bug.md) | Timer Completion Bug | 1-Quick Fix | [x] | - |
| [android-041](android/android-041-remove-notification-permission.md) | Notification Permission entfernen | 4-Polish | [x] | - |
| [android-042](android/android-042-automated-screenshots.md) | Vollautomatische Screenshots | 5-QA | [x] | - |
| [android-043](android/android-043-settings-sheet-responsive.md) | SettingsSheet Scroll + Responsive | 4-Polish | [x] | - |
| [android-044](android/android-044-timer-screen-responsive.md) | TimerScreen Responsive Layout | 4-Polish | [x] | - |
| [android-045](android/android-045-player-screen-responsive.md) | PlayerScreen Responsive Layout | 4-Polish | [x] | - |
| [android-046](android/android-046-gradient-ios-angleichen.md) | Gradient an iOS angleichen | 4-Polish | [x] | - |
| [android-047](android/android-047-audio-services-testability.md) | Audio-Services Testbarkeit | 2-Architektur | [x] | - |
| [android-048](android/android-048-detekt-baseline-issues.md) | detekt Baseline Issues beheben | 5-QA | [x] | - |
| [android-049](android/android-049-ci-ktlint-detekt.md) | CI um ktlint/detekt erweitern | 5-QA | [x] | android-048 |
| [android-050](android/android-050-detekt-baseline-cleanup.md) | detekt Baseline systematisch abbauen | 5-QA | [x] | android-049 |
| [android-051](android/android-051-detekt-compose-compliance.md) | detekt-compose Rules Compliance | 5-QA | [x] | android-050 |
| [android-052](android/android-052-pure-content-pattern.md) | Pure Content Pattern Screenshot-Tests | 2-Architektur | [x] WONTFIX | - |
| [android-053](android/android-053-wheelpicker-api-improvements.md) | WheelPicker API-Verbesserungen | 2-Architektur | [x] | - |
| [android-054](android/android-054-timer-repository-interface.md) | TimerRepository Interface erweitern | 2-Architektur | [x] | - |
| [android-055](android/android-055-progress-update-interval.md) | Progress-Update-Interval optimieren | 4-Polish | [x] | - |
| [android-056](android/android-056-audio-focus-management.md) | AudioFocus Management implementieren | 2-Architektur | [x] | - |
| [android-057](android/android-057-konfigurierbare-vorbereitungszeit.md) | Konfigurierbare Vorbereitungszeit | 3-Feature | [x] | - |
| [android-058](android/android-058-settings-sofort-speichern.md) | Settings sofort speichern | 4-Polish | [x] | - |
| [android-059](android/android-059-settings-card-layout.md) | SettingsSheet Card-Layout | 4-Polish | [x] | - |
| [android-060](android/android-060-dropdown-styling.md) | Dropdown-Styling an iOS angleichen | 4-Polish | [x] | - |

---

## Workflow

```bash
# 1. Ticket lesen
cat dev-docs/tickets/ios/ios-001-headphone-playpause.md
cat dev-docs/tickets/android/android-005-guided-meditation-repository.md
cat dev-docs/tickets/shared/shared-001-ambient-sound-fade.md

# 2. Claude Code beauftragen
"Setze Ticket ios-001 um gemaess der Spezifikation"
"Setze den iOS-Subtask von shared-001 um"

# 3. Tests ausfuehren
cd ios && make test-unit
cd android && ./gradlew test

# 4. Status in INDEX.md aktualisieren
```

---

## Branch-Konvention

```bash
# Platform-spezifisch
git checkout -b feature/ios-001-headphone-playpause
git checkout -b feature/android-005-guided-meditation-repository

# Cross-Platform (separate Branches pro Plattform)
git checkout -b feature/shared-001-ambient-fade-ios
git checkout -b feature/shared-001-ambient-fade-android
```

## Commit-Konvention

```bash
feat(ios): #ios-001 Play/Pause fuer kabelgebundene Kopfhoerer
fix(android): #android-001 Affirmationen lokalisieren
feat(shared): #shared-001 Ambient Sound Fade (iOS)
feat(shared): #shared-001 Ambient Sound Fade (Android)
```

---

## Dokumentations-Regel

Jedes Ticket muss bei Abschluss folgende Dokumentation aktualisieren:

| Ticket-Typ | CHANGELOG.md | CLAUDE.md | README.md |
|------------|--------------|-----------|-----------|
| Bug Fix | Ja | Nein | Nein |
| Feature | Ja | Bei Architektur | Bei Major |
| Architektur | Ja | Ja | Nein |
| QA | Nein | Nein | Nein |

---

## Templates

- [TEMPLATE-platform.md](TEMPLATE-platform.md) - Vorlage fuer ios-/android-Tickets
- [TEMPLATE-shared.md](TEMPLATE-shared.md) - Vorlage fuer shared-Tickets

---

## Ticket-Philosophie

**Tickets beschreiben das WAS und WARUM, nicht das WIE.**

| Gehoert ins Ticket | Gehoert NICHT ins Ticket |
|--------------------|--------------------------|
| Was soll gemacht werden? | Code-Implementierung |
| Warum ist es wichtig? | Dateilisten (neu/aendern) |
| Akzeptanzkriterien | Architektur-Diagramme |
| Manueller Testfall | Test-Befehle |
| Referenz auf existierenden Code | Zeilennummern |
| Nicht-offensichtliche Hinweise | Offensichtliche Patterns |

**Warum?**
- Claude Code hat Zugriff auf CLAUDE.md (Architektur, Commands, Patterns)
- Claude Code kann bestehenden Code als Referenz lesen
- Claude Code kann selbst bessere Loesungen finden
- Weniger Pflege-Aufwand fuer Tickets

---

## Design-Richtlinien

**Ziel:** Eine einfache, warmherzige Meditations-App, die dem User hilft und sich nicht in den Vordergrund draengt.

### Grundprinzipien

| Prinzip | Bedeutung |
|---------|-----------|
| **Einfach > Feature-reich** | Weniger ist mehr |
| **Ruhe > Information** | Meditations-App, nicht Dashboard |
| **Unaufdringlich** | Hilft, draengt sich nicht auf |
| **Warmherzig** | Freundlich, nicht steril |

### Entscheidungskriterien fuer Features

**Vor jedem Ticket fragen:**
1. Hilft das dem User bei der Meditation? (nicht nur "ist es nuetzlich?")
2. Wuerde das Fehlen den User stoeren?
3. Ist es die einfachste Loesung?

**Red Flags (Ticket ueberdenken):**
- "Android/iOS hat das auch" - Kein guter Grund allein
- "Koennte nuetzlich sein" - Wahrscheinlich nicht noetig
- "Mehr Information fuer den User" - Oft das Gegenteil von hilfreich
- "Feature-Parity" - Nur wenn beide Plattformen davon profitieren

### Plattform-Konsistenz

| Situation | Empfehlung |
|-----------|------------|
| Feature sinnvoll fuer beide | Shared Ticket, identische UX |
| Plattform-Pattern unterschiedlich | Separate Umsetzung, gleiches Ziel |
| Feature nur auf einer Plattform sinnvoll | Nur dort umsetzen |
| Feature auf einer Plattform ueberfluessig | Dort entfernen, nicht portieren |

### Qualitaets-Pflicht

- **Accessibility bleibt Pflicht** - Einfachheit ≠ weniger Accessibility
- **Performance zaehlt** - Schnelle App = unaufdringliche App

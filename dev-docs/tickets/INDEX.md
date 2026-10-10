# Ticket-Index

> Generiert von `make tickets-index` — nicht von Hand bearbeiten.
> Konventionen, Workflow und Frontmatter-Format: [README.md](README.md)

Status: `[ ]` offen · `[~]` in Arbeit · `[x]` erledigt · `[-]` wontfix · `-` nicht betroffen

## Aktiv

### Cross-Platform

| Nr | Ticket | Phase | iOS | Android |
|----|--------|-------|-----|---------|
| [shared-028](shared/shared-028-ci-release-pipeline.md) | CI Release Pipeline | 2-Architektur | [ ] | [ ] |
| [shared-047](shared/shared-047-meditation-export-share.md) | Meditation exportieren / teilen | 3-Feature | [ ] | [ ] |
| [shared-060](shared/shared-060-domain-bounded-contexts.md) | Domain-Layer Bounded Contexts | 2-Architektur | [ ] | [ ] |
| [shared-085](shared/shared-085-store-website-meditationen-zuerst.md) | Store + Website spiegeln Meditationen-zuerst-IA | 4-Polish | [ ] | [ ] |
| [shared-117](shared/shared-117-lautstaerke-normalisierung.md) | Lautstärke-Normalisierung gefuehrter Meditationen | 3-Feature | [ ] | [ ] |
| [shared-123](shared/shared-123-backup-geraetewechsel-bibliothek.md) | Bibliothek beim Geraetewechsel — Backup-Verhalten klaeren | 3-Feature | [ ] | [ ] |
| [shared-125](shared/shared-125-timer-zeitauswahl-wert-und-bahn.md) | Timer-Zeitauswahl als Wert und Bahn | 4-Polish | [ ] | [ ] |
| [shared-129](shared/shared-129-podcast-import-aeltere-folgen.md) | Podcast-Import auch fuer aeltere Folgen | 3-Feature | [ ] | [ ] |
| [shared-138](shared/shared-138-teilen-waehrend-laufendem-import.md) | Teilen während eines laufenden Imports: der zuletzt geteilte Eintrag gewinnt, nichts geht still verloren | 4-Polish | [ ] | [ ] |
| [shared-139](shared/shared-139-dauer-im-bearbeiten-blatt-sichtbar.md) | Bearbeiten-Blatt: Dauer bleibt neben langem Dateinamen sichtbar | 4-Polish | [ ] | [ ] |
| [shared-140](shared/shared-140-einzahl-bei-einer-minute.md) | Einzahl bei einer Minute im Atemkreis und in Ansagen | 4-Polish | [ ] | [ ] |
| [shared-141](shared/shared-141-timer-dial-singular-minute.md) | Timer-Zifferblatt zeigt „1 Minuten“ statt „1 Minute“ | 4-Polish | [ ] | [ ] |

### iOS

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [ios-050](ios/ios-050-typografie-2-1-a11y-layout.md) | Typografie 2.1 — Layout-Anpassungen fuer DT AX2+ | 5-QA | [ ] | [ios-048](archive/ios/ios-048-typografie-newsreader-geist.md) |
| [ios-056](ios/ios-056-ui-tests-unabhaengig-vom-simulator.md) | UI-Tests unabhängig vom Zustand des Simulators | 5-QA | [ ] | [ios-055](archive/ios/ios-055-dienste-nur-im-app-einstieg-erzeugen.md) |
| [ios-057](ios/ios-057-unit-tests-ohne-reste-im-app-ordner.md) | Unit-Tests hinterlassen keine Daten im echten App-Ordner | 5-QA | [ ] | - |
| [ios-058](ios/ios-058-audio-koordinator-ohne-singleton.md) | Audio-Koordinator wie alle anderen Dienste im App-Einstieg erzeugen | 5-QA | [ ] | [ios-055](archive/ios/ios-055-dienste-nur-im-app-einstieg-erzeugen.md) |
| [ios-061](ios/ios-061-link-ohne-pfad-geht-verloren.md) | Geteilter Link ohne Pfad: „Fast geschafft“, aber die App übernimmt nichts | 1-Quick Fix | [ ] | - |

### Android

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [android-079](android/android-079-custom-audio-import-dauer-performance.md) | Custom-Audio-Import langer Dateien beschleunigen (Dauer-Erkennung) | 4-Polish | [ ] | - |
| [android-082](android/android-082-instrumented-tests-android-16.md) | Instrumented Tests auf Android 16 wieder gruen | 5-QA | [ ] | [android-081](archive/android/android-081-target-sdk-36-android-16.md) |
| [android-083](android/android-083-composables-app-darstellung.md) | Fuenf Composables folgen dem Geraet statt der App-Darstellung | 4-Polish | [ ] | [shared-122](archive/shared/shared-122-default-darstellung-dunkel.md) |
| [android-086](android/android-086-lehrer-feld-beschriftung-ueberlappt.md) | Bearbeiten-Blatt: Beschriftung des Lehrer-Felds liegt über dem vorausgefüllten Namen | 4-Polish | [ ] | - |
| [android-087](android/android-087-geladene-dateien-wegraeumen.md) | Beim Link- und Podcast-Import geladene Dateien werden weggeräumt | 4-Polish | [ ] | - |
| [android-088](android/android-088-bibliothek-doppelter-randabstand.md) | Bibliothek und Bearbeiten-Blatt verschenken Höhe an doppelte Randabstände | 4-Polish | [ ] | - |
| [android-090](android/android-090-r8-agp9-defaults.md) | Release-Build auf die R8-Standards von AGP 9 umstellen | 2-Architektur | [ ] | - |
| [android-091](android/android-091-veraltete-apis-nach-androidx-update.md) | Veraltete AndroidX-/Compose-APIs nach dem Dependabot-Update ersetzen | 5-QA | [~] | - |
| [android-092](android/android-092-ci-gradle-cache-version-catalog.md) | CI-Gradle-Cache erneuert sich bei Änderungen am Version-Catalog | 5-QA | [ ] | - |
| [android-093](android/android-093-wischgesten-ohne-veraltete-api.md) | Wischgesten in Bibliothek und Suche ohne veraltete Compose-API | 5-QA | [ ] | [android-091](android/android-091-veraltete-apis-nach-androidx-update.md) |
| [android-094](android/android-094-media3-session-statt-compat.md) | Sperrbildschirm-Steuerung und Wiedergabe-Benachrichtigung ohne veraltete MediaSession-Kompatibilitätsbibliothek | 2-Architektur | [ ] | - |

## Archiv

### Cross-Platform

| Nr | Ticket | Phase | iOS | Android |
|----|--------|-------|-----|---------|
| [shared-001](archive/shared/shared-001-ambient-sound-fade.md) | Ambient Sound Fade In/Out | 4-Polish | [x] | [x] |
| [shared-002](archive/shared/shared-002-remember-last-tab.md) | Letzten Tab merken | 4-Polish | [x] | [x] |
| [shared-003](archive/shared/shared-003-delete-confirmation.md) | Delete Confirmation Dialog | 4-Polish | [x] | [x] |
| [shared-004](archive/shared/shared-004-play-icon-meditation-list.md) | Play-Icon in Meditationsliste | 4-Polish | [x] | [x] |
| [shared-005](archive/shared/shared-005-empty-state-simplify.md) | Empty State vereinfachen | 4-Polish | [x] | [x] |
| [shared-006](archive/shared/shared-006-timer-text-adjustments.md) | Timer-Texte anpassen | 4-Polish | [x] | [x] |
| [shared-007](archive/shared/shared-007-dependency-injection.md) | Dependency Injection Architektur | 2-Architektur | [x] | [x] |
| [shared-008](archive/shared/shared-008-overflow-menu-meditation-list.md) | Overflow-Menü statt Edit-Icon | 4-Polish | [x] | [x] |
| [shared-009](archive/shared/shared-009-website-android-ready.md) | Website für iOS + Android | 4-Polish | [x] | [x] |
| [shared-010](archive/shared/shared-010-silence-label-rename.md) | Stille-Option umbenennen | 4-Polish | [x] | [x] |
| [shared-011](archive/shared/shared-011-edit-sheet-remove-reset.md) | Edit Sheet Reset-Button entfernen | 4-Polish | [x] | [x] |
| [shared-012](archive/shared/shared-012-portrait-only.md) | Portrait-Only Modus | 4-Polish | [x] | [x] |
| [shared-013](archive/shared/shared-013-timer-focus-mode.md) | Timer Focus Mode | 4-Polish | [x] | [x] |
| [shared-014](archive/shared/shared-014-interval-sound-update.md) | Neuer Interval-Sound | 4-Polish | [x] | [x] |
| [shared-015](archive/shared/shared-015-state-machine-test-coverage.md) | State-Machine Tests TimerReducer | 5-QA | [x] | [x] |
| [shared-016](archive/shared/shared-016-konfigurierbare-gong-toene.md) | Konfigurierbarer Start/Ende-Gong | 3-Feature | [x] | [x] |
| [shared-017](archive/shared/shared-017-background-audio-preview.md) | Background-Audio Preview in Settings | 3-Feature | [x] | [x] |
| [shared-018](archive/shared/shared-018-lockscreen-artwork.md) | Lock Screen Artwork | 4-Polish | [x] | [x] |
| [shared-019](archive/shared/shared-019-background-volume-slider.md) | Lautstaerkeregler Hintergrundsounds | 4-Polish | [x] | [x] |
| [shared-020](archive/shared/shared-020-gong-volume-slider.md) | Lautstaerkeregler Gong-Sounds | 4-Polish | [x] | [x] |
| [shared-021](archive/shared/shared-021-settings-icon-onboarding-hint.md) | Settings-Icon und Onboarding-Hint | 4-Polish | [x] | [x] |
| [shared-022](archive/shared/shared-022-interval-gong-volume.md) | Lautstärkeregler Intervall-Gong | 3-Feature | [x] | [x] |
| [shared-023](archive/shared/shared-023-guided-meditation-preparation-time.md) | Vorbereitungszeit gefuehrte Meditationen | 3-Feature | [x] | [x] |
| [shared-024](archive/shared/shared-024-clean-architecture-review.md) | Clean Architecture Layer-Review | 2-Architektur | [x] | [x] |
| [shared-025](archive/shared/shared-025-fastlane-integration.md) | Fastlane Screenshots | 2-Architektur | [x] | [x] |
| [shared-026](archive/shared/shared-026-ios-store-publishing.md) | iOS Store Publishing | 2-Architektur | [x] | - |
| [shared-027](archive/shared/shared-027-android-store-publishing.md) | Android Store Publishing | 2-Architektur | - | [x] |
| [shared-029](archive/shared/shared-029-release-prepare-workflow.md) | Release Prepare Workflow | 2-Architektur | [x] | [x] |
| [shared-030](archive/shared/shared-030-release-notes-skill.md) | Release Notes Skill | 2-Architektur | [x] | [x] |
| [shared-031](archive/shared/shared-031-import-opens-edit-sheet.md) | Edit Sheet nach Import oeffnen | 4-Polish | [x] | [x] |
| [shared-032](archive/shared/shared-032-customizable-color-themes.md) | Customizable Color Themes | 3-Feature | [x] | [x] |
| [shared-033](archive/shared/shared-033-dark-mode-paletten.md) | Theme-Paletten finalisieren | 4-Polish | [x] | [x] |
| [shared-034](archive/shared/shared-034-theme-picker-vorschau.md) | Theme-Vorschau im Picker | 4-Polish | [x] | [x] |
| [shared-035](archive/shared/shared-035-kontrast-audit-wcag.md) | Kontrast-Audit WCAG-Validierung | 5-QA | [x] | [x] |
| [shared-036](archive/shared/shared-036-kern-features-navigation-pattern.md) | Kern-Features Navigation Pattern | 2-Architektur | [x] | [x] |
| [shared-037](archive/shared/shared-037-typography-system.md) | Zentrales Typography System | 2-Architektur | [x] | [x] |
| [shared-038](archive/shared/shared-038-import-reibung-eliminieren.md) | ~~Import-Reibung eliminieren~~ (aufgeteilt in 043-045) | 3-Feature | [x] | [x] |
| [shared-039](archive/shared/shared-039-empty-state-content-guide.md) | Empty State + In-App Content Guide | 3-Feature | [x] | [x] |
| [shared-039b](archive/shared/shared-039b-import-anleitungen.md) | Import-Anleitungen im Content Guide | 4-Polish | [x] | - |
| [shared-040](archive/shared/shared-040-app-store-narrativ.md) | App Store Narrativ und Screenshots | 4-Polish | [-] | [-] |
| [shared-041](archive/shared/shared-041-appearance-mode-selection.md) | Appearance Mode Selection | 3-Feature | [x] | [x] |
| [shared-042](archive/shared/shared-042-settings-appearance-section.md) | Settings Erscheinungsbild-Section | 4-Polish | [x] | [x] |
| [shared-043](archive/shared/shared-043-import-auto-metadaten.md) | Import Auto-Metadaten (kein Edit Sheet) | 3-Feature | [-] | [-] |
| [shared-044](archive/shared/shared-044-batch-import.md) | Batch Import (Mehrfachauswahl) | 3-Feature | [-] | [-] |
| [shared-045](archive/shared/shared-045-share-sheet-file-association.md) | File Association ("Oeffnen mit") | 3-Feature | [x] | [x] |
| [shared-046](archive/shared/shared-046-share-extension.md) | Share Extension ("Teilen") | 3-Feature | [x] | [x] |
| [shared-048](archive/shared/shared-048-timer-remove-pause.md) | Timer Pause-Button entfernen | 4-Polish | [x] | [x] |
| [shared-049](archive/shared/shared-049-flexible-interval-gongs.md) | Flexible Intervallklaenge | 3-Feature | [x] | [x] |
| [shared-050](archive/shared/shared-050-optionale-einleitung-timer.md) | Optionale Einleitung Meditationstimer | 3-Feature | [x] | [x] |
| [shared-051](archive/shared/shared-051-timer-presets-custom-audio.md) | ~~Meditation Timer Presets & Custom Audio~~ (aufgeteilt in 061-066) | 3-Feature | [x] | [x] |
| [shared-052](archive/shared/shared-052-timer-completion-danke.md) | Timer Completion "Danke" | 4-Polish | [x] | [x] |
| [shared-053](archive/shared/shared-053-guided-meditation-completion.md) | Guided Meditation Completion Screen | 4-Polish | [x] | [x] |
| [shared-054](archive/shared/shared-054-preview-audio-trennen.md) | Preview-Audio von Timer-Lifecycle trennen | 2-Architektur | [x] | [x] |
| [shared-055](archive/shared/shared-055-endgong-phase.md) | endGong als eigene Phase | 2-Architektur | [x] | [x] |
| [shared-056](archive/shared/shared-056-tick-emittiert-events.md) | tick() emittiert Domain Events | 2-Architektur | [x] | [x] |
| [shared-057](archive/shared/shared-057-display-state-eliminieren.md) | TimerDisplayState eliminieren | 2-Architektur | [x] | [x] |
| [shared-058](archive/shared/shared-058-entscheidungspunkt-aggregate.md) | Entscheidungspunkt Aggregate | 2-Architektur | [x] | [x] |
| [shared-059](archive/shared/shared-059-keep-alive-invariante.md) | Keep-Alive strukturell absichern | 2-Architektur | [x] | [x] |
| [shared-061](archive/shared/shared-061-einstellungen-tab.md) | Einstellungen-Tab und 3-Tab-Navigation | 2-Architektur | [x] | [x] |
| [shared-062](archive/shared/shared-062-praxis-datenmodell.md) | Praxis-Datenmodell und Persistenz | 2-Architektur | [x] | [x] |
| [shared-063](archive/shared/shared-063-praxis-auswahl.md) | ~~Praxis-Auswahl (Pill-Button & Bottom Sheet)~~ WONTFIX | 3-Feature | [-] | [-] |
| [shared-064](archive/shared/shared-064-praxis-editor.md) | Praxis-Editor und Settings-Abloesung | 3-Feature | [x] | [x] |
| [shared-065](archive/shared/shared-065-custom-audio-import.md) | Custom Audio Import | 3-Feature | [x] | [x] |
| [shared-066](archive/shared/shared-066-zen-modus.md) | Zen-Modus (Tab-Bar ausblenden) | 4-Polish | [x] | [x] |
| [shared-067](archive/shared/shared-067-rename-introduction-attunement.md) | Code-Rename Introduction → Attunement | 4-Polish | [x] | [x] |
| [shared-068](archive/shared/shared-068-praxis-vereinfachen.md) | Praxis vereinfachen – Einzelkonfiguration | 2-Architektur | [x] | [x] |
| [shared-069](archive/shared/shared-069-sound-selection-ux-konsistenz.md) | Sound-Auswahl UX-Konsistenz (Overflow-Menü + Icon-Selektor) | 4-Polish | [x] | [x] |
| [shared-070](archive/shared/shared-070-guided-settings-in-globale-settings.md) | Guided-Meditation-Einstellungen in globale Settings | 4-Polish | [x] | [x] |
| [shared-071](archive/shared/shared-071-tab-bibliothek-rename-meditationen.md) | Tab "Bibliothek" → "Meditationen" + Icon waveform | 4-Polish | [x] | [x] |
| [shared-072](archive/shared/shared-072-einstimmung-toggle-konsistenz.md) | Einstimmung Toggle statt Picker-Option "Ohne Einstimmung" | 4-Polish | [x] | [x] |
| [shared-073](archive/shared/shared-073-import-typ-auswahl.md) | Datei-Import mit Typ-Auswahl | 3-Feature | [x] | [x] |
| [shared-074](archive/shared/shared-074-audio-resolver-services.md) | Einheitliche Audio-Resolver (Einstimmung + Klangatmosphaere) | 2-Architektur | [x] | [x] |
| [shared-075](archive/shared/shared-075-library-long-press-preview.md) | Long-Press Preview in der Meditations-Bibliothek | 3-Feature | [x] | [x] |
| [shared-076](archive/shared/shared-076-gong-vibration.md) | Vibration als Gong-Signal | 3-Feature | [x] | [x] |
| [shared-077](archive/shared/shared-077-philosophie-zitat-settings.md) | Philosophie-Zitat in den Einstellungen | 4-Polish | [-] | [-] |
| [shared-078](archive/shared/shared-078-emotionale-store-texte.md) | App Store + Website – Emotionaler Ton | 4-Polish | [-] | [-] |
| [shared-079](archive/shared/shared-079-screenshot-pipeline-hardening.md) | Screenshot-Pipeline Hardening | 3-Feature | [x] | [x] |
| [shared-080](archive/shared/shared-080-completion-screen-survive-termination.md) | Danke-Screen ueberlebt App-Termination | 4-Polish | [x] | [x] |
| [shared-081](archive/shared/shared-081-library-filter-nach-dauer.md) | Filter nach Dauer in der Meditationsliste | 3-Feature | [x] | [x] |
| [shared-082](archive/shared/shared-082-download-konstellations-animation.md) | Download-Modal mit Konstellations-Animation | 4-Polish | [x] | [x] |
| [shared-083](archive/shared/shared-083-setting-karten-timer-konfig.md) | Setting-Karten auf Timer-Konfig statt versteckter Pills | 3-Feature | [x] | [-] |
| [shared-084](archive/shared/shared-084-meditationen-tab-zuerst.md) | Meditationen-Tab als erster Tab | 4-Polish | [x] | [x] |
| [shared-086](archive/shared/shared-086-atemkreis-picker-timer-konfig.md) | Atemkreis-Picker und UI-Feinpolitur am Timer-Konfig | 4-Polish | [x] | [x] |
| [shared-087](archive/shared/shared-087-player-atemkreis-redesign.md) | Guided Meditation Player Redesign — Atemkreis & Auto-Start | 3-Feature | [x] | [x] |
| [shared-088](archive/shared/shared-088-einstimmung-feature-entfernen.md) | Einstimmung-Feature entfernen | 2-Architektur | [x] | [x] |
| [shared-089](archive/shared/shared-089-timer-idle-listen-layout.md) | Timer-Idle-Screen mit flacher Settings-Liste | 4-Polish | [x] | [x] |
| [shared-090](archive/shared/shared-090-timer-atemkreis-analog-player.md) | Timer-Display analog zum Player (Atemkreis) | 4-Polish | [x] | [x] |
| [shared-091](archive/shared/shared-091-url-share-ohne-extension.md) | URL-Share akzeptiert Audio-URLs ohne .mp3/.m4a-Endung | 1-Quick Fix | [x] | [x] |
| [shared-092](archive/shared/shared-092-danke-screen-redesign.md) | Danke-Screen Redesign — Atemkreis statt Herz | 4-Polish | [x] | [-] |
| [shared-093](archive/shared/shared-093-theme-system-vereinfachen.md) | Theme-System auf ein Theme reduzieren | 2-Architektur | [x] | [x] |
| [shared-094](archive/shared/shared-094-theme-refinement-kerzenschein.md) | Theme-Refinement Kerzenschein 2.0 | 4-Polish | [x] | [x] |
| [shared-095](archive/shared/shared-095-running-timer-mondphase.md) | Running-Timer-Visualisierung Mondphase | 4-Polish | [x] | [x] |
| [shared-096](archive/shared/shared-096-player-kerzenschein-refinement.md) | Player-Refinement Kerzenschein 2.0 | 4-Polish | [x] | [x] |
| [shared-097](archive/shared/shared-097-danke-screen-kerzenschein.md) | Danke-Screen Refinement Kerzenschein 2.0 | 4-Polish | [x] | [x] |
| [shared-098](archive/shared/shared-098-library-preview-scrub-slider.md) | Library-Preview mit Scrub-Slider | 3-Feature | [x] | [x] |
| [shared-099](archive/shared/shared-099-typografie-newsreader-geist-android.md) | Typografie Newsreader + Geist (Android-Sync zu ios-048) | 4-Polish | [x] | [x] |
| [shared-100](archive/shared/shared-100-idle-ring-duenn-android.md) | Idle-Ring duenn in Running-Sprache (Android-Sync zu ios-045) | 4-Polish | [x] | [x] |
| [shared-101](archive/shared/shared-101-library-search-android.md) | Library-Suche (Android-Sync zu ios-041) | 3-Feature | [x] | [x] |
| [shared-102](archive/shared/shared-102-library-header-search-android.md) | Library-Header mit immer sichtbarem Suchfeld (Android-Sync zu ios-051) | 4-Polish | [x] | [x] |
| [shared-103](archive/shared/shared-103-share-import-verbesserungen-android.md) | Share-Import-Verbesserungen (Android-Sync zu ios-042/043/044) | 3-Feature | [x] | [x] |
| [shared-104](archive/shared/shared-104-import-anleitungen-android.md) | Import-Anleitungen im Content Guide (Android-Sync zu shared-039b) | 4-Polish | [x] | [x] |
| [shared-105](archive/shared/shared-105-trim-punkte-gefuehrte-meditationen.md) | Trim-Punkte fuer gefuehrte Meditationen | 3-Feature | [x] | [x] |
| [shared-106](archive/shared/shared-106-start-end-gong-pro-meditation.md) | Start- und End-Gong pro Meditation | 3-Feature | [x] | [x] |
| [shared-107](archive/shared/shared-107-waveform-trim-editor.md) | Waveform-Trim-Editor fuer den Wiedergabe-Bereich | 3-Feature | [x] | [x] |
| [shared-108](archive/shared/shared-108-waveform-zoom-trim-editor.md) | Zoom in die Waveform des Trim-Editors | 3-Feature | [x] | [x] |
| [shared-109](archive/shared/shared-109-waveform-player-tonkopf.md) | Waveform Player „Tonkopf" | 3-Feature | [x] | [x] |
| [shared-110](archive/shared/shared-110-editor-screen-discard-schutz.md) | Meditation-Editor als Vollbild-Screen mit Discard-Schutz | 2-Architektur | [x] | [x] |
| [shared-111](archive/shared/shared-111-praxis-editor-explizit-speichern.md) | ~~Praxis-Editor mit explizitem Speichern/Abbrechen~~ WONTFIX (kein Praxis-Editor existiert; Timer ist bewusst Inline-Auto-Save) | 4-Polish | [-] | [-] |
| [shared-112](archive/shared/shared-112-trim-zurueck-dirtied-editor.md) | Trim-Editor — nur „Zurück", Änderungen markieren den Editor | 4-Polish | [x] | [x] |
| [shared-113](archive/shared/shared-113-toten-praxis-editor-code-entfernen.md) | Toten Praxis-Editor-Code entfernen & ViewModel umbenennen | 4-Polish | [x] | [x] |
| [shared-114](archive/shared/shared-114-topbar-navigation-boilerplate.md) | Top-Bar-Navigations-Boilerplate zentralisieren | 4-Polish | [x] | [x] |
| [shared-115](archive/shared/shared-115-gong-auswahl-redesign.md) | Gong-Auswahl "Start & Ende" Redesign | 4-Polish | [x] | [x] |
| [shared-116](archive/shared/shared-116-meditation-editor-gong-klang-picker.md) | Meditation-Editor — Klang-Auswahl als Karten-Picker + Section-Überschriften | 4-Polish | [x] | [x] |
| [shared-118](archive/shared/shared-118-intervall-gong-editor-redesign.md) | Intervall-Gong-Editor an Klang-Auswahl-Vorlage angleichen | 4-Polish | [x] | [x] |
| [shared-119](archive/shared/shared-119-vorbereitungszeit-screen-redesign.md) | Vorbereitungszeit-Screen an neue Timer-Vorlage angleichen | 4-Polish | [x] | [x] |
| [shared-120](archive/shared/shared-120-intervall-gong-master-karte-modus-hinweis.md) | Intervall-Gong-Screen — Master-Karte, Modus-Hinweis & Off-Zustand (Handoff intervall-gongs) | 4-Polish | [x] | [x] |
| [shared-121](archive/shared/shared-121-hintergrundklang-screen-redesign.md) | Hintergrundklang-Screen an Klang-Auswahl-Vorlage angleichen (Handoff soundscape) | 4-Polish | [x] | [x] |
| [shared-122](archive/shared/shared-122-default-darstellung-dunkel.md) | Dunkle Darstellung als Standard | 1-Quick Fix | [x] | [x] |
| [shared-126](archive/shared/shared-126-timer-start-als-play-knopf.md) | Timer-Start als runder Play-Knopf | 4-Polish | [x] | [x] |
| [shared-127](archive/shared/shared-127-datenschutz-netzwerkzugriffe-ehrlich.md) | Datenschutzerklaerung und Offline-Versprechen ehrlich formulieren | 1-Quick Fix | [x] | [x] |
| [shared-128](archive/shared/shared-128-podcast-folge-aus-apple-podcasts.md) | Podcast-Folge aus Apple Podcasts importieren | 3-Feature | [x] | [x] |
| [shared-130](archive/shared/shared-130-ticket-system-archiv-frontmatter-index.md) | Ticket-System mit Archiv, Frontmatter und generiertem Index | 2-Architektur | [x] | [x] |
| [shared-131](archive/shared/shared-131-gleiche-audio-dateitypen-beim-link-import.md) | Gleiche Audio-Dateitypen beim Link- und Podcast-Import | 4-Polish | [x] | [x] |
| [shared-132](archive/shared/shared-132-mehrfach-teilen-ohne-fehler.md) | Mehrfaches Teilen an Still Moment: kein Fehler, der zuletzt geteilte Eintrag gewinnt | 4-Polish | [x] | [x] |
| [shared-133](archive/shared/shared-133-anleitung-import-apple-podcasts.md) | Anleitung "So importierst du aus Apple Podcasts" | 4-Polish | [x] | [x] |
| [shared-134](archive/shared/shared-134-app-bewerten-und-schreib-uns.md) | App bewerten und Schreib uns in den Einstellungen | 3-Feature | [x] | [x] |
| [shared-135](archive/shared/shared-135-eigener-abschnitt-rueckmeldung.md) | Eigener Abschnitt Rückmeldung in den Einstellungen | 4-Polish | [x] | [x] |
| [shared-136](archive/shared/shared-136-schrift-nachweise-ofl.md) | Schrift-Nachweise (OFL) in den Einstellungen | 5-QA | [x] | [x] |
| [shared-137](archive/shared/shared-137-quellenliste-sprachen-lehrerinnen.md) | Quellenliste: Lehrer:innen vorne, alle Sprachen sichtbar | 4-Polish | [x] | [x] |

### iOS

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [ios-001](archive/ios/ios-001-headphone-playpause.md) | Play/Pause kabelgebundene Kopfhoerer | 1-Quick Fix | [x] | - |
| [ios-002](archive/ios/ios-002-ios16-support.md) | iOS 16 Support | 3-Feature | [x] | - |
| [ios-003](archive/ios/ios-003-test-performance-analysis.md) | Test-Performance Analyse | 5-QA | [x] | - |
| [ios-005](archive/ios/ios-005-ui-test-optimization.md) | UI-Test Optimierung (~65s Einsparung) | 5-QA | [x] | - |
| [ios-008](archive/ios/ios-008-domain-spm-extraction.md) | Domain-Layer SPM-Extraktion | 2-Architektur | [-] | - |
| [ios-009](archive/ios/ios-009-parallel-testing-stabilization.md) | Parallel Testing Stabilisierung | 1-Quick Fix | [x] | - |
| [ios-010](archive/ios/ios-010-parallel-testing-documentation.md) | Parallelisierung Best Practices Doku | 5-QA | [x] | [ios-009](archive/ios/ios-009-parallel-testing-stabilization.md) |
| [ios-011](archive/ios/ios-011-separate-test-schemes.md) | Separate Test-Schemes | 2-Architektur | [x] | [ios-009](archive/ios/ios-009-parallel-testing-stabilization.md) |
| [ios-012](archive/ios/ios-012-ui-tests-library-player.md) | UI Tests Library/Player | 5-QA | [x] | [ios-022](archive/ios/ios-022-library-accessibility-identifiers.md) |
| [ios-013](archive/ios/ios-013-player-remove-stop-button.md) | Player Stop-Button entfernen | 4-Polish | [x] | - |
| [ios-015](archive/ios/ios-015-player-skip-10s.md) | Player Skip 10s vereinheitlichen | 4-Polish | [x] | - |
| [ios-016](archive/ios/ios-016-edit-sheet-accessibility-identifiers.md) | Edit Sheet accessibilityIdentifier | 4-Polish | [x] | - |
| [ios-017](archive/ios/ios-017-edit-sheet-accessibility-hints.md) | Edit Sheet accessibilityHint | 4-Polish | [x] | - |
| [ios-018](archive/ios/ios-018-edit-sheet-tests.md) | Edit Sheet Unit Tests | 5-QA | [x] | - |
| [ios-019](archive/ios/ios-019-edit-sheet-remove-original-hint.md) | Edit Sheet Original-Hinweis entfernen | 4-Polish | [x] | - |
| [ios-020](archive/ios/ios-020-timer-reducer-architecture.md) | Timer Reducer Architecture | 2-Architektur | [x] | - |
| [ios-021](archive/ios/ios-021-hands-heart-image.md) | Haende-Herz-Bild statt Emoji | 4-Polish | [x] | - |
| [ios-022](archive/ios/ios-022-library-accessibility-identifiers.md) | Library accessibilityIdentifier/Hint | 4-Polish | [x] | - |
| [ios-023](archive/ios/ios-023-screenshot-test-fixtures.md) | Screenshot Test-Fixtures | 2-Architektur | [x] | - |
| [ios-024](archive/ios/ios-024-file-storage-copy-approach.md) | File Storage Kopie-Ansatz | 2-Architektur | [x] | - |
| [ios-025](archive/ios/ios-025-automated-screenshots.md) | Vollautomatische Screenshots | 5-QA | [x] | [ios-023](archive/ios/ios-023-screenshot-test-fixtures.md) |
| [ios-026](archive/ios/ios-026-timer-responsive-layout.md) | Timer View Responsive Layout | 4-Polish | [x] | - |
| [ios-027](archive/ios/ios-027-player-responsive-layout.md) | Player View Responsive Layout | 4-Polish | [x] | - |
| [ios-028](archive/ios/ios-028-interval-gong-single-play-bug.md) | Intervall-Gong spielt nur einmal | 1-Quick Fix | [x] | - |
| [ios-029](archive/ios/ios-029-konfigurierbare-vorbereitungszeit.md) | Konfigurierbare Vorbereitungszeit | 3-Feature | [x] | - |
| [ios-030](archive/ios/ios-030-screenshot-tests-ohne-launch-args.md) | Screenshot-Tests ohne Launch-Arguments | 2-Architektur | [x] | - |
| [ios-031](archive/ios/ios-031-domain-filemanager-abstraction.md) | Domain FileManager-Abstraktion | 2-Architektur | [x] | [shared-024](archive/shared/shared-024-clean-architecture-review.md) |
| [ios-032](archive/ios/ios-032-timer-settings-repository.md) | Timer Settings Repository | 2-Architektur | [x] | [shared-024](archive/shared/shared-024-clean-architecture-review.md) |
| [ios-033](archive/ios/ios-033-settingsview-dependency-injection.md) | SettingsView Dependency Injection | 2-Architektur | [x] | [shared-024](archive/shared/shared-024-clean-architecture-review.md) |
| [ios-034](archive/ios/ios-034-picker-label-theme-color.md) | Fehlende Theme-Farben Settings/Tooltip | 4-Polish | [x] | - |
| [ios-035](archive/ios/ios-035-card-visual-separation.md) | Meditations-Cards visuell abheben | 4-Polish | [x] | - |
| [ios-036](archive/ios/ios-036-toggle-slider-theme-visibility.md) | Toggle/Slider Controls Theme-Sichtbarkeit | 4-Polish | [x] | - |
| [ios-037](archive/ios/ios-037-slow-test-time-injection.md) | Langsame Tests Time-Injection | 5-QA | [x] | - |
| [ios-038](archive/ios/ios-038-tabbar-active-tab-visibility.md) | Tab-Bar aktiver Tab schlecht erkennbar (iOS 18) | 4-Polish | [x] | - |
| [ios-039](archive/ios/ios-039-legacy-settings-store-aufraeumen.md) | Legacy Timer-Settings-Store aufraeumen | 2-Architektur | [x] | - |
| [ios-040](archive/ios/ios-040-audio-service-single-instance.md) | AudioService als einzelne geteilte Instanz | 2-Architektur | [x] | - |
| [ios-041](archive/ios/ios-041-library-search.md) | Suchfunktion fuer die Bibliothek | 3-Feature | [x] | - |
| [ios-042](archive/ios/ios-042-share-import-immer-meditation.md) | Share-Import immer als Meditation | 4-Polish | [x] | - |
| [ios-043](archive/ios/ios-043-import-prefill-service.md) | Prefill-Service fuer Meditation-Import | 3-Feature | [x] | [ios-042](archive/ios/ios-042-share-import-immer-meditation.md) |
| [ios-044](archive/ios/ios-044-import-prefill-edit-sheet-ui.md) | Edit-Sheet Prefill-UI | 3-Feature | [x] | [ios-043](archive/ios/ios-043-import-prefill-service.md) |
| [ios-045](archive/ios/ios-045-idle-ring-thin.md) | Idle-Ring in Running-Sprache (duenn) | 4-Polish | [x] | - |
| [ios-046](archive/ios/ios-046-running-timer-sanduhr-vessel.md) | Running-Timer-Display "Sanduhr-Vessel" | 4-Polish | [x] | - |
| [ios-047](archive/ios/ios-047-screenshot-running-timer-mondphase.md) | Running-Timer-Screenshot mit sichtbarer Mondphase | 4-Polish | [x] | - |
| [ios-048](archive/ios/ios-048-typografie-newsreader-geist.md) | Typografie Newsreader + Geist nachziehen | 4-Polish | [x] | - |
| [ios-051](archive/ios/ios-051-library-header-suchfeld-sichtbar.md) | Library-Header — Suchfeld immer sichtbar, Titel raus | 4-Polish | [x] | [ios-041](archive/ios/ios-041-library-search.md) |
| [ios-052](archive/ios/ios-052-library-bottom-fade.md) | Bibliothek — letzte Zeile verschwindet im unteren Verlauf | 4-Polish | [x] | [shared-094](archive/shared/shared-094-theme-refinement-kerzenschein.md) |
| [ios-054](archive/ios/ios-054-waveform-generierung-nur-einmal.md) | Waveform einer Meditation nur einmal gleichzeitig berechnen | 2-Architektur | [x] | [ios-055](archive/ios/ios-055-dienste-nur-im-app-einstieg-erzeugen.md) |
| [ios-055](archive/ios/ios-055-dienste-nur-im-app-einstieg-erzeugen.md) | Dienste nur im App-Einstieg erzeugen (Composition Root) | 2-Architektur | [x] | - |
| [ios-059](archive/ios/ios-059-share-extension-im-app-stil.md) | Teilen-Bestaetigung im Still-Moment-Stil statt System-Alert | 4-Polish | [x] | - |
| [ios-060](archive/ios/ios-060-import-blatt-oeffnet-nicht-ausserhalb-bibliothek.md) | Import: Bearbeiten-Blatt öffnet nicht, wenn die App in einem anderen Tab steht | 1-Quick Fix | [x] | - |

### Android

| Nr | Ticket | Phase | Status | Abhaengigkeit |
|----|--------|-------|--------|---------------|
| [android-001](archive/android/android-001-affirmations-i18n.md) | Affirmationen lokalisieren | 1-Quick Fix | [x] | - |
| [android-002](archive/android/android-002-audio-session-coordinator.md) | Audio Session Coordinator | 2-Architektur | [x] | - |
| [android-003](archive/android/android-003-timer-repository-impl.md) | TimerRepository Impl | 2-Architektur | [x] | - |
| [android-003-2](archive/android/android-003-2-timer-viewmodel-repository.md) | TimerVM Repository Integration | 2-Architektur | [x] | [android-003](archive/android/android-003-timer-repository-impl.md) |
| [android-004](archive/android/android-004-guided-meditation-models.md) | GuidedMeditation Models | 3-Feature | [x] | - |
| [android-005](archive/android/android-005-guided-meditation-repository.md) | GuidedMeditation Repository | 3-Feature | [x] | [android-004](archive/android/android-004-guided-meditation-models.md) |
| [android-006](archive/android/android-006-guided-meditation-viewmodel.md) | GuidedMeditation ViewModel | 3-Feature | [x] | [android-005](archive/android/android-005-guided-meditation-repository.md) |
| [android-007](archive/android/android-007-library-screen-ui.md) | Library Screen UI | 3-Feature | [x] | [android-006](archive/android/android-006-guided-meditation-viewmodel.md) |
| [android-008](archive/android/android-008-player-screen-ui.md) | Audio Player Screen UI | 3-Feature | [x] | [android-006](archive/android/android-006-guided-meditation-viewmodel.md) |
| [android-009](archive/android/android-009-tabview-navigation.md) | TabView Navigation | 3-Feature | [x] | [android-007](archive/android/android-007-library-screen-ui.md), [android-008](archive/android/android-008-player-screen-ui.md) |
| [android-010](archive/android/android-010-mediasession-lockscreen.md) | MediaSession Lock Screen | 4-Polish | [x] | [android-008](archive/android/android-008-player-screen-ui.md) |
| [android-011](archive/android/android-011-accessibility-audit.md) | Accessibility Audit | 5-QA | [x] | [android-009](archive/android/android-009-tabview-navigation.md) |
| [android-012](archive/android/android-012-ui-tests.md) | UI Tests (Component-Tests) | 5-QA | [x] | [android-009](archive/android/android-009-tabview-navigation.md) |
| [android-014](archive/android/android-014-setdatasource-fix.md) | setDataSource Failed Fix | 1-Quick Fix | [x] | [android-008](archive/android/android-008-player-screen-ui.md) |
| [android-015](archive/android/android-015-player-remove-progress-ring.md) | Player Progress-Ring entfernen | 4-Polish | [x] | [android-008](archive/android/android-008-player-screen-ui.md) |
| [android-016](archive/android/android-016-storage-documentation.md) | Storage-Unterschiede Dokumentation | 5-QA | [x] | [android-014](archive/android/android-014-setdatasource-fix.md) |
| [android-017](archive/android/android-017-ui-test-interactions.md) | UI Test Interaktions-Verifikation | 5-QA | [-] | [android-012](archive/android/android-012-ui-tests.md) |
| [android-018](archive/android/android-018-player-remove-nowplaying.md) | Player "Now Playing" + Minus entfernen | 4-Polish | [x] | - |
| [android-019](archive/android/android-019-player-loading-indicator.md) | Player Loading-Indikator | 4-Polish | [x] | - |
| [android-020](archive/android/android-020-player-skip-15s.md) | Player Skip 10s vereinheitlichen | 4-Polish | [x] | - |
| [android-021](archive/android/android-021-player-effective-name-bug.md) | Player effectiveName/Teacher Bug | 1-Quick Fix | [x] | - |
| [android-023](archive/android/android-023-section-header-simplify.md) | Section Header vereinfachen | 4-Polish | [x] | - |
| [android-024](archive/android/android-024-list-item-remove-play-icon.md) | List Item Play-Icon entfernen | 4-Polish | [x] | - |
| [android-025](archive/android/android-025-timer-accessibility-improvements.md) | Timer Accessibility Verbesserungen | 4-Polish | [x] | - |
| [android-026](archive/android/android-026-timer-preview-completeness.md) | Timer Preview Vollstaendigkeit | 5-QA | [x] | - |
| [android-027](archive/android/android-027-timer-viewmodel-test-coverage.md) | Timer ViewModel Test-Coverage | 5-QA | [-] | - |
| [android-028](archive/android/android-028-edit-sheet-reset-button.md) | Edit Sheet Reset-Button | 4-Polish | [x] | - |
| [android-029](archive/android/android-029-edit-sheet-autocomplete.md) | Edit Sheet Autocomplete Teacher | 4-Polish | [x] | - |
| [android-031](archive/android/android-031-edit-sheet-file-info.md) | Edit Sheet File-Info Section | 4-Polish | [x] | - |
| [android-033](archive/android/android-033-edit-sheet-heading-semantics.md) | Edit Sheet heading() Titel | 4-Polish | [x] | - |
| [android-034](archive/android/android-034-edit-sheet-previews.md) | Edit Sheet Previews | 5-QA | [x] | - |
| [android-035](archive/android/android-035-edit-sheet-tests.md) | Edit Sheet State Extraktion + Tests | 5-QA | [x] | - |
| [android-036](archive/android/android-036-timer-reducer-architecture.md) | Timer Reducer Architecture | 2-Architektur | [x] | - |
| [android-037](archive/android/android-037-unify-app-icon.md) | App-Icon an iOS angleichen | 4-Polish | [x] | - |
| [android-038](archive/android/android-038-hands-heart-image.md) | Haende-Herz-Bild statt Emoji | 4-Polish | [x] | - |
| [android-039](archive/android/android-039-library-viewmodel-tests.md) | Library ViewModel Tests | 5-QA | [x] | - |
| [android-040](archive/android/android-040-timer-completion-bug.md) | Timer Completion Bug | 1-Quick Fix | [x] | - |
| [android-041](archive/android/android-041-remove-notification-permission.md) | Notification Permission entfernen | 4-Polish | [x] | - |
| [android-042](archive/android/android-042-automated-screenshots.md) | Vollautomatische Screenshots | 5-QA | [x] | - |
| [android-043](archive/android/android-043-settings-sheet-responsive.md) | SettingsSheet Scroll + Responsive | 4-Polish | [x] | - |
| [android-044](archive/android/android-044-timer-screen-responsive.md) | TimerScreen Responsive Layout | 4-Polish | [x] | - |
| [android-045](archive/android/android-045-player-screen-responsive.md) | PlayerScreen Responsive Layout | 4-Polish | [x] | - |
| [android-046](archive/android/android-046-gradient-ios-angleichen.md) | Gradient an iOS angleichen | 4-Polish | [x] | - |
| [android-047](archive/android/android-047-audio-services-testability.md) | Audio-Services Testbarkeit | 2-Architektur | [x] | - |
| [android-048](archive/android/android-048-detekt-baseline-issues.md) | detekt Baseline Issues beheben | 5-QA | [x] | - |
| [android-049](archive/android/android-049-ci-ktlint-detekt.md) | CI um ktlint/detekt erweitern | 5-QA | [x] | [android-048](archive/android/android-048-detekt-baseline-issues.md) |
| [android-050](archive/android/android-050-detekt-baseline-cleanup.md) | detekt Baseline systematisch abbauen | 5-QA | [x] | [android-049](archive/android/android-049-ci-ktlint-detekt.md) |
| [android-051](archive/android/android-051-detekt-compose-compliance.md) | detekt-compose Rules Compliance | 5-QA | [x] | [android-050](archive/android/android-050-detekt-baseline-cleanup.md) |
| [android-052](archive/android/android-052-pure-content-pattern.md) | Pure Content Pattern Screenshot-Tests | 2-Architektur | [-] | - |
| [android-053](archive/android/android-053-wheelpicker-api-improvements.md) | WheelPicker API-Verbesserungen | 2-Architektur | [x] | - |
| [android-054](archive/android/android-054-timer-repository-interface.md) | TimerRepository Interface erweitern | 2-Architektur | [x] | - |
| [android-055](archive/android/android-055-progress-update-interval.md) | Progress-Update-Interval optimieren | 4-Polish | [x] | - |
| [android-056](archive/android/android-056-audio-focus-management.md) | AudioFocus Management implementieren | 2-Architektur | [x] | - |
| [android-057](archive/android/android-057-konfigurierbare-vorbereitungszeit.md) | Konfigurierbare Vorbereitungszeit | 3-Feature | [x] | - |
| [android-058](archive/android/android-058-settings-sofort-speichern.md) | Settings sofort speichern | 4-Polish | [x] | - |
| [android-059](archive/android/android-059-settings-card-layout.md) | SettingsSheet Card-Layout | 4-Polish | [x] | - |
| [android-060](archive/android/android-060-dropdown-styling.md) | Dropdown-Styling an iOS angleichen | 4-Polish | [x] | - |
| [android-061](archive/android/android-061-timer-settings-repository.md) | Timer Settings Repository Abstraktion | 2-Architektur | [x] | [shared-024](archive/shared/shared-024-clean-architecture-review.md) |
| [android-062](archive/android/android-062-timer-service-abstractions.md) | Timer Service Abstraktionen | 2-Architektur | [x] | [shared-024](archive/shared/shared-024-clean-architecture-review.md) |
| [android-063](archive/android/android-063-semantic-colors-in-views.md) | Semantische Farben in Views konsumieren | 4-Polish | [x] | - |
| [android-064](archive/android/android-064-test-output-summary.md) | Test-Output strukturierte Zusammenfassung | 5-QA | [x] | - |
| [android-065](archive/android/android-065-dauer-aus-praxis-editor-entfernen.md) | Dauer-Picker aus PraxisEditor entfernen | 4-Polish | [x] | - |
| [android-066](archive/android/android-066-footer-text-entfernen.md) | Footer-Text "Du verdienst diese Pause" entfernen | 4-Polish | [x] | - |
| [android-067](archive/android/android-067-pills-emoji-icons-ersetzen.md) | Konfigurations-Pills: Emoji durch monochrome Icons | 4-Polish | [x] | - |
| [android-068](archive/android/android-068-completion-screen-back-button.md) | Abschluss-Screen: Auto-Navigation → expliziter Button | 4-Polish | [x] | - |
| [android-069](archive/android/android-069-timer-regressions-tests.md) | Timer-Regressions-Tests implementieren | 5-QA | [x] | - |
| [android-070](archive/android/android-070-sound-lokalisierung-aus-domain.md) | Sound-Lokalisierung aus Domain-Modellen auslagern | 2-Architektur | [x] | - |
| [android-071](archive/android/android-071-preparation-affirmation-fuenfte.md) | Vorbereitungs-Phase: 5. Affirmation | 4-Polish | [x] | - |
| [android-072](archive/android/android-072-background-sound-library.md) | Background Sound Library erweitern | 3-Feature | [x] | - |
| [android-073](archive/android/android-073-praxis-editor-auto-save.md) | PraxisEditor Auto-Save beim Zurücknavigieren | 4-Polish | [x] | - |
| [android-074](archive/android/android-074-settings-datastore-timer-entfernen.md) | SettingsDataStore als Timer-Quelle entfernen | 1-Quick Fix | [x] | - |
| [android-075](archive/android/android-075-url-share-hangs.md) | URL-Share haengt im Loading-Dialog | 1-Quick Fix | [x] | - |
| [android-076](archive/android/android-076-file-uri-rejected.md) | URL-Share Import scheitert (file:// abgewiesen) | 1-Quick Fix | [x] | - |
| [android-077](archive/android/android-077-url-download-filename.md) | URL-Download Cache-Prefix entfernen | 1-Quick Fix | [x] | - |
| [android-078](archive/android/android-078-edit-stale-lambda.md) | Edit-Sheet zeigt alte Metadaten (stale lambda) | 1-Quick Fix | [x] | - |
| [android-080](archive/android/android-080-waveform-generierung-beschleunigen.md) | Waveform-Generierung langer Meditationen beschleunigen (Sampling) | 4-Polish | [x] | - |
| [android-081](archive/android/android-081-target-sdk-36-android-16.md) | Target API Level 36 (Android 16) fuer Google Play — Frist 31.08.2026 | 2-Architektur | [x] | - |
| [android-084](archive/android/android-084-timer-idle-kleine-bildschirme.md) | Timer-Startbildschirm auf kleinen Bildschirmen abgeschnitten | 4-Polish | [x] | - |
| [android-085](archive/android/android-085-vorbereitungszeit-titel-einstellungen.md) | Vorbereitungszeit in den Einstellungen mit Titel und Untertitel wie auf iOS | 4-Polish | [x] | - |
| [android-089](archive/android/android-089-dependabot-android-actions.md) | Automatische Dependency-Updates für Android und GitHub Actions (Dependabot) | 5-QA | [x] | - |

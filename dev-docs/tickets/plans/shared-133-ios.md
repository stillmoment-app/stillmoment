# Implementierungsplan: shared-133 (iOS)

Ticket: shared-133
Erstellt: 2026-10-09

## Annahmen

- Schritt-Titel der Podcast-Anleitung wie im Design-Entwurf: "Folge suchen" / "Folge teilen" / "In der App fertigstellen" (EN: "Find the episode" / "Share the episode" / "Finish in the app").
- Symbol des Kastens: `antenna.radiowaves.left.and.right` (iOS 13+, Target 16.0 ok). Ein SF Symbol für das Apple-Podcasts-Logo gibt es nicht, Marken-Logos sind ohnehin tabu. Vor dem Bauen in der SF-Symbols-App gegen `dot.radiowaves.left.and.right` abwägen; maßgeblich ist, welches näher an den Podcast-Wellen im Entwurf liegt.
- Schritt-Symbole: `magnifyingglass`, `square.and.arrow.up`, `checkmark.circle` (wie im Entwurf).
- Englische Texte: Vorschlag unten, im Ton der bestehenden englischen Anleitungen. Wird beim Plan-Review bestätigt.
- Der Hinweis "nur einzelne Folgen" ist eine ruhige Zeile mit `info.circle` und Caption-Text unter den Schritten; VoiceOver liest ihn nach Schritt 3.

## Betroffene Codestellen

Pfade relativ zu `ios/`.

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `StillMoment/Presentation/Views/GuidedMeditations/ContentGuideSheet.swift` | Presentation | Erweitern | Dritter `NavigationLink` zu `HowToImportPodcastsView` mit `ImportBannerCard`, ID `library.guideSheet.banner.podcasts` |
| `StillMoment/Presentation/Views/GuidedMeditations/HowToImportPodcastsView.swift` | Presentation | Neu | Aufbau wie `HowToImportBrowserView` (Header, Intro, 3 StepCards, Connector), zusätzlich Hinweis-Zeile. IDs `library.guideSheet.howto.podcasts` / `.title`. Preview "Podcasts Howto" (`@available(iOS 17.0, *)`, wie die anderen) |
| `StillMoment/Presentation/Views/GuidedMeditations/HowToImportBrowserView.swift` | Presentation | Unverändert | Nur Texte ändern sich (Keys bleiben) |
| `StillMoment/Presentation/Views/GuidedMeditations/HowToImportFilesView.swift` | Presentation | Unverändert | dto. |
| `StillMoment/Presentation/Views/GuidedMeditations/HowToImportStepCard.swift` | Presentation | Unverändert | Wird wiederverwendet; "Schritt N von 3" passt |
| `StillMoment/Resources/{de,en}.lproj/Localizable.strings` | Resources | Ändern + Neu | siehe Texte |
| `StillMomentUITests/LibraryFlowUITests.swift` | UI-Test | Erweitern | Existenztest um Podcasts-Kasten; neuer Test Kasten → Anleitung → Zurück |
| `StillMomentUITests/ScreenshotTests.swift` (`testScreenshot13_importGuide`) | Screenshot | Prüfen | Sind alle drei Kästen im Bild? Ggf. auf `…banner.podcasts` warten. Danach neu aufnehmen |

Kein Refactoring der drei Anleitungs-Views zu einem gemeinsamen Gerüst: Die dritte Kopie ist überschaubar (~100 Zeilen) und das Kriterium braucht es nicht. Follow-up-Idee: gemeinsames `HowToImportGuideView` mit optionalem Hinweis.

## Texte

Prefix `guided_meditations.guide.`

| Key | DE | EN |
|-----|----|----|
| `intro` (ändern) | Gute Meditationen gibt es frei verfügbar auf Webseiten und in Podcasts. Ein paar Empfehlungen findest du unten. | Good meditations are freely available on websites and in podcasts. You'll find a few recommendations below. |
| `banner.podcasts.title` | So importierst du aus Apple Podcasts | How to import from Apple Podcasts |
| `banner.podcasts.subtitle` | Folge → Teilen → Still Moment. | Episode → Share → Still Moment. |
| `howto.podcasts.title` | So importierst du aus Apple Podcasts | How to import from Apple Podcasts |
| `howto.podcasts.intro` | Viele Lehrer:innen veröffentlichen ihre Meditationen als Podcast. So übernimmst du eine Folge in deine Bibliothek. | Many teachers publish their meditations as a podcast. Here's how to add an episode to your library. |
| `howto.podcasts.step1.title` / `.body` | Folge suchen / Öffne die App „Podcasts“ und suche die Folge, die du hören möchtest. | Find the episode / Open the Podcasts app and find the episode you'd like to hear. |
| `howto.podcasts.step2.title` / `.body` | Folge teilen / Öffne die Folge und tippe auf das Teilen-Symbol. Wähle Still Moment und tippe in der kurzen Bestätigung auf „Fertig“. | Share the episode / Open the episode and tap the share icon. Pick Still Moment and tap “Done” in the short confirmation. |
| `howto.podcasts.step3.title` / `.body` | In der App fertigstellen / Öffne Still Moment. Die Folge wird geladen — passe die Angaben an, wenn du möchtest. | Finish in the app / Open Still Moment. The episode loads — adjust the details if you like. |
| `howto.podcasts.note` | Du kannst nur einzelne Folgen übernehmen, keine ganzen Podcasts. | You can only add single episodes, not whole podcasts. |
| `howto.browser.step2.body` (ändern) | Wähle Still Moment aus den vorgeschlagenen Apps und tippe in der kurzen Bestätigung auf „Fertig“. | Pick Still Moment from the suggested apps and tap “Done” in the short confirmation. |
| `howto.browser.step3.body` (ändern) | Öffne Still Moment. Der Import beginnt automatisch — passe die Angaben an, wenn du möchtest. | Open Still Moment. The import starts automatically — adjust the details if you like. |
| `howto.files.step3.body` (ändern) | Der Import beginnt automatisch — passe die Angaben an, wenn du möchtest. | The import starts automatically — adjust the details if you like. |

"Fertig"/"Done" entspricht dem Button der Share-Extension (`share.button.done`), "Fast geschafft"/"Almost there" ist deren Titel.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| SF Symbol `antenna.radiowaves.left.and.right` | iOS 13 | SF Symbols | Alternative `dot.radiowaves.left.and.right` (iOS 13) |
| SF Symbol `info.circle`, `magnifyingglass` | iOS 13 | SF Symbols | — |

Keine neuen Framework-APIs.

## Fachliche Szenarien

### AK-1: Dritter Kasten
- Gegeben: Bibliothek, "Wo finde ich Meditationen?" offen
  Dann: drei Kästen in der Reihenfolge Browser, Dateien, Apple Podcasts; darunter die Quellenliste
- Gegeben: VoiceOver an
  Wenn: Fokus auf dem Podcasts-Kasten
  Dann: ein Button "So importierst du aus Apple Podcasts, Folge → Teilen → Still Moment."

### AK-2/3/4: Anleitung
- Wenn: Podcasts-Kasten antippen
  Dann: Anleitung mit Eyebrow, Titel, Einleitung, genau drei Schritten mit den Texten oben; Zurück führt zur Übersicht

### AK-5: Hinweis
- Dann: unter Schritt 3 steht "Du kannst nur einzelne Folgen übernehmen, keine ganzen Podcasts."; VoiceOver liest ihn nach Schritt 3

### AK-6: Einleitung
- Dann: Übersicht zeigt die neue Einleitung (Webseiten und Podcasts)

### AK-Korrektur Browser/Dateien
- Browser-Anleitung Schritt 2 nennt "Fertig", kein "OK"; Schritt 3 und Dateien-Schritt 3 nennen keine Felder mehr

### AK-Erhalt
- Browser- und Dateien-Kasten öffnen weiterhin ihre Anleitungen; Quellenliste unverändert

## Reihenfolge der Akzeptanzkriterien

1. **Texte** (Localizable DE/EN, inkl. Korrekturen) — Grundlage für alles
2. **HowToImportPodcastsView** inkl. Hinweis
3. **Dritter Kasten** im ContentGuideSheet
4. **UI-Tests** (Existenz, Navigation hin und zurück) — rot zuerst
5. **Screenshot 13** prüfen und neu aufnehmen (de + en), danach `process-screenshots.sh` / Store-Kuration
6. Manueller Test am Gerät (App Podcasts → Teilen → Fertig → Still Moment)

## Offene Fragen

- [ ] Englische Texte so in Ordnung?
- [ ] Symbol `antenna.radiowaves.left.and.right` oder `dot.radiowaves.left.and.right`?

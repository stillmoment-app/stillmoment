# Implementierungsplan: shared-133 (Android)

Ticket: shared-133
Erstellt: 2026-10-09

## Annahmen

- Schritt-Titel wie im Design-Entwurf: "Folge suchen" / "Folge teilen" / "In der App fertigstellen" (EN: "Find the episode" / "Share the episode" / "Finish in the app").
- Kasten-Symbol `Icons.Filled.Podcasts` (material-icons-extended 1.7.6 ist eingebunden; die bestehenden Kästen nutzen `Filled.Public` und `Filled.Folder`).
- Schritt-Symbole: `Icons.Filled.Search`, `Icons.Filled.Share`, `Icons.Outlined.CheckCircle` (Share und CheckCircle wie in der Browser-Anleitung).
- Englische Texte identisch mit dem iOS-Plan, wo der Ablauf gleich ist; abweichend nur Schritt 1–3 der Podcast-Anleitung und Browser-Schritte 2/3 (keine Bestätigung, Still Moment öffnet sich selbst).
- Hinweis "nur einzelne Folgen": ruhige Zeile mit `Icons.Outlined.Info` und Caption-Text unter den Schritten, TalkBack liest ihn nach Schritt 3.

## Betroffene Codestellen

Pfade relativ zu `android/app/src/`.

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `main/kotlin/com/stillmoment/presentation/ui/meditations/HowToImportGuideScreen.kt` | Presentation | Erweitern | `HowToImportGuideKind.PODCASTS`, `podcastsGuide`-Spec, `specFor` erweitern. `GuideSpec` bekommt optionales `noteRes: Int?`; Hinweis wird im bestehenden `Column` nach den Schritten gerendert (kein zweiter Wurzel-Emitter → `MultipleEmitters`) |
| `main/kotlin/com/stillmoment/presentation/ui/meditations/ContentGuideSheet.kt` | Presentation | Erweitern | Dritte `ImportBannerCard` in `ImportBannerStack` mit `Icons.Filled.Podcasts` → `PODCASTS`. Navigation im Sheet bleibt unverändert. KDoc ("two how-to banners") anpassen. Preview "How-to Podcasts" ergänzen |
| `main/kotlin/com/stillmoment/presentation/ui/meditations/ImportBannerCard.kt` | Presentation | Unverändert | Ein TalkBack-Button "Titel, Untertitel" |
| `main/kotlin/com/stillmoment/presentation/ui/meditations/HowToImportStepCard.kt` | Presentation | Unverändert | "Schritt N von 3" passt |
| `main/res/values/strings.xml`, `main/res/values-de/strings.xml` | Resources | Ändern + Neu | siehe Texte |
| `androidTest/kotlin/com/stillmoment/presentation/ui/meditations/ContentGuideSheetTest.kt` | UI-Test | Erweitern | `showsBothImportBanners_inListMode` → drei Kästen; neuer Test: Podcasts-Kasten → drei Schritte + Hinweis sichtbar → Zurück |
| `androidTest/kotlin/com/stillmoment/screenshots/ScreengrabScreenshotTests.kt` (`screenshot08_importGuide`) | Screenshot | Neu aufnehmen | Code unverändert, prüfen ob alle drei Kästen im Bild sind |

## Texte

Prefix `guided_meditations_guide_`

| Key | DE | EN |
|-----|----|----|
| `intro` (ändern) | Gute Meditationen gibt es frei verfügbar auf Webseiten und in Podcasts. Ein paar Empfehlungen findest du unten. | Good meditations are freely available on websites and in podcasts. You'll find a few recommendations below. |
| `banner_podcasts_title` | So importierst du aus Apple Podcasts | How to import from Apple Podcasts |
| `banner_podcasts_subtitle` | Folge → Teilen → Still Moment. | Episode → Share → Still Moment. |
| `howto_podcasts_title` | So importierst du aus Apple Podcasts | How to import from Apple Podcasts |
| `howto_podcasts_intro` | Viele Lehrer:innen veröffentlichen ihre Meditationen als Podcast. So übernimmst du eine Folge in deine Bibliothek. | Many teachers publish their meditations as a podcast. Here's how to add an episode to your library. |
| `howto_podcasts_step1_title` / `_body` | Folge suchen / Öffne podcasts.apple.com im Browser und suche die Folge, die du hören möchtest. | Find the episode / Open podcasts.apple.com in your browser and find the episode you'd like to hear. |
| `howto_podcasts_step2_title` / `_body` | Folge teilen / Öffne die Folge und tippe auf das Teilen-Symbol. Wähle Still Moment. | Share the episode / Open the episode and tap the share icon. Pick Still Moment. |
| `howto_podcasts_step3_title` / `_body` | In der App fertigstellen / Still Moment öffnet sich und lädt die Folge — passe die Angaben an, wenn du möchtest. | Finish in the app / Still Moment opens and loads the episode — adjust the details if you like. |
| `howto_podcasts_note` | Du kannst nur einzelne Folgen übernehmen, keine ganzen Podcasts. | You can only add single episodes, not whole podcasts. |
| `howto_browser_step2_body` (ändern) | Wähle Still Moment aus den vorgeschlagenen Apps. | Pick Still Moment from the suggested apps. |
| `howto_browser_step3_body` (ändern) | Still Moment öffnet sich und der Import beginnt — passe die Angaben an, wenn du möchtest. | Still Moment opens and the import starts — adjust the details if you like. |
| `howto_files_step3_body` (ändern) | Der Import beginnt automatisch — passe die Angaben an, wenn du möchtest. | The import starts automatically — adjust the details if you like. |

Der Ablauf ist am Emulator belegt (2026-10-09): Chrome übergibt den Folgenlink mit `?i=`, Still Moment öffnet sich direkt mit dem Bearbeiten-Blatt.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Icons.Filled.Podcasts`, `Icons.Filled.Search`, `Icons.Outlined.Info` | material-icons-extended 1.7.6 | im Projekt eingebunden | — |

Keine neuen Framework-APIs.

## Fachliche Szenarien

### AK-1: Dritter Kasten
- Gegeben: "Wo finde ich Meditationen?" offen
  Dann: drei Kästen Browser, Dateien, Apple Podcasts; darunter die Quellenliste
- Gegeben: TalkBack an
  Dann: Podcasts-Kasten wird als ein Button "So importierst du aus Apple Podcasts, Folge → Teilen → Still Moment." vorgelesen

### AK-2/3/4: Anleitung
- Wenn: Podcasts-Kasten antippen
  Dann: Anleitung mit Titel, Einleitung, genau drei Schritten mit den Texten oben; Zurück (Pfeil und System-Zurück) führt zur Übersicht

### AK-5: Hinweis
- Dann: unter Schritt 3 der Hinweis "Du kannst nur einzelne Folgen übernehmen, keine ganzen Podcasts."
- Browser- und Dateien-Anleitung zeigen keinen Hinweis (`noteRes = null`)

### AK-6: Einleitung
- Dann: neue Einleitung sichtbar

### AK-Korrektur Browser/Dateien
- Browser-Schritt 2 ohne "OK"/Bestätigung; Schritt 3 beginnt mit "Still Moment öffnet sich"; Dateien-Schritt 3 ohne Felder

### AK-Erhalt
- Browser- und Dateien-Kasten öffnen weiterhin ihre Anleitungen (bestehende Tests bleiben grün); Quellenliste unverändert

## Reihenfolge der Akzeptanzkriterien

1. **ContentGuideSheetTest** erweitern (drei Kästen, Podcasts-Anleitung + Hinweis) — rot
2. **Texte** (strings.xml DE/EN inkl. Korrekturen)
3. **HowToImportGuideScreen**: `PODCASTS`, Spec, `noteRes` + Hinweis-Zeile
4. **ContentGuideSheet**: dritter Kasten, KDoc, Preview — grün
5. **Screenshot 08** neu aufnehmen (de + en), danach Store-Kuration (`05_ImportGuide`) und Website-Bilder
6. Manueller Test am Gerät (podcasts.apple.com → Teilen → Still Moment)

## Offene Fragen

- [ ] Englische Texte so in Ordnung? (gleich wie iOS-Plan)

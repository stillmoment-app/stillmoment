# View-Namen Referenz

Einheitliche Begriffe für Tickets und Dokumentation: ein Ticket-Begriff → der iOS-Name → der Android-Name. Besonders wichtig, weil die Plattformen **nicht immer gleich benennen** (siehe Divergenzen unten).

> Dateipfade hier bewusst **nicht** gelistet — sie veralten sofort. Aktuelle Pfade per
> `find ios/StillMoment/Presentation -name "<Name>.swift"` bzw.
> `find android/app/src/main/kotlin -name "<Name>.kt"`.

## Timer-Bereich

| Ticket-Begriff | iOS | Android |
|----------------|-----|---------|
| **Timer** | `TimerView` | `TimerScreen` |
| **Timer-Focus** (laufende Meditation) | — *(Teil von `TimerView`, Komponente `RunningTimerDisplay`)* | `TimerFocusScreen` |
| **Settings** (Timer-Einstellungen) | `SettingsView` | `SettingsSheet` |
| **Praxis-Editor** | `SettingDetailRoot` *(via `SettingsView`)* | `PraxisEditorScreen` |
| **Vorbereitungszeit** | `PreparationTimeSelectionView` | `PreparationTimeSelectionScreen` |
| **Hintergrund-Sound** | `BackgroundSoundSelectionView` | `SelectBackgroundSoundScreen` |
| **Gong-Auswahl** | `GongSelectionView` | `SelectGongScreen` |
| **Intervall-Gongs** | `IntervalGongsEditorView` | `IntervalGongsEditorScreen` |

> **Hinweis:** Der Minute Picker ist Teil von **Timer** (kein eigener View).
> Die iOS-Detail-Screens (Vorbereitung/Hintergrund/Gong/Intervall) werden über das
> `SettingDestination`-Enum + `SettingDetailRoot` navigiert; beide Plattformen teilen das
> `PraxisEditorViewModel`.

## Bibliothek / Guided Meditations

| Ticket-Begriff | iOS | Android |
|----------------|-----|---------|
| **MeditationsList** | `GuidedMeditationsListView` | `GuidedMeditationsListScreen` |
| **MeditationPlayer** | `GuidedMeditationPlayerView` | `GuidedMeditationPlayerScreen` |
| **MeditationEdit** | `GuidedMeditationEditSheet` | `MeditationEditSheet` |
| **TrimEditor** | `TrimEditorSheet` | — *(noch nicht implementiert, Folge-Ticket)* |
| **ContentGuide** | `ContentGuideSheet` | `ContentGuideSheet` |
| **Import-Anleitung** | `HowToImportFilesView` / `HowToImportBrowserView` | `HowToImportGuideScreen` |

## App-Einstellungen

| Ticket-Begriff | iOS | Android |
|----------------|-----|---------|
| **AppSettings** (globale Einstellungen) | `AppSettingsView` | `AppSettingsScreen` |
| **SoundAttributions** | `SoundAttributionsView` | `SoundAttributionsScreen` |

> **Nicht verwechseln:** **Settings** = Timer-Einstellungen (pro Praxis), **AppSettings** = globale App-Einstellungen (Theme, Sprache …).

## Naming-Konventionen

| Platform | Suffix | Beispiel |
|----------|--------|----------|
| iOS | `*View` / `*Sheet` | `TimerView`, `GuidedMeditationEditSheet` |
| Android | `*Screen` / `*Sheet` | `TimerScreen`, `SettingsSheet` |

## Cross-Platform-Divergenzen (Fehlerquellen)

Diese Stellen weichen bewusst voneinander ab — beim Ticket-Schreiben beachten:

- **Wortstellung dreht sich um:** iOS `*Selection*` ↔ Android `Select*`
  (`GongSelectionView` ↔ `SelectGongScreen`, `BackgroundSoundSelectionView` ↔ `SelectBackgroundSoundScreen`).
- **Laufender Timer:** iOS hat **keinen** eigenen Screen — der Running-State lebt in `TimerView`
  (`RunningTimerDisplay`). Android trennt ihn als `TimerFocusScreen` ab.
- **„Guided"-Präfix:** iOS hält es bei `Edit` durch (`GuidedMeditationEditSheet`),
  Android lässt es dort weg (`MeditationEditSheet`) — bei List/Player aber beide mit Präfix.

---

**Last Updated**: 2026-06-14

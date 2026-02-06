# View-Namen Referenz

Einheitliche Begriffe für Tickets und Dokumentation.

## Timer-Bereich

| Ticket-Begriff | iOS | Android |
|----------------|-----|---------|
| **Timer** | `TimerView` | `TimerScreen` |
| **Settings** | `SettingsView` | `SettingsSheet` |

> **Hinweis:** Der Minute Picker ist Teil von **Timer** (kein eigener View).

## Guided Meditations-Bereich

| Ticket-Begriff | iOS | Android |
|----------------|-----|---------|
| **MeditationsList** | `GuidedMeditationsListView` | `GuidedMeditationsListScreen` |
| **MeditationPlayer** | `GuidedMeditationPlayerView` | `GuidedMeditationPlayerScreen` |
| **MeditationEdit** | `GuidedMeditationEditSheet` | `MeditationEditSheet` |

## Naming-Konventionen

| Platform | Suffix | Beispiel |
|----------|--------|----------|
| iOS | `*View` | `TimerView`, `SettingsView` |
| Android | `*Screen` / `*Sheet` | `TimerScreen`, `SettingsSheet` |

## Dateipfade

### iOS
```
ios/StillMoment/Presentation/Views/
├── Timer/
│   ├── TimerView.swift
│   └── SettingsView.swift
└── GuidedMeditations/
    ├── GuidedMeditationsListView.swift
    ├── GuidedMeditationPlayerView.swift
    └── GuidedMeditationEditSheet.swift
```

### Android
```
android/app/src/main/kotlin/com/stillmoment/presentation/ui/
├── timer/
│   ├── TimerScreen.kt
│   ├── TimerFocusScreen.kt
│   └── SettingsSheet.kt
└── meditations/
    ├── GuidedMeditationsListScreen.kt
    ├── GuidedMeditationPlayerScreen.kt
    └── MeditationEditSheet.kt
```

---

**Last Updated**: 2026-02-06

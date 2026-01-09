# Cross-Platform Konsistenz - Checklist

Vergleicht Lokalisierungs-Keys zwischen iOS und Android.

## Namenskonvention

| Plattform | Format | Beispiel |
|-----------|--------|----------|
| iOS | dot.notation | `welcome.title` |
| Android | underscore_case | `welcome_title` |

## Normalisierung fuer Vergleich

```
iOS Key              →  Normalisiert  ←  Android Key
welcome.title        →  welcome_title ←  welcome_title
button.start         →  button_start  ←  button_start
settings.audio.title →  settings_audio_title ← settings_audio_title
```

## Vergleichs-Algorithmus

1. **iOS Keys extrahieren:**
   ```bash
   grep -o '"[^"]*" =' ios/.../Localizable.strings | sed 's/"//g' | sed 's/ =//'
   ```

2. **Android Keys extrahieren:**
   ```bash
   grep -o 'name="[^"]*"' android/.../strings.xml | sed 's/name="//g' | sed 's/"//g'
   ```

3. **iOS Keys normalisieren:**
   ```
   Ersetze . durch _
   ```

4. **Vergleichen:**
   - Keys nur in iOS vorhanden
   - Keys nur in Android vorhanden
   - Keys in beiden (Match)

## Erwartete Plattform-spezifische Keys

### Nur iOS (kein Android-Aequivalent noetig)

| Key-Pattern | Grund |
|-------------|-------|
| `tab.*` | iOS TabView spezifisch |
| `*.hint` | iOS Accessibility Hints (Android nutzt andere Patterns) |

### Nur Android (kein iOS-Aequivalent noetig)

| Key-Pattern | Grund |
|-------------|-------|
| `app_name` | Android Manifest Requirement |
| `notification_channel_*` | Android Notification Channels |

## Semantische Gruppen

Beide Plattformen sollten Keys in diesen Gruppen haben:

| Gruppe | iOS Prefix | Android Prefix |
|--------|------------|----------------|
| Welcome | `welcome.*` | `welcome_*` |
| Buttons | `button.*` | `button_*` |
| Settings | `settings.*` | `settings_*` |
| Timer | `timer.*` | `timer_*` |
| Accessibility | `accessibility.*` | `accessibility_*` |
| Affirmations | `affirmation.*` | `affirmation_*` |
| Common | `common.*` | `common_*` |
| Guided Meditations | `guided_meditations.*` | `guided_meditations_*` / `library_*` |

## Inhaltliche Konsistenz

Nicht nur Keys, auch **Inhalte** vergleichen:

```
iOS (en):     "Start"
Android (en): "Start"
→ Match

iOS (de):     "Starten"
Android (de): "Beginnen"
→ Inkonsistenz! Gleiche Aktion, unterschiedliche Woerter
```

## Bewertung

| Finding | Schwere |
|---------|---------|
| Fehlendes Aequivalent fuer UI-Text | Mittel |
| Inhaltliche Inkonsistenz (gleiche Funktion, anderer Text) | Mittel |
| Fehlendes Aequivalent fuer Accessibility | Gering |
| Plattform-spezifischer Key ohne Dokumentation | Gering |

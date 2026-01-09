# Ungenutzte Keys - Checklist

Identifiziert Lokalisierungs-Keys die definiert aber nicht verwendet werden.

## iOS - Usage Patterns

Ein iOS Key gilt als **verwendet** wenn er in einem dieser Patterns vorkommt:

### Pattern 1: Text() mit Bundle
```swift
Text("KEY", bundle: .main)
Text("KEY")  // SwiftUI findet Key automatisch
```

**Grep:**
```bash
grep -r 'Text("KEY"' ios/StillMoment --include="*.swift"
```

### Pattern 2: NSLocalizedString
```swift
NSLocalizedString("KEY", comment: "")
```

**Grep:**
```bash
grep -r 'NSLocalizedString("KEY"' ios/StillMoment --include="*.swift"
```

### Pattern 3: Accessibility Modifiers
```swift
.accessibilityLabel("KEY")
.accessibilityHint("KEY")
```

**Grep:**
```bash
grep -r 'accessibilityLabel("KEY"' ios/StillMoment --include="*.swift"
grep -r 'accessibilityHint("KEY"' ios/StillMoment --include="*.swift"
```

### Pattern 4: String Format
```swift
String(format: NSLocalizedString("KEY", comment: ""), arg)
```

**Grep:**
```bash
grep -r 'NSLocalizedString("KEY"' ios/StillMoment --include="*.swift"
```

## Android - Usage Patterns

Ein Android Key gilt als **verwendet** wenn er in einem dieser Patterns vorkommt:

### Pattern 1: stringResource
```kotlin
stringResource(R.string.KEY)
```

**Grep:**
```bash
grep -r 'R\.string\.KEY' android/app/src --include="*.kt"
```

### Pattern 2: getString (in Activities/Fragments)
```kotlin
getString(R.string.KEY)
context.getString(R.string.KEY)
```

### Pattern 3: XML References
```xml
android:text="@string/KEY"
android:contentDescription="@string/KEY"
```

**Grep:**
```bash
grep -r '@string/KEY' android/app/src --include="*.xml"
```

## Ausnahmen - Keys die nicht im Code erscheinen

### Domain-Model Inline-Lokalisierung

Diese Keys sind **NICHT** in Localizable.strings/strings.xml:

**GongSound:**
```swift
struct LocalizedString {
    let en: String
    let de: String
    var localized: String { ... }
}
```

Keys wie `gong.tibetan`, `gong.singing_bowl` existieren als inline Structs.

**BackgroundSound:**
Gleiche Struktur fuer `sound.forest`, `sound.whitenoise`, etc.

### Dynamisch generierte Keys

```swift
// Affirmations werden als Array geladen
NSLocalizedString("affirmation.running.\(index)", comment: "")
```

Diese Keys (`affirmation.running.1` bis `affirmation.running.5`) sind verwendet,
auch wenn der exakte String nicht im grep erscheint.

## Pruef-Algorithmus

```
1. Alle Keys aus Localizable.strings extrahieren
2. Fuer jeden Key:
   a. Suche in allen Swift-Dateien (ohne Tests)
   b. Wenn kein Match: Als "moeglicherweise ungenutzt" markieren
3. Manuelle Pruefung der Kandidaten:
   - Dynamische Keys? (z.B. affirmation.running.*)
   - Domain-Model Keys?
   - Tatsaechlich ungenutzt?
```

## Bewertung

| Finding | Schwere |
|---------|---------|
| Definitiv ungenutzter Key (kein Match, keine Ausnahme) | Gering |
| Verdaechtiger Key (braucht manuelle Pruefung) | Info |
| Dynamischer Key ohne Basis-Verwendung | Mittel |

## Empfehlung bei ungenutzten Keys

Ungenutzte Keys sollten entfernt werden um:
- Wartbarkeit zu verbessern
- Uebersetzungsaufwand zu reduzieren
- Verwirrung zu vermeiden

**Vor dem Loeschen:**
1. Git-Historie pruefen (war Key mal verwendet?)
2. Geplante Features pruefen (wird Key bald gebraucht?)
3. Beide Sprachen (en/de) entfernen

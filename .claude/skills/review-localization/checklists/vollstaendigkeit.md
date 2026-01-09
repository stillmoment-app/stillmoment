# Vollstaendigkeit - Checklist

Prueft ob alle UI-Texte korrekt internationalisiert sind.

## iOS Pruefung

### Automatisierte Pruefung

```bash
cd ios && make check-localization
```

Dieses Script sucht nach hardcoded Strings in:
- `Text("Hardcoded")`
- `Button("Hardcoded")`
- `.accessibilityLabel("Hardcoded")`
- `.accessibilityHint("Hardcoded")`
- `.alert("Hardcoded", isPresented:...)`
- `.navigationTitle("Hardcoded")`
- `Picker("Hardcoded", selection:...)`

### Manuelle Pruefung

Suche nach Patterns die das Script nicht erkennt:

```
Label("Hardcoded", systemImage:
Toggle("Hardcoded", isOn:
Section("Hardcoded")
```

### Key-Parity (en/de)

```bash
cd ios && make validate-localization
```

Prueft:
- Syntax-Validierung beider Dateien
- Alle Keys existieren in beiden Sprachen
- Keine leeren Values
- Placeholder-Konsistenz (%d, %@, etc.)

## Android Pruefung

### Hardcoded Strings finden

Suche in Kotlin-Dateien nach:

```kotlin
// FALSCH - Hardcoded
Text(text = "Hardcoded")
Text("Hardcoded")
contentDescription = "Hardcoded"

// RICHTIG - Lokalisiert
Text(text = stringResource(R.string.key))
contentDescription = stringResource(R.string.key)
```

**Grep-Pattern:**
```bash
grep -rn 'Text(text = "[A-Z]' android/app/src/main/kotlin/
grep -rn 'contentDescription = "[A-Z]' android/app/src/main/kotlin/
```

### Key-Parity (en/de)

Vergleiche Keys in:
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

Beide muessen identische `name` Attribute haben.

## Erlaubte Ausnahmen

Diese Patterns sind KEINE Fehler:

### iOS
- `Text("key", bundle: .main)` - Korrekt lokalisiert
- `NSLocalizedString("key", comment: "")` - Korrekt lokalisiert
- `Text(variable)` - Dynamischer Content
- `Text("\(number)")` - Reine Zahlen
- `systemImage:` Parameter - SF Symbols

### Android
- `stringResource(R.string.key)` - Korrekt lokalisiert
- `Text(text = variable)` - Dynamischer Content
- Zahlen und Sonderzeichen

## Bewertung

| Finding | Schwere |
|---------|---------|
| Hardcoded sichtbarer Text | Kritisch |
| Hardcoded Accessibility-Label | Kritisch |
| Fehlende Uebersetzung (en/de) | Kritisch |
| Leerer Value in strings | Mittel |
| Inkonsistente Placeholders | Mittel |

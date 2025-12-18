# Ticket ios-002: iOS 16 Support

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein (~30-45 min)
**Abhaengigkeiten**: Keine
**Phase**: 3-Feature

---

## Beschreibung

Ein Benutzer moechte die App auf iOS 16.6.1 verwenden. Aktuell ist iOS 17.0 die Mindestversion.

---

## Analyse

**Test-Build mit iOS 16 Deployment Target ergab 34 Compiler-Fehler:**

| Fehlertyp | Anzahl | Loesung |
|-----------|--------|---------|
| `#Preview` Makro | 15x | `@available(iOS 17.0, *)` hinzufuegen |
| `fixedLayout` Preview-Trait | 15x | (Teil von #Preview) |
| `@Previewable` | 2x | `@available(iOS 17.0, *)` hinzufuegen |
| `onChange(of:initial:_:)` | 2x | Alte Signatur verwenden |

---

## Akzeptanzkriterien

- [ ] Deployment Target auf iOS 16.0 geaendert
- [ ] Alle `#Preview` Makros mit `@available(iOS 17.0, *)` markiert
- [ ] `onChange` Signaturen auf iOS 16 kompatible Version geaendert
- [ ] Locale API auf iOS 16 kompatibel (falls noetig)
- [ ] App kompiliert und laeuft auf iOS 16 Simulator
- [ ] Bestehende Unit Tests weiterhin gruen

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag fuer iOS 16 Support
- [ ] README.md: Minimum iOS Version aktualisieren

---

## Betroffene Dateien

### Preview-Code (`@available` hinzufuegen)

- `StillMoment/Presentation/Views/Timer/TimerView.swift` (8 Previews)
- `StillMoment/Presentation/Views/Timer/SettingsView.swift` (5 Previews)
- `StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` (4 Previews)
- `StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` (4 Previews)
- `StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` (5 Previews)
- `StillMoment/Presentation/Views/Shared/AutocompleteTextField.swift` (2 Previews + 2 @Previewable)

### App-Code (Signatur aendern)

- `StillMoment/Presentation/Views/Shared/AutocompleteTextField.swift` (Zeile 40, 44)

### Projekt

- `StillMoment.xcodeproj/project.pbxproj` (IPHONEOS_DEPLOYMENT_TARGET)

---

## Technische Details

### 1. Deployment Target aendern

In `StillMoment.xcodeproj/project.pbxproj`:
```
IPHONEOS_DEPLOYMENT_TARGET = 17.0  →  IPHONEOS_DEPLOYMENT_TARGET = 16.0
```

Oder in Xcode: Project → Target → General → Minimum Deployments → iOS 16.0

### 2. onChange-Signatur anpassen

In `AutocompleteTextField.swift`:

```swift
// Vorher (iOS 17+)
.onChange(of: self.text) { _, newValue in
    let filtered = Self.filterSuggestions(self.suggestions, for: newValue)
    self.showSuggestions = !filtered.isEmpty
}
.onChange(of: self.isFocused) { _, focused in
    if !focused {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showSuggestions = false
        }
    }
}

// Nachher (iOS 14+, deprecated in iOS 17 aber funktional)
.onChange(of: self.text) { newValue in
    let filtered = Self.filterSuggestions(self.suggestions, for: newValue)
    self.showSuggestions = !filtered.isEmpty
}
.onChange(of: self.isFocused) { focused in
    if !focused {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showSuggestions = false
        }
    }
}
```

### 3. Previews iOS 17+ markieren

Vor jedes `#Preview` und `@Previewable`:

```swift
// Vorher
#Preview("Default Settings") {
    SettingsView(settings: .constant(defaultSettings)) {}
}

// Nachher
@available(iOS 17.0, *)
#Preview("Default Settings") {
    SettingsView(settings: .constant(defaultSettings)) {}
}
```

### 4. Locale API pruefen (falls noetig)

In `BackgroundSound.swift` Zeile 39:
```swift
// iOS 17+
let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

// iOS 16 kompatibel
let languageCode = Locale.current.languageCode ?? "en"
```

---

## Testanweisungen

```bash
# Build mit iOS 16 Target
cd ios
xcodebuild build \
  -project StillMoment.xcodeproj \
  -scheme StillMoment \
  -destination "generic/platform=iOS" \
  IPHONEOS_DEPLOYMENT_TARGET=16.0

# Unit Tests
make test-unit

# iOS 16 Simulator Test
# 1. iOS 16 Simulator in Xcode installieren
# 2. App auf iOS 16 Simulator starten
# 3. Alle Features manuell testen
```

---

## Auswirkungen

- Deprecation-Warnings fuer `onChange` in Xcode (koennen ignoriert werden)
- Previews funktionieren weiterhin in Xcode (nur auf macOS, nicht iOS)
- CI/CD Pipeline muss ggf. angepasst werden (iOS 16 Simulator)

---

## Entscheidung

- [ ] iOS 16 Support implementieren
- [ ] Bei iOS 17+ bleiben (90%+ der Geraete unterstuetzen iOS 17)

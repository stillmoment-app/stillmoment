---
name: review-localization
description: Prueft App-Texte auf Internationalisierung, Cross-Platform-Konsistenz, ungenutzte Keys und Accessibility-Label-Konsistenz. Aktiviere bei "Review Texte...", "Check localization...", "Pruefe Uebersetzungen...", oder /review-localization.
---

# Localization Review

Systematische Pruefung der Lokalisierung auf beiden Plattformen (iOS + Android).

## Wann dieser Skill aktiviert wird

Dieser Skill wird automatisch geladen wenn der User fragt nach:
- "Review localization" / "Pruefe Lokalisierung"
- "Check translations" / "Pruefe Uebersetzungen"
- "Sind alle Texte internationalisiert?"
- "iOS und Android Texte vergleichen"
- "Ungenutzte Strings finden"
- `/review-localization`

## Workflow

### Schritt 1: Scope bestimmen

Frage den User nach dem Scope:
- **iOS only**: Nur iOS pruefen
- **Android only**: Nur Android pruefen
- **Both** (Standard): Beide Plattformen pruefen

### Schritt 2: Resource-Dateien lesen

**iOS:**
- `ios/StillMoment/Resources/en.lproj/Localizable.strings`
- `ios/StillMoment/Resources/de.lproj/Localizable.strings`

**Android:**
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

Alle 4 Dateien mit dem Read-Tool lesen und Keys extrahieren.

### Schritt 3: Vollstaendigkeitspruefung

Fuehre bestehende Validierungs-Scripts aus (nur fuer iOS):

```bash
cd ios && make check-localization    # Hardcoded Strings finden
cd ios && make validate-localization # Syntax + en/de Parity
```

Fuer Android manuell pruefen:
- Siehe `checklists/vollstaendigkeit.md`

### Schritt 4: Cross-Platform-Vergleich

Vergleiche iOS und Android Keys:
- Siehe `checklists/cross-platform.md`

**Normalisierung:**
- iOS: `welcome.title` → `welcome_title`
- Vergleiche normalisierte Keys

**Erwartete Differenzen dokumentieren:**
- Plattform-spezifische Keys (z.B. iOS `tab.*`, Android Navigation)
- Unterschiedliche Accessibility-Patterns

### Schritt 5: Ungenutzte Keys identifizieren

Suche nach Keys die definiert aber nicht verwendet werden:
- Siehe `checklists/unused-keys.md`

**iOS Grep-Patterns:**
```
Text("KEY"
NSLocalizedString("KEY"
.accessibilityLabel("KEY"
.accessibilityHint("KEY"
```

**Android Grep-Patterns:**
```
R.string.KEY
stringResource(R.string.KEY
```

### Schritt 6: Accessibility-Konsistenz pruefen

Pruefe ob Accessibility-Labels und sichtbare Labels konsistent sind:
- Siehe `checklists/accessibility.md`

### Schritt 7: Report generieren

Erstelle strukturierten Report nach `templates/report.md`:
- Zusammenfassung mit Status pro Pruefung
- Details zu allen Findings
- Empfehlungen zur Behebung

## Referenzen

### Lokalisierungs-Dateien

| Plattform | Sprache | Pfad |
|-----------|---------|------|
| iOS | English | `ios/StillMoment/Resources/en.lproj/Localizable.strings` |
| iOS | German | `ios/StillMoment/Resources/de.lproj/Localizable.strings` |
| Android | English | `android/app/src/main/res/values/strings.xml` |
| Android | German | `android/app/src/main/res/values-de/strings.xml` |

### Bestehende Validierungs-Scripts

| Script | Funktion |
|--------|----------|
| `ios/scripts/check-localization.sh` | Findet hardcoded Strings in SwiftUI |
| `ios/scripts/validate-localization.sh` | Validiert Syntax und en/de Parity |

### Projekt-Standards

- `CLAUDE.md` - Internationalization Guidelines
- `dev-docs/ARCHITECTURE.md` - Architektur-Uebersicht

## Key-Namenskonventionen

| Plattform | Format | Beispiel |
|-----------|--------|----------|
| iOS | dot-notation | `welcome.title`, `button.start` |
| Android | underscore | `welcome_title`, `button_start` |

## Bekannte Ausnahmen

Diese Keys sind absichtlich nur auf einer Plattform:

**Nur iOS:**
- `tab.*` - iOS Tab Bar spezifisch
- Keys mit `.hint` Suffix - iOS Accessibility Hints

**Nur Android:**
- `app_name` - Android Manifest
- Navigation-spezifische Keys

**Domain-Model LocalizedStrings (nicht in Resource Bundles):**
- `GongSound.LocalizedString` - Inline-Lokalisierung
- `BackgroundSound.LocalizedString` - Inline-Lokalisierung

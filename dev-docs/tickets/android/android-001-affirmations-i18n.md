# Ticket android-001: Affirmationen lokalisieren

**Status**: [x] DONE
**Prioritaet**: KRITISCH
**Aufwand**: Klein (~30 min)
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Beschreibung

Die Countdown- und Running-Affirmationen sind im `TimerViewModel` hardcoded, obwohl die Strings bereits in `strings.xml` und `strings-de.xml` definiert sind. Deutsche Nutzer sehen englische Affirmationen.

---

## Akzeptanzkriterien

- [x] Hardcoded Affirmationen aus `TimerViewModel` entfernt
- [x] Affirmationen werden via `context.getString(R.string.affirmation_*)` geladen
- [x] Deutsche Uebersetzungen in `strings-de.xml` vorhanden und korrekt
- [x] Unit Tests fuer Affirmation-Rotation bestehen
- [x] Manuelle Pruefung: Deutsche Systemsprache zeigt deutsche Affirmationen

### Dokumentation
- [x] CHANGELOG.md: Bug-Fix Eintrag fuer i18n-Korrektur

---

## Betroffene Dateien

### Zu aendern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`
  - Zeilen 73-86: Hardcoded Listen entfernen
  - Methoden `getCurrentCountdownAffirmation()` und `getCurrentRunningAffirmation()` anpassen

### Bereits vorhanden (nur pruefen):
- `android/app/src/main/res/values/strings.xml` (Zeilen 73-84)
- `android/app/src/main/res/values-de/strings.xml`

---

## Technische Details

### Aktueller Code (zu entfernen):
```kotlin
// TimerViewModel.kt:73-86
private val countdownAffirmations = listOf(
    "Find a comfortable position",
    "Take a deep breath",
    "Close your eyes gently",
    "Let go of all tension"
)

private val runningAffirmations = listOf(
    "Be present in this moment",
    "Breathe naturally and deeply",
    "Notice your thoughts, let them pass",
    "Feel the calm within you",
    "You are doing wonderfully"
)
```

### Neuer Ansatz:
```kotlin
// Option A: Arrays in strings.xml + getStringArray()
private fun getCountdownAffirmations(): Array<String> {
    return getApplication<Application>().resources.getStringArray(R.array.countdown_affirmations)
}

// Option B: Einzelne Strings laden (falls Array nicht gewuenscht)
private fun getCountdownAffirmation(index: Int): String {
    val resourceId = when (index % 4) {
        0 -> R.string.affirmation_countdown_1
        1 -> R.string.affirmation_countdown_2
        2 -> R.string.affirmation_countdown_3
        else -> R.string.affirmation_countdown_4
    }
    return getApplication<Application>().getString(resourceId)
}
```

### strings.xml erweitern (falls Array gewaehlt):
```xml
<string-array name="countdown_affirmations">
    <item>@string/affirmation_countdown_1</item>
    <item>@string/affirmation_countdown_2</item>
    <item>@string/affirmation_countdown_3</item>
    <item>@string/affirmation_countdown_4</item>
</string-array>
```

---

## Testanweisungen

```bash
# Unit Tests ausfuehren
cd android && ./gradlew test

# App auf Geraet/Emulator mit deutscher Sprache testen
# 1. Systemsprache auf Deutsch stellen
# 2. App starten
# 3. Timer starten
# 4. Pruefen: Affirmationen sind auf Deutsch
```

---

## Referenzen

- iOS laedt Affirmationen aus `Localizable.strings`:
  - `ios/StillMoment/Resources/de.lproj/Localizable.strings`
  - `ios/StillMoment/Resources/en.lproj/Localizable.strings`

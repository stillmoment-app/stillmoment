# Ticket android-070: Sound-Lokalisierung aus Domain-Modellen auslagern

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine (android-072 abgeschlossen)
**Phase**: 3-Refactor

---

## Was

`BackgroundSound.localizedName`/`localizedDescription` und `GongSound.localizedName` enthalten direkte `Locale.getDefault().language`-Abfragen im Domain-Modell. Diese Locale-Logik soll aus den Domain-Modellen entfernt werden. Die Locale-Aufloesung gehoert in die Presentation-Schicht.

**Stand nach android-072:** `BackgroundSound`-Namen kommen jetzt aus `sounds.json` und stehen als `nameEnglish`/`nameGerman` im Domain-Modell. Das Modell haelt also bereits beide Sprachvarianten als plain data — nur die Locale-Aufloesung in `localizedName` ist noch impure. `GongSound`-Namen sind weiterhin hardcodiert im Kotlin-Companion-Object, ebenfalls mit `localizedName`.

## Warum

Domain-Modelle sind "pure models — NO dependencies" (CLAUDE.md). `Locale.getDefault()` ist eine Plattform-Abhaengigkeit und macht Domain-Tests von der Geraete-Locale abhaengig. Das verletzt die Layer-Regel: reine Domain-Modelle duerfen keine Plattform-Imports haben.

---

## Akzeptanzkriterien

### Feature

**BackgroundSound:**
- [ ] `BackgroundSound.localizedName` und `localizedDescription` entfernt
- [ ] `import java.util.Locale` aus `BackgroundSound.kt` entfernt
- [ ] Presentation-Schicht liest `nameEnglish`/`nameGerman` direkt und waehlt per Locale

**GongSound:**
- [ ] `GongSound.localizedName` entfernt
- [ ] `import java.util.Locale` aus `GongSound.kt` entfernt
- [ ] Presentation-Schicht liest `nameEnglish`/`nameGerman` direkt und waehlt per Locale

**Shared:**
- [ ] Alle bisherigen `.localizedName`-Verwendungen in UI-Code weiterhin korrekt lokalisiert
- [ ] Kein `Locale.getDefault()` mehr in Domain-Modellen

### Tests
- [ ] `BackgroundSoundTest` (falls vorhanden) ist Locale-unabhaengig
- [ ] `GongSoundTest` (falls vorhanden) ist Locale-unabhaengig
- [ ] `make test` gruen

### Dokumentation
- [ ] `android/CLAUDE.md` ggf. aktualisieren falls Sound-Pattern dort beschrieben ist

---

## Manueller Test

1. Geraete-Sprache auf Deutsch stellen: Sound-Namen in der App sind auf Deutsch
2. Geraete-Sprache auf Englisch stellen: Sound-Namen auf Englisch
3. Erwartung in beiden Faellen: korrekte Namen in SettingsSheet und ConfigurationPills

---

## Referenz

- `android/.../domain/models/BackgroundSound.kt` — `localizedName`, `localizedDescription`, `import java.util.Locale`
- `android/.../domain/models/GongSound.kt` — `localizedName`, `import java.util.Locale`
- `android/.../presentation/ui/timer/` — alle Dateien die `.localizedName` verwenden
- `android/.../presentation/ui/PraxisExtensions.kt` — ebenfalls betroffen

---

## Hinweise

**Richtiger Ansatz (nach android-072):** `stringResId: Int` ist NICHT der richtige Weg — das wuerde eine Android-Plattform-Abhaengigkeit (`R`) ins Domain-Modell einschleppen.

Stattdessen: Domain-Modell haelt `nameEnglish`/`nameGerman` als plain Strings (bereits der Fall bei `BackgroundSound`). Die Presentation-Schicht liest die Locale und waehlt:

```kotlin
// Extension in Presentation-Schicht (z.B. PraxisExtensions.kt oder SoundExtensions.kt)
fun BackgroundSound.displayName(context: Context): String =
    if (Locale.getDefault().language == "de") nameGerman else nameEnglish

fun GongSound.displayName(context: Context): String =
    if (Locale.getDefault().language == "de") nameGerman else nameEnglish
```

Alternativ als Composable-Helper mit `LocalConfiguration`:

```kotlin
@Composable
fun BackgroundSound.localizedName(): String {
    val locale = LocalConfiguration.current.locales[0]
    return if (locale.language == "de") nameGerman else nameEnglish
}
```

Der Composable-Ansatz ist zu bevorzugen, da er Locale-Aenderungen zur Laufzeit korrekt trackt.

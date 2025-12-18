# Ticket 004: GuidedMeditation Domain Models

**Status**: [x] DONE
**Priorität**: HOCH
**Aufwand**: Klein (~1h)
**Abhängigkeiten**: Keine

---

## Beschreibung

Domain Models für Guided Meditations erstellen, analog zu iOS. Diese Models repräsentieren importierte Audio-Dateien mit Metadaten (Lehrer, Name, Dauer).

---

## Akzeptanzkriterien

- [x] `GuidedMeditation` data class in Domain Layer erstellt
- [x] Computed Properties: `effectiveTeacher`, `effectiveName`, `formattedDuration`
- [x] `GuidedMeditationGroup` data class für Gruppierung nach Lehrer
- [x] Unit Tests für Models vorhanden
- [x] Models sind Serializable (für DataStore)

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditation.kt`
- `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditationGroup.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/domain/models/GuidedMeditationTest.kt`

---

## Technische Details

### GuidedMeditation:
```kotlin
// domain/models/GuidedMeditation.kt
@Serializable
data class GuidedMeditation(
    val id: String = UUID.randomUUID().toString(),
    val fileUri: String,            // Content URI (SAF)
    val fileName: String,
    val duration: Long,             // Duration in milliseconds
    val teacher: String,            // From ID3 or user-edited
    val name: String,               // From ID3 or user-edited
    val customTeacher: String? = null,
    val customName: String? = null,
    val dateAdded: Long = System.currentTimeMillis()
) {
    val effectiveTeacher: String
        get() = customTeacher ?: teacher

    val effectiveName: String
        get() = customName ?: name

    val formattedDuration: String
        get() {
            val totalSeconds = duration / 1000
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            val seconds = totalSeconds % 60

            return if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format("%d:%02d", minutes, seconds)
            }
        }

    fun withCustomTeacher(teacher: String?): GuidedMeditation =
        copy(customTeacher = teacher)

    fun withCustomName(name: String?): GuidedMeditation =
        copy(customName = name)
}
```

### GuidedMeditationGroup:
```kotlin
// domain/models/GuidedMeditationGroup.kt
data class GuidedMeditationGroup(
    val teacher: String,
    val meditations: List<GuidedMeditation>
) {
    val count: Int get() = meditations.size

    val totalDuration: Long
        get() = meditations.sumOf { it.duration }

    val formattedTotalDuration: String
        get() {
            val totalSeconds = totalDuration / 1000
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            return if (hours > 0) {
                String.format("%dh %dm", hours, minutes)
            } else {
                String.format("%d min", minutes)
            }
        }
}

// Extension function for grouping
fun List<GuidedMeditation>.groupByTeacher(): List<GuidedMeditationGroup> {
    return groupBy { it.effectiveTeacher }
        .map { (teacher, meditations) ->
            GuidedMeditationGroup(
                teacher = teacher,
                meditations = meditations.sortedBy { it.effectiveName }
            )
        }
        .sortedBy { it.teacher }
}
```

---

## Unterschiede zu iOS

| Aspekt | iOS | Android |
|--------|-----|---------|
| File Reference | Security-Scoped Bookmark (Data) | Content URI (String) |
| ID | UUID | String (UUID.toString()) |
| Duration | TimeInterval (Double, seconds) | Long (milliseconds) |
| Serialization | Codable | Kotlinx Serialization |

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test --tests "*GuidedMeditation*"
```

---

## iOS-Referenz

- `ios/StillMoment/Domain/Models/GuidedMeditation.swift`

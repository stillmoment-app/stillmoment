# Ticket android-039: Library ViewModel Tests vervollstaendigen

**Status**: [x] DONE
**Prioritaet**: HOCH (Kritischer Test-Coverage Gap)
**Aufwand**: Mittel (~2h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

GuidedMeditationsListViewModelTest erweitern, um die tatsaechliche ViewModel-Logik zu testen (import, delete, update flows), nicht nur die UiState data class.

## Warum

**Review-Ergebnis vom 2025-12-19:**

Die iOS Library View hat **93/100 Punkte**, Android nur **80/100**. Der Hauptgrund ist die Test-Coverage:

| Plattform | Test-Coverage Score |
|-----------|---------------------|
| iOS | 23/25 |
| Android | **12/25** |

**Problem:** Die aktuellen Android-Tests testen ausschliesslich die `UiState` data class Properties:
- `totalCount` (computed property)
- `isEmpty` (computed property)
- `availableTeachers` (computed property)
- State copy behavior

**NICHT getestet (0% Coverage):**
- `importMeditation(uri)` - Import Flow
- `deleteMeditation(meditation)` - Delete Flow
- `updateMeditation(meditation)` - Update Flow
- `showEditSheet(meditation)` / `hideEditSheet()` - UI State Transitions
- `confirmDelete()` / `cancelDelete()` / `executeDelete()` - Delete Confirmation Flow
- `clearError()` - Error Handling
- Loading State Transitions
- Error State Handling

**iOS-Referenz:** `GuidedMeditationsListViewModelTests.swift` hat **37 Tests** die alle diese Flows abdecken.

---

## Akzeptanzkriterien

- [ ] Repository-Mock/Fake erstellen (`FakeGuidedMeditationRepository`)
- [ ] `importMeditation()` Flow getestet (Success + Failure)
- [ ] `deleteMeditation()` Flow getestet
- [ ] `updateMeditation()` Flow getestet
- [ ] `showEditSheet()` / `hideEditSheet()` Flow getestet
- [ ] `confirmDelete()` / `cancelDelete()` / `executeDelete()` Flow getestet
- [ ] Error Handling verifiziert (error state wird gesetzt/geloescht)
- [ ] Loading State Transitions getestet
- [ ] StateFlow-Updates mit Turbine oder `first()` getestet

---

## Manueller Test

1. `cd android && ./gradlew test`
2. Erwartung: Alle Tests gruen, Coverage fuer ViewModel-Logik sichtbar

---

## Referenz

**iOS-Tests als Vorlage (37 Tests):**
- `ios/StillMomentTests/GuidedMeditationsListViewModelTests.swift`

**Getestete Flows in iOS:**
```swift
// Initialization
testInitialization()

// Load
testLoadMeditationsSuccess()
testLoadMeditationsEmpty()
testLoadMeditationsFailure()

// Import
testImportMeditationSuccess()
testImportMeditationMetadataExtractionFails()
testImportMeditationServiceFails()

// Delete
testDeleteMeditationSuccess()
testDeleteMeditationFailure()
testDeleteNonExistentMeditation()

// Update
testUpdateMeditationSuccess()
testUpdateMeditationFailure()

// UI State
testShowDocumentPicker()
testShowEditSheet()

// Grouping
testMeditationsByTeacherEmpty()
testMeditationsByTeacherSingleTeacher()
testMeditationsByTeacherMultipleTeachers()
// ... weitere

// Loading/Error State
testLoadingStateDuringLoad()
testErrorMessageClearedOnNextOperation()
testErrorMessageClearedOnImport()
```

**Pattern fuer Mock Service:**
```swift
final class MockGuidedMeditationServiceExtended: GuidedMeditationServiceProtocol {
    var meditations: [GuidedMeditation] = []
    var loadShouldThrow = false
    var addShouldThrow = false
    var updateShouldThrow = false
    var deleteShouldThrow = false
    // ...
}
```

**Android-Aequivalent (zu erstellen):**
```kotlin
class FakeGuidedMeditationRepository : GuidedMeditationRepository {
    var meditations = mutableListOf<GuidedMeditation>()
    var importShouldFail = false
    var deleteShouldFail = false
    var updateShouldFail = false

    override val meditationsFlow: Flow<List<GuidedMeditation>>
        get() = flowOf(meditations)

    override suspend fun importMeditation(uri: Uri): Result<GuidedMeditation> {
        return if (importShouldFail) {
            Result.failure(Exception("Import failed"))
        } else {
            val meditation = GuidedMeditation(...)
            meditations.add(meditation)
            Result.success(meditation)
        }
    }
    // ...
}
```

---

## Hinweise

- Repository muss gemockt werden (Interface: `GuidedMeditationRepository`)
- Coroutines testen mit `runTest` und `TestDispatcher`
- StateFlow-Updates mit `turbine` Library oder manuell mit `first()` testen
- Bestehende Test-Struktur in `GuidedMeditationPlayerViewModelTest.kt` als Referenz

---

## Review-Kontext

Dieses Ticket wurde durch `/review-view Library` identifiziert.

**Gesamt-Bewertung Library View:**
| Kategorie | iOS | Android |
|-----------|-----|---------|
| Accessibility | 22/25 | 19/25 |
| Code-Qualitaet | 23/25 | 25/25 |
| Test-Coverage | 23/25 | **12/25** |
| UX/Layout | 25/25 | 24/25 |
| **Gesamt** | **93/100** | **80/100** |

Nach Umsetzung dieses Tickets sollte Android Test-Coverage auf ~22/25 steigen.

---

*Generiert/Aktualisiert mit `/review-view Library` am 2025-12-19*

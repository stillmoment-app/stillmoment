# Ticket android-039: Library ViewModel Tests vervollstaendigen

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel (~2h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

GuidedMeditationsListViewModelTest erweitern, um die tatsaechliche ViewModel-Logik zu testen (import, delete, update flows), nicht nur die UiState data class.

## Warum

Die aktuellen Tests testen nur die UiState data class Properties (totalCount, isEmpty, availableTeachers). Die ViewModel-Funktionen (importMeditation, deleteMeditation, updateMeditation, showEditSheet) haben keine Test-Coverage.

---

## Akzeptanzkriterien

- [ ] importMeditation() Flow getestet (Success + Failure)
- [ ] deleteMeditation() Flow getestet
- [ ] updateMeditation() Flow getestet
- [ ] showEditSheet() / hideEditSheet() Flow getestet
- [ ] Error Handling verifiziert (error state wird gesetzt/geloescht)
- [ ] Loading State Transitions getestet
- [ ] Repository wird mit Mock/Fake getestet

---

## Manueller Test

1. `cd android && ./gradlew test`
2. Erwartung: Alle Tests gruen, Coverage fuer ViewModel-Logik sichtbar

---

## Referenz

iOS-Tests als Vorlage:
- `ios/StillMomentTests/GuidedMeditationsListViewModelTests.swift`
- Pattern: Mock Services mit Flags (`loadShouldThrow`, `addShouldThrow`)

Bestehende Android-Test-Struktur:
- `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModelTest.kt`

---

## Hinweise

- Repository muss gemockt werden (Interface: `GuidedMeditationRepository`)
- Coroutines testen mit `runTest` und `TestDispatcher`
- StateFlow-Updates mit `turbine` Library oder manuell mit `first()` testen

---

*Generiert mit `/review-view Library`*

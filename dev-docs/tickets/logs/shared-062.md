# shared-062: Praxis-Datenmodell und Persistenz

---

## IMPLEMENT
Status: DONE
Commits:
- 51a629f feat(ios): #shared-062 add Praxis domain model and repository protocol

Challenges:
<!-- CHALLENGES_START -->
- Test file header: SwiftLint `file_header` rule requires "Still Moment" (not "StillMomentTests") as module name in test file headers. Consistent across all test files.
- CHANGELOG/glossary from previous session referenced unimplemented `UserDefaultsPraxisRepository` -- had to fix documentation to match actual implementation scope (domain layer only).
<!-- CHALLENGES_END -->

Summary:
iOS domain layer for Praxis implemented: immutable `Praxis` value object with full validation (duration, interval, volume, preparation time clamping), `PraxisRepository` protocol with CRUD operations and error types, migration initializer from `MeditationSettings`, localized `shortDescription`, and 25 unit tests covering defaults, equality, validation, short description, and migration. Localization strings added for DE and EN.

---

## IMPLEMENT (Infrastructure)
Status: DONE
Commits:
- 7199a7c feat(ios): #shared-062 add UserDefaultsPraxisRepository with migration

Challenges:
<!-- CHALLENGES_START -->
- PraxisRepositoryError needed Equatable conformance for test assertions with XCTAssertEqual -- added it to the domain protocol file.
- SwiftLint `conditional_returns_on_newline` rule requires `guard let sut else {` and `return XCTFail(...)` on separate lines -- single-line guard-else-return pattern is rejected.
- SwiftLint `trailing_closure` rule flagged `all.contains(where: { ... })` -- must use `all.contains { ... }` trailing closure syntax.
<!-- CHALLENGES_END -->

Summary:
iOS infrastructure layer for Praxis persistence implemented: `UserDefaultsPraxisRepository` stores praxes as JSON-encoded array in UserDefaults, handles fresh install (creates default Praxis) and migration (converts existing MeditationSettings to "Standard" Praxis). 18 unit tests covering CRUD, active praxis ID, migration, and round-trip persistence.

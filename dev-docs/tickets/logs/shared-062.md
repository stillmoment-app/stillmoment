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

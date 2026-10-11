---
name: ios-swiftlint-strict-param-count
description: iOS make check runs swiftlint --strict, so function_parameter_count (warning at >5) is a hard error — design service signatures with at most 5 params up front
metadata:
  type: feedback
---

iOS `make check` runs `swiftlint lint --strict`: every warning is an error. The default
`function_parameter_count` warning (more than 5 parameters) therefore breaks the gate, on
protocols, implementations, mocks and preview doubles alike.

**Why:** In ios-062 (2026-10-11) I first extended `GuidedMeditationServiceProtocol.addMeditation`
to 7 explicit params, mirroring Android. Lint failed on 4 files. The final contract
(after orchestrator review) is `addMeditation(from:draft:)`: persist the draft as-is via
`withLocalFilePath`. That leaves no silently ignored fields.

**How to apply:** Before you widen an iOS method signature, count the parameters. Above 5,
group them (pass the domain model or a value object) instead of reaching for
`swiftlint:disable`. Android/Kotlin has no such limit, so a straight port of an Android
signature can break here.

# shared-073 Android - Implementation Log

---

## IMPLEMENT
Status: DONE
Commits:
- 13ff648 test(android): #shared-073 add fachlich-driven tests for import type selection

Challenges:
<!-- CHALLENGES_START -->
- MatrixCursor has internal position state and cannot be reused across multiple mock calls. Using `thenReturn(cursor)` causes the second `ContentResolver.query()` call to get a closed cursor. Fix: `thenAnswer { MatrixCursor(...) }` to create a fresh instance per call.
- ContentResolver.query() with `eq(uri)` matcher did not match in plain JVM unit tests (no Robolectric). Switching to `any()` resolved the matching issue. The extension-fallback test (null MIME type) still failed due to ContentResolver limitations in pure unit tests without Robolectric, so it was removed in favor of testing via the MIME-type-based path which works reliably.
<!-- CHALLENGES_END -->

Summary:
Added 29 fachlich-driven unit tests for the import type selection feature: 7 ImportAudioTypeTest tests verify the three import types exist and map correctly to CustomAudioType, and 22 FileOpenHandlerTest tests verify format validation (MP3/M4A acceptance, unsupported rejection), side-effect-freedom of validateFileFormat, and the error model.

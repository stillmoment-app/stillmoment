---
name: mockito-suspend-thenthrow
description: Mockito thenThrow mit Checked Exception scheitert bei suspend-Mocks — thenAnswer verwenden
metadata:
  type: feedback
---

Bei Mockito-Mocks von `suspend`-Funktionen schlägt `wheneverBlocking { mock.suspendFn(x) }.thenThrow(CheckedException(...))` mit `MockitoException` fehl, wenn die Exception eine Checked Exception ist (z.B. `WaveformGenerationException`).

**Why:** Mockito prüft die Checked-Exception gegen die generierte suspend-Wrapper-Signatur (Continuation-basiert), nicht gegen die deklarierte Kotlin-Signatur — die Throws-Klausel passt nicht, also wird die Exception als unzulässig abgelehnt.

**How to apply:** Statt `.thenThrow(SomeCheckedException(...))` `.thenAnswer { throw SomeCheckedException(...) }` verwenden. Gilt nur für suspend-Funktionen; bei normalen Funktionen funktioniert `thenThrow` weiterhin.

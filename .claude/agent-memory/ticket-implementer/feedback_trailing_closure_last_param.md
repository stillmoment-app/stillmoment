---
name: trailing-closure-last-param
description: SwiftLint trailing_closure zwingt bei Closure-als-letztem-Parameter zur Trailing-Syntax; benannte Konstante/Methodenreferenz statt Literal
metadata:
  type: feedback
---

Bekommt eine Methode einen Closure als **letzten** Parameter (`onProgress:`, `onCancel:`,
`completion:`), schlaegt SwiftLints `trailing_closure` an jeder Aufrufstelle zu, die ihn
als benanntes Argument uebergibt.

**Why:** Die Regel ist opt-in aktiviert und laeuft im Pre-commit mit `--strict`, also als Error.
In Tests will man den Closure aber meist *nicht* haben ("interessiert hier nicht") und die
Trailing-Syntax macht aus einer Zeile drei — was dann `file_length`/`type_body_length` reisst.
Bei shared-124 hat diese Kette drei Lint-Runden gekostet.

**How to apply:** Statt `onProgress: { _ in }` eine benannte Konstante nutzen
(`static let ignoreProgress: (Double) -> Void = { _ in }`) oder eine Methodenreferenz
(`onProgress: recorder.record`) — beides sind keine Closure-Literale, die Regel greift nicht.
Fuer viele gleichartige Aufrufe lohnt eine Kurzform-Hilfsmethode im Test
(`downloadIgnoringProgress(sut, from:filename:)`), damit die Aufrufe einzeilig bleiben.
Im Produktionscode denselben Trick: Closure in einer `private func makeXHandler() -> (T) -> Void`
bauen und die Variable uebergeben.

Verwandt: wenn eine Testklasse dadurch ueber `type_body_length` (350) laeuft, neue Tests in eine
`Klasse+Thema.swift`-Extension auslagern und benoetigte Member von `private` auf `internal`
heben — siehe [[feedback_view_extension_file_split]].

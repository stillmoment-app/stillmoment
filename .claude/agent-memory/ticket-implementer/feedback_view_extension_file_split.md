---
name: feedback-view-extension-file-split
description: Beim Aufteilen grosser SwiftUI-Views in Type+Topic.swift kollidieren die file_name-Regel und Swifts private-Sichtbarkeit; Loesung sind verschachtelte ViewModifier mit Bindings
metadata:
  type: feedback
---

Wandert ein Block (z.B. `.alert`-Modifier) aus einer zu grossen View in eine
Datei `TypeName+Topic.swift`, muss diese Datei eine `extension TypeName`
deklarieren — sonst schlaegt SwiftLints `file_name` zu. In der Extension sind
die `private` gehaltenen `@State`/`@StateObject`-Member der View aber **nicht**
sichtbar, weil `private` in Swift dateiweit gilt.

Bewaehrte Loesung: in der Extension einen verschachtelten `ViewModifier`
deklarieren, der die benoetigten Werte als `@Binding` und Closures
entgegennimmt; die Hauptdatei ruft ihn per `.modifier(...)` auf. Zugriffsrechte
bleiben unangetastet, die Verschiebung bleibt verhaltensneutral.

**Why:** Die Alternativen sind schlechter — `private` auf `internal` lockern
weicht die Kapselung der View auf, und eine `extension View` im selben File
verletzt die `file_name`-Regel.

**How to apply:** Immer wenn `file_length` (warning 400 / error 500) eine View
zum Aufteilen zwingt. Dateien mit ausschliesslich `#Preview`-Makros brauchen die
Extension nicht — `file_name` prueft nur, wenn die Datei ueberhaupt Typen
deklariert. Praezedenzfall: `GuidedMeditationsListView+Alerts.swift` (shared-124,
Paket 0).

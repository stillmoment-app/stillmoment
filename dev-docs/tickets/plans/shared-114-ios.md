# Implementierungsplan: shared-114 (iOS)

Ticket: [shared-114](../shared/shared-114-topbar-navigation-boilerplate.md)
Erstellt: 2026-06-14

## Ziel

Den 7-fach duplizierten Screen-Titel-Workaround (`.navigationBarTitleDisplayMode(.inline)` + `ToolbarItem(placement: .principal)` mit `Text(...).textStyle(.screenTitle, color: \.textPrimary)`) in einen wiederverwendbaren ViewModifier `.screenTitleBar(_:)` bündeln. Sichtbares Verhalten bleibt exakt gleich.

## Annahmen

- Der neue Modifier nimmt einen `LocalizedStringKey` entgegen und repliziert intern exakt `Text(titleKey, bundle: .main).textStyle(.screenTitle, color: \.textPrimary)` — der `bundle: .main`-Parameter bleibt erhalten, da alle bestehenden Aufrufe ihn nutzen.
- Mehrere `.toolbar`-Modifier an einer View werden von SwiftUI additiv zusammengeführt. SettingsView kann daher `.screenTitleBar(...)` nutzen UND seinen bestehenden `.toolbar`-Block mit dem `.confirmationAction`-Done-Button unverändert behalten. (Verifizieren während der Implementierung am laufenden Screen.)
- Neue Datei wird automatisch vom Xcode `PBXFileSystemSynchronizedRootGroup` erkannt — kein pbxproj-Eingriff nötig.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/Views/Shared/View+ScreenTitleBar.swift` | Presentation | **Neu** | ViewModifier `.screenTitleBar(_:)` — kapselt `.navigationBarTitleDisplayMode(.inline)` + `.principal`-Titel mit `.screenTitle`/`\.textPrimary` |
| `Presentation/Views/Timer/GongSelectionView.swift` | Presentation | Ersetzen | Titel-Block (Z. 38–44) durch `.screenTitleBar("praxis.editor.startGong.title")` |
| `Presentation/Views/Timer/PreparationTimeSelectionView.swift` | Presentation | Ersetzen | Titel-Block durch Modifier-Aufruf |
| `Presentation/Views/Timer/BackgroundSoundSelectionView.swift` | Presentation | Ersetzen | Titel-Block durch Modifier-Aufruf |
| `Presentation/Views/Timer/IntervalGongsEditorView.swift` | Presentation | Ersetzen | Titel-Block durch Modifier-Aufruf |
| `Presentation/Views/.../SettingsView.swift` | Presentation | Ersetzen (teilweise) | Titel-Block durch Modifier-Aufruf; bestehender `.confirmationAction`-Done-Button bleibt im separaten `.toolbar`-Block |
| `Presentation/Views/.../AppSettingsView.swift` | Presentation | Ersetzen | Titel-Block durch Modifier-Aufruf |
| `Presentation/Views/.../SoundAttributionsView.swift` | Presentation | Ersetzen | Titel-Block durch Modifier-Aufruf |

> Exakte Pfade/Zeilen pro Screen während der Implementierung per Glob/Read bestätigen — die Views liegen in Unterordnern (`Timer/`, ggf. `Settings/`).

## Bestehender Code-Block (Vorlage, aus GongSelectionView Z. 38–44)

```swift
.navigationBarTitleDisplayMode(.inline)
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("praxis.editor.startGong.title", bundle: .main)
            .textStyle(.screenTitle, color: \.textPrimary)
    }
}
```

## Geplante API

```swift
extension View {
    /// Setzt einen inline-Screen-Titel mit Theme-Farbe (textPrimary).
    /// Kapselt den .principal-Workaround, da .navigationTitle() die Theme-Farbe
    /// ignoriert (UIKit-Bridge).
    func screenTitleBar(_ titleKey: LocalizedStringKey) -> some View
}
```

Implementierung via privatem `ViewModifier` (analog `TextStyleModifier` in `View+TextStyle.swift`). Der Modifier braucht selbst **kein** `@Environment(\.themeColors)` — die Farbe wird von `.textStyle(.screenTitle, color: \.textPrimary)` aufgelöst, das intern bereits das Environment liest.

## Design-Entscheidungen

### Parameter-Typ `LocalizedStringKey` statt `String`

**Trade-off:** `String` + `NSLocalizedString` wäre expliziter; `LocalizedStringKey` matcht den bestehenden `Text("key", bundle: .main)`-Aufruf 1:1 und vermeidet doppelte Lokalisierung.
**Entscheidung:** `LocalizedStringKey`, intern `Text(titleKey, bundle: .main)`. Garantiert identisches Verhalten zum aktuellen Code.

### SoundAttributionsView Titel-Quelle prüfen

SoundAttributionsView könnte einen dynamischen/zusammengesetzten Titel haben. Während der Implementierung prüfen, ob der Titel ein statischer Key ist (dann Modifier nutzbar) oder eine interpolierte Variante (dann ggf. außen vor lassen und im Review begründen).

## Refactorings

Keine. Reine Extraktion eines duplizierten Blocks in einen Modifier — additiv, bricht nichts.

## Fachliche Szenarien

### AK: Titel-Darstellung unverändert
- Gegeben: Nutzer öffnet die Gong-Auswahl
  Wenn: der Screen erscheint
  Dann: der Titel steht zentriert in der Nav-Bar, in `textPrimary`-Farbe, inline-Display-Mode — identisch zu vorher.

### AK: Theme-Farbe folgt Dark Mode / Theme
- Gegeben: Nutzer hat Dark Mode oder ein farbiges Theme aktiv
  Wenn: er einen betroffenen Screen öffnet
  Dann: der Titel nutzt die korrekte `textPrimary`-Theme-Farbe (nicht System-Schwarz/Weiß) — der UIKit-Bridge-Bug kehrt nicht zurück.

### AK: SettingsView Done-Button bleibt
- Gegeben: Nutzer öffnet die Einstellungen
  Wenn: der Screen erscheint
  Dann: Titel UND der "Done"-Button (`.confirmationAction`) sind sichtbar und funktional.

### AK: Null-Regression über alle 7 Screens
- Gegeben: alle 7 betroffenen Screens
  Wenn: nach dem Refactoring geöffnet
  Dann: Titel-Text, -Farbe, -Position und Display-Mode identisch zu vorher; bestehende Tests/Screenshots bleiben grün.

## Reihenfolge

1. Neuen Modifier `View+ScreenTitleBar.swift` anlegen.
2. Einen Screen (GongSelectionView) umstellen, visuell + per Build verifizieren.
3. Übrige 6 Screens mechanisch umstellen (SettingsView mit Sorgfalt wegen Done-Button).
4. `make check` + bestehende Tests/Screenshots grün.

## Offene Fragen

- Keine. Bei dynamischem Titel in SoundAttributionsView: Screen aus dem Scope nehmen und im Review begründen.

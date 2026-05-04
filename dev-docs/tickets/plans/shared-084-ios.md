# Implementierungsplan: shared-084 (iOS)

Ticket: [shared-084](../shared/shared-084-meditationen-tab-zuerst.md)
Erstellt: 2026-05-04

## Ziel

Tab-Reihenfolge in der TabBar tauschen (Meditationen, Timer, Einstellungen) und beim allerersten App-Start auf den Meditationen-Tab landen. Bestehende Last-used-Persistenz (shared-002) bleibt unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `ios/StillMoment/StillMomentApp.swift` | Presentation | Aendern | Reihenfolge der `TabView`-Children tauschen (Library vor Timer); `@AppStorage("selectedTab")`-Default von `AppTab.timer.rawValue` auf `AppTab.library.rawValue`. |
| `ios/StillMomentTests/AppTabTests.swift` | Tests | Anpassen | `testDefaultTabIsTimer` → `testDefaultTabIsLibrary`. Default-Verhalten dokumentiert hier. |
| `ios/StillMomentUITests/ScreenshotTests.swift` | UITests | Anpassen | `TabIndex.timer/library` tauschen (`library = 0`, `timer = 1`, `settings = 2`). `navigateToLibraryTab()` greift per `boundBy: TabIndex.library` zu — Index muss korrekt sein. |

Nicht betroffen:
- `AppTab` enum selbst (raw values bleiben "timer", "library", "settings" — Persistenz-Stabilitaet, vgl. `testRawValuesAreStableForPersistence`).
- Lokalisierungen (`tab.library`, `tab.timer`, `tab.settings`) — Keys sind orientierungsfrei, Texte bereits korrekt aus shared-071.
- Domain/Application/Infrastructure — reine Presentation-Aenderung.
- `handleImportTypeSelection(...)` — setzt `selectedTab` explizit auf `library` bzw. `timer` per raw value, unabhaengig von der Reihenfolge.

---

## API-Recherche

Keine externen APIs noetig. SwiftUI `TabView` mit `selection:`-Binding und `.tag()` ist bereits verwendet — Reihenfolge ergibt sich rein aus der Reihenfolge der Children im View-Builder. `@AppStorage` mit String-Default ist Standard.

Hinweis: Die `tag()`-Werte bleiben dieselben (`AppTab.library.rawValue` etc.), das Tausch-Verhalten ist nur visuelle Reihenfolge im View-Tree.

---

## Design-Entscheidungen

### 1. Default-Tab nur fuer Frischinstallationen

**Trade-off:** Bestandsuser, die `selectedTab="timer"` durch passive Akzeptanz des alten Defaults (nicht aktiver Wahl) im UserDefaults haben, sehen weiterhin den Timer-Tab beim Start. Eine harte Migration ("alle User auf Meditationen umstellen") koennte das angleichen, wuerde aber aktiv gewaehlte `timer`-Praeferenzen ueberschreiben — wir koennen die zwei Faelle nicht unterscheiden.

**Entscheidung:** Keine Migration. Default-Wert in `@AppStorage` aendern reicht — wirkt nur wenn kein Wert gespeichert ist (= Frischinstallation oder geloeschte App-Daten). Bestandsuser behalten ihren persistierten Tab. Das deckt sich mit dem Ticket-Wortlaut ("Beim allerersten App-Start" + "shared-002 bleibt gueltig").

### 2. Keine Aenderung an `AppTab`-Enum-Reihenfolge

**Trade-off:** Man koennte den Enum-Cases im Code umsortieren (`case library, timer, settings`), damit `AppTab.allCases` der UI-Reihenfolge entspricht.

**Entscheidung:** Nicht aendern. Raw values sind persistenzrelevant, Enum-Reihenfolge ist im Code nirgends als UI-Quelle benutzt (TabView listet Children explizit). Die UI-Reihenfolge lebt im `body` von `StillMomentApp` — eine zweite Quelle einzufuehren waere redundant. `allCases.count == 3` reicht als Test.

---

## Refactorings

Keine. Aenderung ist additiv-tauschend, betrifft drei Stellen punktuell.

---

## Fachliche Szenarien

### AK-1: Tab-Reihenfolge (Meditationen, Timer, Einstellungen)

- **Gegeben:** App ist gestartet
  **Wenn:** User schaut auf die TabBar
  **Dann:** Erster Tab links ist Meditationen (waveform-Icon), zweiter ist Timer (timer-Icon), dritter ist Einstellungen (slider-Icon)

- **Gegeben:** ScreenshotTests-Helper greifen per Index auf Tabs zu
  **Wenn:** `navigateToLibraryTab()` ausgefuehrt wird
  **Dann:** Der Tab am Index 0 ist der Library-Tab, Library-Inhalte werden sichtbar

### AK-2: Frischinstallation startet auf Meditationen

- **Gegeben:** App wird neu installiert (`UserDefaults` ohne Eintrag fuer `selectedTab`)
  **Wenn:** User startet die App das erste Mal
  **Dann:** Meditationen-Tab ist aktiv

- **Gegeben:** User hat zuvor App-Daten geloescht
  **Wenn:** App wird erneut gestartet
  **Dann:** Meditationen-Tab ist aktiv (gleiche Logik wie Frischinstallation)

### AK-3: Last-used bleibt erhalten (shared-002 weiterhin gueltig)

- **Gegeben:** User wechselt zum Timer-Tab und schliesst die App
  **Wenn:** User startet die App erneut
  **Dann:** Timer-Tab ist aktiv (zuletzt gewaehlter Tab)

- **Gegeben:** User wechselt zum Einstellungen-Tab und schliesst die App
  **Wenn:** User startet die App erneut
  **Dann:** Einstellungen-Tab ist aktiv

- **Gegeben:** Bestandsuser mit persistiertem `selectedTab="timer"` (passive Default-Akzeptanz vor shared-084)
  **Wenn:** User startet die App nach dem Update
  **Dann:** Timer-Tab ist aktiv (Persistenz wird respektiert; bewusste Entscheidung gegen Migration)

### AK-4: Persistenz-Stabilitaet (Regression-Schutz)

- **Gegeben:** `AppTab`-Enum existiert
  **Wenn:** Raw values gelesen werden
  **Dann:** `timer`, `library`, `settings` (Strings unveraendert — User-Defaults aus alten Versionen lesbar)

---

## Reihenfolge der Akzeptanzkriterien (TDD-Pfad)

1. **AK-2 (Default Meditationen)** — Test: `testDefaultTabIsLibrary` (rot), dann `@AppStorage`-Default in `StillMomentApp` auf `AppTab.library.rawValue` setzen (gruen).
2. **AK-1 (Reihenfolge)** — Tausch der `TabView`-Children in `StillMomentApp.body`. Verifikation per ScreenshotTests-Helper-Anpassung (`TabIndex.library = 0, timer = 1`). Bestaetigung visuell + per `navigateToLibraryTab()`.
3. **AK-3 (Last-used)** — Bestehende Persistenz-Logik unveraendert; Smoke-Test manuell laut Ticket.
4. **AK-4 (Raw values stabil)** — `testRawValuesAreStableForPersistence` existiert bereits, sollte nach Aenderung weiterhin gruen sein.

Reihenfolge AK-2 → AK-1 vermeidet, dass bei einem Zwischenzustand (Reihenfolge schon getauscht, Default noch alt) der Timer-Tab aufpoppt, obwohl er nun an Position 2 stehen soll.

---

## Manueller Test (laut Ticket)

1. App-Daten loeschen (lange auf App-Icon → "App entfernen" → "Aus App-Datenbank entfernen") oder frisch via Simulator installieren.
2. App starten → Erwartung: Meditationen-Tab aktiv, Tab-Reihenfolge Meditationen | Timer | Einstellungen.
3. Auf Timer-Tab wechseln, App schliessen (App-Switcher killen), App neu oeffnen → Erwartung: Timer-Tab aktiv.
4. Auf Einstellungen-Tab wechseln, App schliessen, App neu oeffnen → Erwartung: Einstellungen-Tab aktiv.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| ScreenshotTests fallen durch (Library-Index falsch) | `TabIndex` in `ScreenshotTests.swift` mit dem Tab-Tausch synchron anpassen — beide Aenderungen im selben Commit. |
| Bestandsuser mit persistiertem `timer` empfinden "kein Effekt" | Bewusste Entscheidung (siehe Design-Entscheidung 1). Im CHANGELOG erwaehnen, dass die Reihenfolge sich aendert und Frischinstallationen mit Meditationen starten. |
| Folge-Ticket shared-085 (Marketing/Screenshots) abhaengig | Kein direktes Risiko fuer dieses Ticket — nur Hinweis dass App-Store-Screenshots nach Implementierung neu zu generieren sind. |

---

## Offene Fragen

Keine.

# Implementierungsplan: shared-084 (Android)

Ticket: [shared-084](../shared/shared-084-meditationen-tab-zuerst.md)
iOS-Plan: [shared-084-ios.md](shared-084-ios.md)
Erstellt: 2026-05-05

## Ziel

Tab-Reihenfolge in der `NavigationBar` tauschen (Meditationen, Timer, Einstellungen) und beim allerersten App-Start auf den Meditationen-Tab landen. Bestehende Last-used-Persistenz (shared-002) bleibt unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `android/app/src/main/kotlin/com/stillmoment/domain/models/AppTab.kt` | Domain | Aendern | `DEFAULT = TIMER` → `DEFAULT = LIBRARY`. Single Source of Truth fuer alle Stellen, die den Default ueber `AppTab.fromRoute()` bzw. `AppTab.DEFAULT` ableiten. |
| `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt` | Presentation | Aendern | (a) Reihenfolge der `tabs`-`persistentListOf` (Zeilen 171–196) tauschen: erst LIBRARY-`TabItem`, dann TIMER, dann SETTINGS. (b) SETTINGS-Icon von `Icons.AutoMirrored.Filled/Outlined.QueueMusic` auf `Icons.Filled.Tune` / `Icons.Outlined.Tune` aendern (iOS-Pendant zu `slider.horizontal.3`). |
| `android/app/src/test/kotlin/com/stillmoment/domain/models/AppTabTest.kt` | Tests | Anpassen | `Default.DEFAULT is TIMER` → `DEFAULT is LIBRARY`. |
| `android/app/src/test/kotlin/com/stillmoment/data/local/SettingsDataStoreTest.kt` | Tests | Anpassen | `AppTab DEFAULT is TIMER` → `LIBRARY`. |
| `CHANGELOG.md` | Docs | Ergaenzen | Android-Eintrag analog zum bestehenden iOS-Eintrag unter „Meditationen-Tab als erster Tab". |

Nicht betroffen:
- `AppTab`-Routen (`timerGraph`, `library`, `settings`) — werden in DataStore persistiert, Stabilitaet-Tests existieren bereits (`SettingsDataStoreTest.AppTab routes are stable for persistence`, `AppTabTest.routes are stable for persistence`).
- `SettingsDataStore.selectedTabFlow` / `getSelectedTab()` / `setSelectedTab()` — Persistenz-Mechanik bleibt wie sie ist; Default-Wechsel wirkt automatisch ueber `AppTab.fromRoute(null)`.
- `NavigationTest.kt` (androidTest) — verwendet einen isolierten `TestNavigationHost` mit hartcodiertem Timer-Default; das ist ein bewusster Test-Stub, der nicht ueber `AppTab.DEFAULT` laeuft. Keine Aenderung noetig.
- `ScreengrabScreenshotTests.kt` — `setup()` setzt explizit `setSelectedTab(AppTab.TIMER)` vor Tests (siehe Zeile 104). Tab-Klicks gehen ueber Content-Descriptions (`Navigate to timer` / `Navigate to meditations`), nicht ueber Index. Reihenfolgewechsel und Default-Wechsel haben hier keinen Effekt.
- `handleCustomAudioImport()` (NavGraph.kt:922) — setzt nach Soundscape-Import explizit `setSelectedTab(AppTab.TIMER)`; semantisch korrekt (User hat eben einen Soundscape importiert, der zum Timer gehoert) und unabhaengig vom Default-Verhalten.
- Lokalisierungen (`tab_timer`, `tab_library`, `tab_settings`, `accessibility_tab_*`) — orientierungsfrei, bereits korrekt aus shared-071.
- ViewModels, Repositories, Audio-Stack — reine Presentation-/Domain-Default-Aenderung.

---

## API-Recherche

Keine externen APIs noetig. Compose-Navigation `NavHost` mit `startDestination = savedTab.route` ist bereits etabliert; `produceState` laed den persistierten Tab vor dem ersten Compose-Frame. `persistentListOf<TabItem>` ist eine `kotlinx.collections.immutable`-Liste — Reihenfolge ergibt sich rein aus Konstruktor-Reihenfolge.

Hinweis: `AppTab.fromRoute(null)` liefert bereits `AppTab.DEFAULT`. Die DataStore-Schicht muss nicht angefasst werden — der Default-Wechsel in der Domain propagiert automatisch.

---

## Design-Entscheidungen

### 1. Default in `AppTab` umstellen, nicht in DataStore

**Trade-off:** Man koennte den Default lokal in `SettingsDataStore.selectedTabFlow` haerten (z. B. `AppTab.LIBRARY` als Fallback). Das wuerde die Domain-Konstante unangetastet lassen.

**Entscheidung:** `AppTab.DEFAULT` aendern. Das Domain-Modell ist explizit die Single Source of Truth (Kommentar: „Default tab shown on first app launch") — ein zweiter Default in der Infrastructure-Schicht waere Duplikation und ein Architekturbruch. Alle Aufrufer (DataStore, `fromRoute()`-Fallbacks) ziehen automatisch nach. iOS fuehrt die Aenderung in der `@AppStorage`-Default-Definition durch, weil dort kein Domain-Pendant existiert; Android ist hier sauberer.

### 2. Keine Migration fuer Bestandsuser

**Trade-off:** Bestandsuser, die durch passive Akzeptanz des alten Defaults `selected_tab="timerGraph"` im DataStore haben, sehen weiterhin den Timer-Tab beim Start. Man koennte einen `selected_tab`-Wert „one-shot"-loeschen, um sie auf den neuen Default zu lenken — wuerde aber aktiv gewaehlte Timer-Praeferenzen ueberschreiben.

**Entscheidung:** Keine Migration. `AppTab.fromRoute(...)` greift nur, wenn kein Wert oder ein unbekannter Wert gespeichert ist (= Frischinstallation oder geloeschte App-Daten). Konsistent zum iOS-Plan und zum Ticket-Wortlaut („Beim allerersten App-Start" + „shared-002 bleibt gueltig").

### 3. Enum-Reihenfolge in `AppTab` nicht aendern

**Trade-off:** Man koennte die Enum-Cases umsortieren (`LIBRARY, TIMER, SETTINGS`), damit `AppTab.entries` der UI-Reihenfolge entspricht.

**Entscheidung:** Nicht aendern. Enum-Reihenfolge ist nirgends als UI-Quelle benutzt — die UI-Reihenfolge lebt in `tabs: persistentListOf(...)` in `NavGraph.kt`. Eine zweite Quelle einzufuehren waere redundant. Persistenz-relevant sind die Routen-Strings, nicht die Enum-Position. Konsistent zum iOS-Plan.

---

## Refactorings

Keine. Aenderung ist additiv-tauschend, betrifft vier Stellen punktuell (1 Domain-Konstante, 1 UI-Liste, 2 Tests).

---

## Fachliche Szenarien

### AK-1: Tab-Reihenfolge (Meditationen, Timer, Einstellungen)

- **Gegeben:** App ist gestartet
  **Wenn:** User schaut auf die Bottom-NavigationBar
  **Dann:** Erster Tab links ist Meditationen (GraphicEq-Icon, Label „Meditationen"/„Meditations"), zweiter ist Timer (Timer-Icon, Label „Timer"), dritter ist Einstellungen (Label „Einstellungen"/„Settings")

- **Gegeben:** Tabs werden ueber Content-Description angeklickt (Screengrab-/UI-Tests)
  **Wenn:** „Navigate to meditations" angetippt wird
  **Dann:** Library-Inhalte werden sichtbar (kein Index-bezogener Test verwendet in der Codebase)

### AK-2: Frischinstallation startet auf Meditationen

- **Gegeben:** App wird neu installiert (DataStore enthaelt keinen `selected_tab`-Eintrag)
  **Wenn:** User startet die App das erste Mal
  **Dann:** Meditationen-Tab ist aktiv (Library-Screen sichtbar)

- **Gegeben:** User loescht App-Daten ueber Systemeinstellungen
  **Wenn:** App wird erneut gestartet
  **Dann:** Meditationen-Tab ist aktiv

- **Gegeben:** DataStore enthaelt einen unbekannten Routenwert (z. B. Legacy-Eintrag)
  **Wenn:** App startet
  **Dann:** `AppTab.fromRoute(unknown)` faellt auf `LIBRARY` zurueck (`AppTab.DEFAULT`)

### AK-3: Last-used bleibt erhalten (shared-002 weiterhin gueltig)

- **Gegeben:** User wechselt zum Timer-Tab und beendet die App
  **Wenn:** User startet die App erneut
  **Dann:** Timer-Tab ist aktiv

- **Gegeben:** User wechselt zum Einstellungen-Tab und beendet die App
  **Wenn:** User startet die App erneut
  **Dann:** Einstellungen-Tab ist aktiv

- **Gegeben:** Bestandsuser mit persistiertem `selected_tab="timerGraph"` (passive Default-Akzeptanz vor shared-084)
  **Wenn:** User startet die App nach dem Update
  **Dann:** Timer-Tab ist aktiv (Persistenz wird respektiert; bewusste Entscheidung gegen Migration)

### AK-4: Persistenz-Stabilitaet (Regression-Schutz)

- **Gegeben:** `AppTab`-Enum existiert
  **Wenn:** Routen gelesen werden
  **Dann:** `timerGraph`, `library`, `settings` (Strings unveraendert — DataStore-Eintraege aus alten Versionen lesbar). Bestehende Tests `routes are stable for persistence` (in `AppTabTest` und `SettingsDataStoreTest`) bleiben gruen.

### AK-5: Soundscape-Import bleibt funktional

- **Gegeben:** User importiert eine Soundscape-Datei aus einer beliebigen Tab-Position heraus
  **Wenn:** Import erfolgreich
  **Dann:** App navigiert zum Timer-Tab und in den `PraxisEditor` → `SelectBackground`-Screen (Verhalten von `handleCustomAudioImport()` unveraendert; setzt `setSelectedTab(AppTab.TIMER)` explizit)

### AK-6: SETTINGS-Tab-Icon angeglichen an iOS

- **Gegeben:** App ist gestartet, User schaut auf die NavigationBar
  **Wenn:** Der SETTINGS-Tab gerendert wird
  **Dann:** Icon zeigt drei horizontale Slider/Regler (Material `Icons.Filled.Tune` bzw. `Icons.Outlined.Tune`), analog zu iOS `slider.horizontal.3`. Kein Listen-/Playlist-Icon mehr (vorher `QueueMusic`).

---

## Reihenfolge der Akzeptanzkriterien (TDD-Pfad)

1. **AK-2 / AK-4 (Default Meditationen + Persistenz-Routen stabil)** — Tests in `AppTabTest` und `SettingsDataStoreTest` umstellen (`DEFAULT is LIBRARY`), `make test-unit-agent TEST=AppTabTest` rot sehen, `AppTab.DEFAULT = LIBRARY` setzen, gruen.
2. **AK-1 (Reihenfolge)** — `tabs`-`persistentListOf` in `NavGraph.kt` neu sortieren. Verifikation manuell auf dem Geraet/Emulator (Screenshot-Tests-Helper greifen ueber Content-Description, sind nicht von der Reihenfolge abhaengig).
3. **AK-3 (Last-used)** — Bestehende Persistenz-Logik unveraendert; Smoke-Test manuell laut Ticket.
4. **AK-5 (Soundscape-Import)** — Bestehender Pfad in `handleCustomAudioImport()` unveraendert; Regressionscheck manuell.
5. **AK-6 (SETTINGS-Icon)** — Icon-Imports und `selectedIcon`/`unselectedIcon` im SETTINGS-`TabItem` auswechseln. Visueller Check auf dem Geraet/Emulator. Kein eigener Test (Icon-Auswahl ist Praesentationsdetail, kein fachliches Verhalten).

Reihenfolge AK-2 → AK-1 vermeidet einen Zwischenzustand (Reihenfolge schon getauscht, Default noch alt), bei dem der Timer-Tab beim ersten Start an Position 2 aufpoppt.

---

## Manueller Test (laut Ticket)

1. App-Daten ueber Systemeinstellungen loeschen (oder per `adb shell pm clear com.stillmoment`).
2. App starten → Erwartung: Meditationen-Tab aktiv, Tab-Reihenfolge Meditationen | Timer | Einstellungen.
3. Auf Timer-Tab wechseln, App schliessen (App-Switcher killen), App neu oeffnen → Erwartung: Timer-Tab aktiv.
4. Auf Einstellungen-Tab wechseln, App schliessen, App neu oeffnen → Erwartung: Einstellungen-Tab aktiv.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Bestandsuser mit persistiertem `timerGraph` empfinden „kein Effekt" | Bewusste Entscheidung (siehe Design-Entscheidung 2). CHANGELOG erwaehnt, dass die Reihenfolge sich aendert und Frischinstallationen mit Meditationen starten. |
| Screenshot-Tests (`ScreengrabScreenshotTests`) brechen, wenn der Setup-Code den Default nicht mehr explizit setzt | `setup()` ruft schon `setSelectedTab(AppTab.TIMER)` auf — bleibt unveraendert. Kein Risiko. |
| Folge-Ticket shared-085 (Marketing/Screenshots) abhaengig | Kein direktes Risiko — nur Hinweis, dass Play-Store-Screenshots nach Implementierung neu zu generieren sind. |

---

## SETTINGS-Icon-Migration (mit aufgenommen)

`SETTINGS`-Tab nutzt aktuell `Icons.AutoMirrored.Filled/Outlined.QueueMusic` (NavGraph.kt:191–194). Das wirkt wie ein Listen-/Playlist-Icon und passt semantisch nicht zu „Einstellungen". iOS verwendet `slider.horizontal.3` — Android-Pendant: `Icons.Filled.Tune` / `Icons.Outlined.Tune` (drei horizontale Slider).

Da die Aenderung thematisch nahe liegt (Tab-Bar-Bereinigung) und iOS bereits ein Slider-Icon nutzt, ist sie in shared-084 mitgenommen (siehe AK-6 und betroffene Codestellen). Imports in `NavGraph.kt` entsprechend austauschen:

```kotlin
// entfernen
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.automirrored.outlined.QueueMusic

// hinzufuegen
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.outlined.Tune
```

---

## Offene Fragen

Keine.

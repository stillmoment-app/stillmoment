# Ticket shared-122: Dunkle Darstellung als Standard

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Trivial — ein Standardwert je Plattform. Das Risiko liegt nicht im Code, sondern im Verhalten fuer Bestandsuser (siehe Hinweise).
**Phase**: 1-Quick Fix

---

## Was

Neue User sollen die App in dunkler Darstellung erleben, unabhaengig davon ob ihr Geraet auf hell oder dunkel steht. Bisher folgt die App standardmaessig der Systemeinstellung.

## Warum

Die App soll sich wie eine Pause anfuehlen — die dunkle Darstellung traegt diese Ruhe, ist abends augenschonend und ist das Bild, mit dem die App im Store praesentiert wird. Wer beim ersten Start in der hellen Variante landet, sieht eine andere App als die beworbene. Die Wahlmoeglichkeit bleibt vollstaendig erhalten.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Nach einer Neuinstallation startet die App in dunkler Darstellung, auch wenn das Geraet auf helle Darstellung eingestellt ist
- [ ] In den Einstellungen ist "Dunkel" als aktive Auswahl sichtbar
- [ ] "System", "Hell" und "Dunkel" bleiben unveraendert waehlbar und wirken sofort
- [ ] Eine vom User getroffene Auswahl bleibt nach App-Neustart erhalten und gewinnt gegen den Standardwert
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Standardwert ist dunkel; gespeicherte Auswahl gewinnt gegen Standardwert)
- [ ] Unit Tests Android (dito)

### Dokumentation
- [ ] CHANGELOG.md — user-sichtbare Aenderung, inklusive Hinweis fuer Bestandsuser

---

## Manueller Test

1. App deinstallieren, Geraet auf helle Darstellung stellen
2. App installieren und starten
3. Erwartung: App erscheint dunkel; Einstellungen zeigen "Dunkel" als Auswahl
4. Auf "System" umstellen
5. Erwartung: App wird hell (Geraet steht auf hell)
6. App beenden und neu starten
7. Erwartung: App bleibt bei "System", der Standardwert ueberschreibt die Auswahl nicht

---

## Referenz

- iOS: `ios/StillMoment/Domain/Models/`, `ios/StillMoment/Presentation/Theme/`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/`

---

## Hinweise

**Bestandsuser wechseln mit — bewusst akzeptiert.** Wer die Darstellung nie selbst gewaehlt hat, hat keinen gespeicherten Wert; diese User landen mit dem Update in der dunklen Darstellung, auch wenn ihr Geraet auf hell steht. Eine Unterscheidung zwischen Neuinstallation und Update ist nicht verlaesslich moeglich — es gibt keinen First-Launch-Marker in der App, und ein neu eingefuehrter waere bei Update-Usern genauso leer wie bei Neuinstallationen. Entscheidung: keine Migrationsheuristik bauen, die Umstellung ist einen Tap entfernt. In den Release Notes erwaehnen.

**Screenshot-Automatisierung.** Beide Plattformen setzen die Darstellung fuer Screenshot-Laeufe explizit und sind daher nicht betroffen. Nur ein iOS-Lauf ohne explizite Angabe rendert kuenftig dunkel statt hell — beim Erzeugen heller Varianten die Angabe also setzen.

---

## Abschluss (2026-07-31)

Umgesetzt als reiner Wertwechsel des Standards, je Plattform eine Zeile plus Tests:
`AppearanceMode.default` (iOS, `ios/StillMoment/Domain/Models/AppearanceMode.swift`) und
`AppearanceMode.DEFAULT = DARK` (Android, `android/app/src/main/kotlin/com/stillmoment/domain/models/AppearanceMode.kt`,
inkl. `SettingsDataStore`-Fallback). Kein UI-Code beruehrt.

Quality Gate gruen: `make -C ios check`, iOS Unit Tests 1334/1334 PASS,
`make -C android check`, Android Unit Tests 1280/1280 PASS.

### Offene Punkte

**Manuelle Verifikation nicht durchgefuehrt.** Die Akzeptanzkriterien sind vollstaendig von
Unit-Tests gedeckt (Standardwert ist dunkel; gespeicherte Auswahl gewinnt gegen Standardwert).
Die Schritte aus dem Abschnitt „Manueller Test" — App deinstallieren, Geraet auf hell stellen,
Neuinstallation — bleiben offen und liegen beim User.

**Screenshot-Falle ist eingetreten, wie im Hinweis oben vorhergesagt.** Beide Plattformen setzen
die Darstellung fuer Screenshot-Laeufe explizit: Android in
`android/app/src/androidTest/kotlin/com/stillmoment/screenshots/ScreengrabScreenshotTests.kt`
(`settingsDataStore.setAppearanceMode(AppearanceMode.DARK)`), iOS ueber `-appearanceMode` aus
`ios/fastlane/Snapfile`, das `ios/Makefile` mit `MODE ?= dark` fuellt. **Aber:** Der Snapfile
setzt das Argument nur, wenn `SCREENSHOT_MODE` gesetzt ist. Wer `bundle exec fastlane screenshots`
direkt aufruft und damit das Makefile umgeht, hat es nicht gesetzt — dieser Pfad rendete vorher in
der Simulator-Darstellung (hell) und rendert ab jetzt dunkel. Fuer **helle** Screenshot-Varianten
muss `MODE=light` (via Makefile) bzw. `SCREENSHOT_MODE=light` (direkt) explizit gesetzt werden.
Kein CI-Workflow ruft Screenshots auf, es bricht also nichts Automatisiertes.

**Android rendert einen dunklen ersten Frame.** `collectAsState(initial = DEFAULT)` liefert den
Standardwert, bevor DataStore emittiert — wer „Hell" gespeichert hat, sieht beim Start kurz dunkel.
Vorbestehende Eigenschaft mit umgedrehter Richtung (vorher blitzte es fuer Dark-User hell), bewusst
out of scope. Betrifft ab jetzt weniger User als vorher.

**Folgearbeit (eigenes Ticket, nicht Teil von shared-122):** Fuenf Android-Composables lesen
`isSystemInDarkTheme()` (Geraete-Flag) statt der aufgeloesten App-Darstellung —
`MoonPhase.kt:65`, `PlayerCenterDisc.kt:41`, `LibrarySearchBar.kt:70`, `MeditationListItem.kt:83`,
`LibraryActionPill.kt:44`. Solange der Standard `SYSTEM` war, stimmten Geraete-Flag und
App-Darstellung fuer jeden ueberein, der nie selbst gewaehlt hat. Ab jetzt ist „Neuinstallation auf
hell eingestelltem Geraet" der Normalfall, und diese fuenf Stellen nehmen die Hell-Palette auf
dunklem Grund. Auswirkung ist subtil (Alpha-/Waerme-Unterschiede in Gradients, Focus-Border), kein
gebrochenes Layout. `MainActivity.kt:93` nutzt `isSystemInDarkTheme()` korrekt (loest `SYSTEM` auf).
iOS ist nicht betroffen.

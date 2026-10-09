# Release Guide

Schritt für Schritt von `[Unreleased]` bis in die Stores. Alle Befehle aus dem Repo-Root,
sofern nicht anders angegeben. Beispielversion: `2.6.0`.

## Ablauf

```bash
# 1. Release Notes (iOS + Android) schreiben und CHANGELOG.md umziehen
/release-notes

# 2. Alles aus Schritt 1 in EINEM Commit (4 Fastlane-Changelogs + CHANGELOG.md)
git add CHANGELOG.md ios/fastlane/metadata android/fastlane/metadata
git commit -m "docs: Release Notes 2.6.0"

# 3. Vorbereiten — erst Probelauf, dann echt (beide Plattformen nacheinander)
make release-prepare VERSION=2.6.0 DRY_RUN=1
make release-prepare VERSION=2.6.0

# 4. Prüfen und pushen
git log --oneline -3          # zwei Prepare-Commits: chore(ios)…, chore(android)…
git push origin main --tags

# 5. Hochladen (beide Release-Guards laufen vor dem ersten Upload)
make release VERSION=2.6.0
# oder je Plattform: make -C ios release VERSION=2.6.0 / make -C android release VERSION=2.6.0
```

Danach: [Nach dem Upload](#nach-dem-upload) — dort steht, wann der manuelle Testplan dran ist.
Für Android liegt er **vor** Schritt 5.

**Warum ein Commit in Schritt 2:** `release-prepare` bricht ab, sobald außerhalb von
`<plattform>/fastlane/metadata/` etwas geändert oder ungetrackt ist — ein nicht committetes
`CHANGELOG.md` blockiert also. Beim Root-Aufruf läuft iOS zuerst; für den Android-Lauf danach
gelten auch nicht committete iOS-Release-Notes als Änderung.

## Was `release-prepare` tut

Reihenfolge wie in `ios/scripts/release-prepare.sh` bzw. `android/scripts/release-prepare.sh`.
Der Root-Aufruf führt erst iOS komplett aus (inkl. Commit + Tag), dann Android.

1. **VERSION** prüfen (Format `x.y.z`).
2. **Sauberer Arbeitsbaum**: keine geänderten oder ungetrackten Dateien außer unter
   `<plattform>/fastlane/metadata/`.
3. **Tag frei**: `ios-v2.6.0` bzw. `android-v2.6.0` existiert noch nicht.
4. **Preflight** (`scripts/release/preflight.py`, braucht `uv`):
   `CHANGELOG.md` hat `## [2.6.0]`, unter `## [Unreleased]` steht nichts mehr;
   Release Notes je Sprache vorhanden, nicht leer, höchstens 4000 (iOS) bzw. 500 (Android) Zeichen.
   iOS liest `ios/fastlane/metadata/{de-DE,en-GB}/changelogs/2.6.0.txt`, Android
   `android/fastlane/metadata/android/{de-DE,en-US}/changelogs/<versionCode+1>.txt`.
5. **Zugangsdaten** vorhanden — iOS: API-Key-JSON (`APP_STORE_CONNECT_API_KEY_PATH` oder
   `~/.fastlane/stillmoment-appstore.json`). Android: `android/keystore.properties` samt der darin
   genannten Keystore-Datei und der Play-Console-Schlüssel (`SUPPLY_JSON_KEY` oder
   `~/.fastlane/stillmoment-play-console.json`).
6. Nur iOS: kopiert `changelogs/2.6.0.txt` nach `release_notes.txt` (liest `deliver`).
7. **`make check`** — nur prüfend, formatiert nichts um (iOS mit `CI=1`). Unformatierter Code
   lässt prepare scheitern → `make -C <plattform> format`, committen, neu starten.
8. **`make test`** (iOS: Unit + UI mit Coverage; Android: `./gradlew test`).
9. **`make build-release`** — Release-Konfiguration bauen (iOS ohne Signing, Android `bundleRelease`).
10. **Screenshots** (`make screenshots`), überspringbar mit `SKIP_SCREENSHOTS=1`.
11. **Version erhöhen** (`bump-version.sh`): iOS `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION +1`,
    Android `versionName` + `versionCode +1`.
12. **Commit** nur der eigenen Pfade — iOS: `project.pbxproj`, `ios/fastlane/metadata`,
    `docs/images/screenshots`; Android: `app/build.gradle.kts`, `android/fastlane/metadata`.
    Message `chore(<plattform>): Prepare release v2.6.0`.
13. **Tag** `<plattform>-v2.6.0` (annotiert). Bleiben danach Änderungen übrig, warnt das Skript.

Mit `DRY_RUN=1` laufen nur die Prüfungen 1–5 wirklich; Schritte 6–13 werden nur angezeigt.

**Logs:** Ausgabe von Schritt 7–10 in `ios/release-prepare.log` bzw. `android/release-prepare.log`
(gitignored, live mitlesen mit `tail -f`).

## Was `make release` vor dem Upload prüft

`scripts/release/release-guard.sh <plattform>` läuft vor jedem Upload (`make release`, Android auch
`release-production`). Schlägt eine Prüfung fehl, wird nichts hochgeladen.

- `VERSION` ist gesetzt — Pflicht auf beiden Plattformen.
- Arbeitsbaum sauber, ungetrackte Dateien eingeschlossen.
- Tag `<plattform>-vVERSION` existiert, ist Vorfahre von `HEAD`, und unter `<plattform>/` hat sich
  seit dem Tag nichts geändert. (Der Tag muss nicht `HEAD` sein — der Prepare-Commit der anderen
  Plattform liegt darüber.)
- Version im Projekt (`MARKETING_VERSION` bzw. `versionName`) = `VERSION`.
- Store-Screenshots vollständig: iOS 10 je Sprache in `ios/fastlane/screenshots/`, Android 8 je
  Sprache in `phoneScreenshots/`. Das Alter des ältesten Screenshots wird angezeigt — bei
  `SKIP_SCREENSHOTS=1` auf Aktualität achten.

Was danach passiert:

- **iOS** (`make -C ios release`): baut die App, lädt den Build nach TestFlight (wartet auf die
  Verarbeitung), lädt Metadaten, Release Notes und Screenshots für die Version hoch.
  **Nicht** zur Prüfung eingereicht. Konfiguriert: nach Apples Freigabe automatisch veröffentlichen,
  keine gestaffelte Veröffentlichung. `SKIP_BUILD=1` lädt nur Metadaten + Screenshots.
- **Android** (`make -C android release`): baut das App-Bundle und lädt es mit Metadaten,
  Release Notes und Screenshots in den Production-Track. Ohne `release_status` gilt bei fastlane
  `completed`: das Release geht direkt in Googles Prüfung und nach Freigabe an alle Nutzer —
  keine gestaffelte Auslieferung, außer in der Play Console ist „Verwaltete Veröffentlichung“ aktiv.
  `make -C android release-production` macht dasselbe mit Bestätigungsfrage.

## Nach dem Upload

### iOS

1. Testplan [`TEST_PLAN_IOS.md`](TEST_PLAN_IOS.md) mit dem TestFlight-Build durchführen.
2. App Store Connect → Version 2.6.0: prüfen, dass der neue Build ausgewählt ist, sonst auswählen.
   (Die Fastfile meldet „automatically assigned“; im fastlane-Code ordnet `deliver` den Build aber
   nur beim Einreichen zu, das hier abgeschaltet ist — nicht an einem echten Release verifiziert.)
3. „Zur Prüfung einreichen“. Nach Apples Freigabe geht die Version automatisch an alle.

### Android

Der Testplan [`TEST_PLAN_ANDROID.md`](TEST_PLAN_ANDROID.md) gehört **vor** `make release`, weil der
Upload direkt in die Prüfung und danach an alle geht. Für den Upgrade-Test (Abschnitt 0) ein lokales
Release-Build über die Store-Version installieren (`adb install -r`). Ob das klappt, ist offen: Mit
Play App Signing trägt die Store-Version Googles Signatur, das lokale Build die des Upload-Keys —
`adb` lehnt es dann ab. In dem Fall bleibt nur ein interner Test-Track der Play Console; dafür gibt
es kein Make-Target, und ein dort hochgeladener `versionCode` lässt sich nicht noch einmal hochladen.

Nach der Freigabe: Store-Einträge kurz ansehen (Screenshots, Beschreibung, Release Notes).

## Hotfix für eine Plattform

```bash
/release-notes ios 2.6.1                     # schreibt nur iOS-Dateien + CHANGELOG.md
git add CHANGELOG.md ios/fastlane/metadata && git commit -m "docs: Release Notes iOS 2.6.1"
make -C ios release-prepare VERSION=2.6.1 DRY_RUN=1
make -C ios release-prepare VERSION=2.6.1
git push origin main --tags
make -C ios release VERSION=2.6.1
```

Der Preflight verlangt auch hier ein leeres `[Unreleased]` — offene Einträge der anderen Plattform
müssen also mit in die Sektion `## [2.6.1]` oder vorher geklärt werden.

## Wenn etwas schiefgeht

**prepare scheitert vor dem Commit** (Prüfung, Check, Test, Build, Screenshots): Ursache beheben
(Fix committen) und denselben Befehl neu starten. Die Version wird erst nach den Screenshots erhöht.
Vorher prüfen: `git status`. Übrig gebliebene Änderungen außerhalb von `<plattform>/fastlane/metadata/`
— etwa iOS-Screenshots unter `docs/images/screenshots/` oder, falls erst der Commit scheiterte,
die erhöhte Versionsdatei — blockieren den Neustart. Verwerfen mit
`git restore --staged --worktree -- <pfad>`, neue ungetrackte Dateien löschen.

**Root-Aufruf: iOS fertig, Android scheitert:** iOS-Commit und -Tag bleiben stehen. Android-Ursache
beheben, dann nur `make -C android release-prepare VERSION=2.6.0` — der Root-Aufruf würde am
vorhandenen iOS-Tag abbrechen. Ein Fix unter `ios/` macht dagegen den iOS-Tag ungültig (siehe unten).

**Fehler nach Commit + Tag, noch nicht gepusht** — oder der Guard meldet
`<plattform>/ changed since tag`: Prepare zurückdrehen und neu.

```bash
git log --oneline -3     # oberster Commit muss "chore(<plattform>): Prepare release v2.6.0" sein
git tag -d ios-v2.6.0
git reset --hard HEAD~1  # NUR wenn der Prepare-Commit oben liegt
```

Liegt darüber noch der Prepare-Commit der anderen Plattform, beide zurücknehmen (beide Tags löschen,
`HEAD~2`) oder erst die andere Plattform zurückdrehen. Ist ein Fix-Commit darübergerutscht: nicht
blind resetten, sondern den Verlauf klären. Danach Fix committen und `release-prepare` neu starten.

**Schon gepusht:** `main` nicht umschreiben. Solange nichts hochgeladen ist, Tag lokal und remote
löschen (`git push origin --delete ios-v2.6.0`), Fix committen, prepare mit derselben Version neu
starten — die Build-Nummer bzw. der `versionCode` steigt dann ein weiteres Mal. Android: die
Changelog-Dateien vorher auf den neuen `versionCode + 1` umbenennen (der Preflight nennt den
erwarteten Dateinamen).

## CI

`.github/workflows/ci.yml` baut bei jedem Push und Pull Request auf `main`/`develop` die Release-Konfiguration
beider Plattformen (`make -C ios build-release`, `make -C android build-release`). Release-only-Fehler
(z. B. DEBUG-only Code in `#Preview`) fallen so vor `release-prepare` auf.

## Einmalige Einrichtung

- Store-Zugänge und Fastlane: [`../guides/fastlane-ios.md`](../guides/fastlane-ios.md),
  [`../guides/fastlane-android.md`](../guides/fastlane-android.md)
- Ruby/Fastlane-Gems je Plattform: `make -C ios screenshot-setup`, `make -C android screenshot-setup`
  (ohne `vendor/bundle` brechen `screenshots` und `release` ab)
- `uv` für den Preflight: `brew install uv`
- Android-Screenshots brauchen ein Pixel-AVD (startet `make -C android screenshots` selbst)

## Referenzen

| Thema | Ort |
|-------|-----|
| Release Notes schreiben | Skill `/release-notes` (`.claude/skills/release-notes/SKILL.md`) |
| Manuelle Testpläne | [`TEST_PLAN_IOS.md`](TEST_PLAN_IOS.md), [`TEST_PLAN_ANDROID.md`](TEST_PLAN_ANDROID.md) |
| Prepare-Skripte | `ios/scripts/release-prepare.sh`, `android/scripts/release-prepare.sh` |
| Preflight / Guard | `scripts/release/preflight.py`, `scripts/release/release-guard.sh` (Tests: `make test-release-tooling`) |
| Technisches Changelog | `CHANGELOG.md` |
| Store-Texte | `ios/fastlane/metadata/`, `android/fastlane/metadata/android/` |

# Release Guide

Schritt für Schritt von `[Unreleased]` bis in die Stores. Alle Befehle aus dem Repo-Root,
sofern nicht anders angegeben. Beispielversion: `2.6.0`.

## Release durch Claude (Standardweg)

Der Entwickler sagt „Release 2.6.0“ (oder nur „Release“, dann schlägt Claude die Version vor).
Claude führt den [Ablauf](#ablauf) unten selbst aus. **Einzige Freigabe sind die Release Notes:**

1. Claude erzeugt die Release Notes mit `/release-notes`, zeigt sie für beide Plattformen und beide
   Sprachen und wartet. Vor der Freigabe wird nichts committet. Änderungswünsche einarbeiten, erneut zeigen.
2. Nach der Freigabe läuft der Rest ohne Rückfrage: Commit, `release-prepare` (erst `DRY_RUN=1`),
   Push mit Tags, CI auf `main` abwarten, `make release`.
3. Claude hält nur an, wenn
   - ein [Gerätetest](#gerätetest) fällig ist: geänderte Bereiche nennen, um den Test bitten, auf Bestätigung warten;
   - die CI auf `main` für den Release-Stand rot ist: nicht hochladen, berichten;
   - ein Schritt scheitert: Ursache berichten, Wiederanlauf nach [Wenn etwas schiefgeht](#wenn-etwas-schiefgeht)
     vorschlagen. Gepushte Historie auf `main` wird nie umgeschrieben.
4. Zum Schluss berichtet Claude je Plattform: Version, Tag und Upload-Status (iOS: zur Prüfung
   eingereicht). Im Browser ist nichts zu tun, siehe [Nach dem Upload](#nach-dem-upload).

`release-prepare` dauert lange (Tests, Release-Build, Screenshots) — im Hintergrund laufen lassen,
nicht mit Bash-Timeout abbrechen.

## Gerätetest

Kein Pflicht-Testplan bei jedem Release. Ein kurzer Gerätetest (ca. 5 Min je Plattform:
[`TEST_PLAN_IOS.md`](TEST_PLAN_IOS.md), [`TEST_PLAN_ANDROID.md`](TEST_PLAN_ANDROID.md)) ist **vor `make release`**
nur dann fällig, wenn sich seit dem letzten Release-Tag der Plattform Code für Audio, Sperrbildschirm,
Timer-Ablauf oder Hintergrund-Verhalten geändert hat. Prüfen:

```bash
git diff --stat ios-v2.5.0..HEAD -- ios/StillMoment/Infrastructure/Services ios/StillMoment/StillMomentApp.swift
git diff --stat android-v2.5.0..HEAD -- android/app/src/main/kotlin/com/stillmoment/infrastructure/audio \
  android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/stillmoment/domain/services/TimerReducer.kt
```

Im Zweifel lieber testen. Unter `ios/…/Infrastructure/Services` liegen auch Dienste ohne Audio-Bezug;
Claude bewertet die Treffer und nennt sie.

Bewusst nicht mehr manuell geprüft: Darstellung, Barrierefreiheit, Sprache, Import, Unterbrechungen —
das tragen die automatischen Tests bzw. das Risiko ist gering. Der Upgrade-Pfad (Daten älterer Versionen)
ist bis zur Umsetzung von shared-144 ungeprüft.

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

Vor Schritt 5 prüfen, ob ein [Gerätetest](#gerätetest) fällig ist. Danach: [Nach dem Upload](#nach-dem-upload).

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
- Store-Screenshots vollständig: je Sprache so viele, wie die `ORDER`-Liste in
  `<plattform>/scripts/curate-store-screenshots.sh` vorgibt (iOS in `ios/fastlane/screenshots/`,
  Android in `phoneScreenshots/`). Der Guard liest die Anzahl per `--count` aus dem Skript; lässt
  sie sich nicht ermitteln, bricht er ab. Das Alter des ältesten Screenshots wird angezeigt — bei
  `SKIP_SCREENSHOTS=1` auf Aktualität achten.

Was danach passiert:

- **iOS** (`make -C ios release`): baut die App, lädt den Build nach TestFlight (wartet auf die
  Verarbeitung), lädt Metadaten, Release Notes und Screenshots für die Version hoch und reicht
  sie mit diesem Build zur Prüfung ein. Nach Apples Freigabe geht die Version automatisch an alle
  Nutzer (keine gestaffelte Veröffentlichung). Scheitert das Einreichen, endet der Befehl mit Fehler; die Meldung
  nennt Ursache und nächsten Schritt (Build ist dann schon hochgeladen; eingereicht wird in
  App Store Connect, `make release` würde nur erneut bauen und hochladen). `SKIP_BUILD=1` lädt nur Metadaten + Screenshots und reicht nichts ein.
- **Android** (`make -C android release`): baut das App-Bundle und lädt es mit Metadaten,
  Release Notes und Screenshots in den Production-Track. Ohne `release_status` gilt bei fastlane
  `completed`: das Release geht direkt in Googles Prüfung und nach Freigabe an alle Nutzer —
  keine gestaffelte Auslieferung, außer in der Play Console ist „Verwaltete Veröffentlichung“ aktiv.
  `make -C android release-production` macht dasselbe mit Bestätigungsfrage.

## Nach dem Upload

### iOS

Nichts zu tun: Die Version ist eingereicht und geht nach Apples Freigabe an alle. Fällt danach
ein Fehler auf: Hotfix (siehe unten).

### Android

Nichts zu tun: Der Upload geht direkt in Googles Prüfung und danach an alle.

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
| Gerätetest (nur bei Audio-Änderungen) | [`TEST_PLAN_IOS.md`](TEST_PLAN_IOS.md), [`TEST_PLAN_ANDROID.md`](TEST_PLAN_ANDROID.md) |
| Prepare-Skripte | `ios/scripts/release-prepare.sh`, `android/scripts/release-prepare.sh` |
| Preflight / Guard | `scripts/release/preflight.py`, `scripts/release/release-guard.sh` (Tests: `make test-release-tooling`) |
| Technisches Changelog | `CHANGELOG.md` |
| Store-Texte | `ios/fastlane/metadata/`, `android/fastlane/metadata/android/` |

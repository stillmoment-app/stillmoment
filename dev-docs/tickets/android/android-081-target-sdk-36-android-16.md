# Ticket android-081: Target API Level 36 (Android 16) fuer Google Play

**Status**: [x] DONE
**Prioritaet**: KRITISCH
**Komplexitaet**: Der Bump selbst ist klein, das Risiko liegt in den Verhaltensaenderungen von Android 16 — vor allem darin, dass der feste Portrait-Modus auf grossen Displays nicht mehr greift. Verifikation braucht einen echten API-36-Emulator, Unit-Tests fangen davon nichts.
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Die Android-App muss auf Android 16 (API Level 36) zielen statt auf Android 15 (API 35), inklusive der dafuer noetigen Anpassungen an Android-16-Verhaltensaenderungen. Der bestehende Portrait-Only-Modus soll dabei erhalten bleiben.

Ausdruecklich **nicht** Teil dieses Tickets: adaptive Querformat-Layouts fuer Tablets und Foldables. Das ist ein eigenes Thema und braucht Entwurfsarbeit, nicht Termindruck.

## Warum

Google Play verlangt, dass der Target API Level nicht mehr als ein Jahr hinter dem aktuellen Android-Release liegt. Ab **31. August 2026** koennen wir mit API 35 kein App-Update mehr veroeffentlichen — auch keinen Bugfix. Die bereits veroeffentlichte App bleibt installierbar, aber wir waeren bis zur Umsetzung releaseunfaehig.

Google hat uns dazu am 31. Juli 2026 in der Play Console benachrichtigt. Es bleibt also rund ein Monat.

---

## Akzeptanzkriterien

### Feature
- [ ] Die App wird gegen Android 16 gebaut und zielt auf Android 16
- [ ] Ein signierter Release-Build laesst sich in der Play Console hochladen, ohne dass die Target-API-Warnung erscheint
- [ ] Die App bleibt im Hochformat — auch auf einem Tablet und einem aufgefalteten Foldable mit Android 16
- [ ] Zurueck-Navigation funktioniert unveraendert: Meditations-Editor mit Verwerfen-Schutz, Trim-Editor, Content-Guide
- [ ] Eine laufende Meditation und ein laufender Timer spielen auf Android 16 weiter, wenn das Display gesperrt wird; die Gongs kommen zur richtigen Zeit
- [ ] Datei-Import funktioniert auf Android 16: Auswahl aus dem Dateisystem, "Oeffnen mit" aus einer anderen App, "Teilen" einer Audiodatei und eines Links
- [ ] Die Anforderung von Google Play zur 16-KB-Speicherseitengroesse ist geprueft — erfuellt oder mit benanntem Handlungsbedarf dokumentiert

### Tests
- [ ] Bestehende Unit-Test-Suite ist gruen
- [ ] Bestehende Instrumented Tests laufen auf einem Android-16-Emulator gruen
- [ ] `make check` ist gruen

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `android/CLAUDE.md` — die dort dokumentierten SDK-Werte stimmen wieder

---

## Manueller Test

1. Android-16-Emulator starten (Telefon-Format), Release-Build installieren
2. Timer auf 1 Minute stellen, starten, Display sperren
3. Erwartung: Start-Gong, Intervall-Gong und End-Gong kommen bei gesperrtem Display
4. Eine gefuehrte Meditation importieren (aus einer anderen App via "Teilen"), abspielen, Display sperren
5. Erwartung: Wiedergabe laeuft weiter, Lock-Screen-Steuerung ist vorhanden und bedienbar
6. Meditations-Editor oeffnen, etwas aendern, mit der System-Zurueck-Gestensteuerung verlassen
7. Erwartung: Der Verwerfen-Schutz greift wie bisher
8. Tablet-Emulator mit Android 16 starten, App oeffnen, Geraet drehen
9. Erwartung: Die App bleibt im Hochformat

---

## Verifikation

Durchgefuehrt am 31.07.2026 beim Abschluss. `android/CLAUDE.md` und der Kommentar in `AndroidManifest.xml` verweisen fuer Hintergrund und Verifikation auf diesen Abschnitt — er ist die Quelle fuer den naechsten Pflicht-Bump (Target 37).

**Umgebung:** Emulator `Medium_Phone_API_36.1` (Android 16, `ro.build.version.sdk=36`), Debug-Build `com.stillmoment.dev`. On-Device bestaetigt: `targetSdk=36`.

**Portrait-Only auf grossem Display — mit Kontrollexperiment.** Das ist der wichtigste Beleg des Tickets. Auf dem Telefon-AVD wurde per `wm size 1600x2560` + `wm density 320` ein Display mit 800dp kleinster Breite simuliert und das Geraet ins Querformat gedreht:

| Property `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` | Activity-Config | Fenster |
|---|---|---|
| `true` | `sw600dp w600dp h800dp port` | Bounds 600×800dp zentriert, `letterboxReason=FIXED_ORIENTATION` |
| `false` | `sw800dp w1280dp h800dp land` | Vollbild 2560×1600, keine Letterbox |

Ohne den Gegenversuch waere das positive Ergebnis wertlos gewesen: Er unterscheidet „die Property wirkt" von „der Emulator erzwingt die neue Regel gar nicht". Die Display-Overrides wurden danach zurueckgesetzt.

**Lock-Screen-Gongs (per logcat).** Display aus 17:20:20.166 · Start-Gong 17:20:22.538 (2,4 s **nach** dem Sperren) · Intervall-Gongs 17:21:22.672 und 17:22:22.824 — exakt 60 s Abstand. Screen durchgehend `Asleep`, `TimerForegroundService isForeground=true types=0x2`.

**16-KB-Speicherseitengroesse: erfuellt, kein Handlungsbedarf.** Die Ticket-Annahme („kaeme ueber Media3 herein") war falsch — Media3/ExoPlayer liefert **keine** `.so`. Die tatsaechlichen Native-Libs im Release-AAB sind `libandroidx.graphics.path.so` und `libdatastore_shared_counter.so`; alle vier 64-Bit-Varianten (arm64-v8a, x86_64) haben jedes LOAD-Segment auf `align 2**14`.

**Datei-Import auf Android 16 — alle vier Pfade verifiziert:**
- Filesystem-Picker (SAF): end-to-end inkl. Import
- „Oeffnen mit" (VIEW-Intent): `content://media/external/audio/media/47` ueber die System-ResolverActivity, Import-Sheet mit Metadaten und Dauer 15:42, Import vollstaendig durchgefuehrt und in der Bibliothek erschienen
- „Teilen" einer Audiodatei (SEND + `EXTRA_STREAM`): Share-Sheet, Import-Sheet 12:17, Abbrechen persistiert korrekt nichts
- „Teilen" eines Links (SEND + `EXTRA_TEXT`): ohne Link → Dialog „Kein Link gefunden"; mit Audio-URL → Download 103070 Bytes, Redirect korrekt gefolgt, Import-Sheet

Einschraenkung: end-to-end nur mit `audio/mpeg` geprueft; `audio/mp4` und `audio/x-m4a` nur auf Manifest-/Resolver-Ebene.

**Zurueck-Navigation mit vorhersagbaren Zurueck-Gesten (ab Target 36 default-on).** Meditations-Editor: Name geaendert, System-Zurueck-Geste → Dialog „Aenderungen verwerfen?" mit „Verwerfen" / „Weiter bearbeiten" erscheint wie bisher. Content-Guide ebenfalls geprueft. Im Code gibt es keinen `onBackPressed()`-Override; alle drei Stellen nutzen `androidx.activity.compose.BackHandler`. Der Trim-Editor wurde nicht direkt durchgetippt — er nutzt denselben `BackHandler`-Mechanismus wie der verifizierte Editor.

**Unit-Tests / Lint / Release-Build:** `make -C android check` gruen (0 Lint-Errors), `make -C android test-unit-agent` 1276/1276 PASS, `bundleRelease` erfolgreich (signiertes AAB, 28 MB).

**Instrumented Tests — Akzeptanzkriterium NICHT erfuellt.** Auf API 36 warf zunaechst *jeder* Test `NoSuchMethodException: android.hardware.input.InputManager.getInstance` in `Espresso.onIdle`. Ein Kontrolllauf mit targetSdk 35 auf demselben Emulator zeigte den identischen Fehler → Ursache war Emulator/Espresso, nicht der Bump. Espresso 3.7.0 behebt das („Use getSystemService instead of reflective InputManager.getInstance"): 19 von 36 Tests laufen jetzt. Die restlichen 17 scheitern an `assertIsDisplayed` plus einer `ComposeNotIdleException` (bekannte PlayerScreen-Endlos-Rekomposition). Laeufe mit targetSdk 35 und 36 (beide mit Espresso 3.7.0) ergaben **identische** Fehler-Mengen → die 17 Failures sind vorbestehend auf Android 16 und unabhaengig vom Target-SDK. Das Akzeptanzkriterium „Bestehende Instrumented Tests laufen auf einem Android-16-Emulator gruen" ist damit **offen** und braucht ein eigenes Ticket.

---

## Offene Punkte beim Abschluss

- **`versionCode` steht weiter auf 19** und ist auf Google Play bereits verbraucht. Er muss vor dem echten Upload gebumpt werden. Deshalb konnte `supply validate_only` die Target-API-Pruefung nicht erreichen — es brach vorher mit „Version code 19 has already been used" ab. Das AK „Upload ohne Target-API-Warnung" ist damit **nicht** vollstaendig belegt; eine Target-SDK-Beanstandung gab es aber auch nicht. Der Play-Console-Upload bleibt Aufgabe des Users.
- **17 vorbestehende Instrumented-Test-Failures auf Android 16** (siehe Verifikation) — eigenes Ticket noetig.
- **Kein echtes Tablet/Foldable getestet**, nur ein simuliertes 800dp-Display auf einem Telefon-AVD. Das Signal ist stark (Letterboxing auf Framework-Ebene, per Gegenversuch bestaetigt), eine Bestaetigung auf einem echten Tablet-AVD bleibt wuenschenswert.
- **CI ist mit `compileSdk 36` noch nie gelaufen** (Branch hat kein Upstream). Der Android-CI-Job pinnt keine SDK-Platform explizit.
- **Der Opt-out `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` wirkt nur bis Target 36** — ab Target 37 entfaellt die Moeglichkeit, und der naechste Pflicht-Bump braucht echte adaptive Querformat-Layouts. Bewusst nicht Teil dieses Tickets; dokumentiert im Manifest-Kommentar, in `android/CLAUDE.md` und im CHANGELOG.

---

## Referenz

- shared-012 — Portrait-Only-Modus, die bewusste Produktentscheidung, die hier verteidigt wird
- shared-045 / shared-046 — File Association und Share-Import, die auf Android 16 nachzuprueben sind
- shared-080 — Danke-Screen ueberlebt App-Termination; Android 16 erzeugt bei Konfigurationsaenderungen haeufiger Neuerstellungen
- Doku: [Behavior changes: Apps targeting Android 16](https://developer.android.com/about/versions/16/behavior-changes-16)

---

## Hinweise

**Portrait-Only auf grossen Displays:** Ab Target API 36 ignoriert Android die Orientierungs- und Groessenbeschraenkungen einer Activity auf Displays ab 600dp Breite. Es gibt dafuer einen offiziellen, temporaeren Opt-out ueber die Manifest-Property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`. Der greift bei Target API 36 noch, bei 37 nicht mehr — wir kaufen damit Zeit, keine Loesung. Wichtig, das im Ticket-Abschluss so zu vermerken, damit beim naechsten Pflicht-Bump niemand ueberrascht ist.

**Was uns nicht betrifft:** Der Edge-to-Edge-Zwang kam bereits mit Target API 35 und ist erledigt. Die neuen Health-Permissions, die Local-Network-Permission und die Bluetooth-Aenderungen beruehren die App nicht.

**Vorhersagbare Zurueck-Gesten** sind ab Target API 36 standardmaessig aktiv. Die App nutzt nirgends die alte Zurueck-Behandlung, funktional ist damit nichts zu erwarten. Was fehlt, ist die Wisch-Vorschau-Animation an den drei Stellen mit eigener Zurueck-Behandlung (Editor, Trim-Editor, Content-Guide) — kosmetisch, und nur anfassen, wenn es ohne Risiko geht. Sonst eigenes Ticket.

**16-KB-Speicherseitengroesse** ist eine separate Play-Anforderung, kein Teil der Target-API-Regel — schlaegt aber beim selben Upload zu. Betrifft nur native Bibliotheken, bei uns kaeme sie ueber Media3 herein.

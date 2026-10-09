# Implementierungsplan: shared-134 (Android)

Ticket: shared-134
Erstellt: 2026-10-09

## Annahmen

- **Platzierung:** Info-Bereich (`InfoLegalSection`), Reihenfolge Klänge → Datenschutz → **App bewerten** → **Schreib uns** (mit Untertitel) → Version. Gesetzte UX-Entscheidung, identisch auf iOS.
- **Package-Name fest `com.stillmoment`.** Debug hat `applicationIdSuffix = ".dev"` (`android/app/build.gradle.kts:64`), `BuildConfig.APPLICATION_ID` wäre dort `com.stillmoment.dev` und führte ins Leere. Deshalb Konstante im Domain-Modell, nicht `BuildConfig`.
- **Mail-Text** = `"\n\n" + "Still Moment <versionName> (<versionCode>) · Android <Build.VERSION.RELEASE>"`. Debug-Builds liefern `versionName` mit Suffix `-dev` (z. B. `2.5.0-dev`). Das wird bewusst nicht bereinigt, ist sogar hilfreich.
- **Betreff `Still Moment`**: Markenname, nicht lokalisiert, also Konstante im Domain-Modell statt in `strings.xml`.
- **EN-Großschreibung:** Bestehende EN-Zeilentitel im Info-Bereich sind Title Case („Sound Attributions", „Privacy Policy"). Daher „Rate the App", „Write to Us". Untertitel als Satz: „Say hello, say thanks, share feedback". Dialogtitel: Title Case wie „Delete Meditation" → „No Mail App Found". Der Button „Copy Address" ist Title Case wie die gesetzte Vorgabe. (Hinweis: Die EN-Dialogtitel im Projekt sind gemischt, z. B. „Download failed". Title Case wurde hier gewählt, weil es die gesetzte Vorgabe ist.)
- **Accessibility auf Android:** Für die Zeile sagt TalkBack den sichtbaren Text vor, der über `clickable` zusammengeführt wird. „Schreib uns" liest so auch den Untertitel mit. Kein eigenes `contentDescription`, damit Untertitel nicht verloren gehen. Den Hinweis liefert `clickable(onClickLabel = …)`. TalkBack sagt dann „Doppeltippen, um <Label>". Darum steht das Label im Infinitiv: „Google Play öffnen" / „open Google Play" und „Mail-Programm öffnen" / „open your mail app". Inhaltlich entspricht das der Vorgabe („Öffnet Google Play"), sprachlich passt es zur TalkBack-Formel und zu den bestehenden Strings („Datenschutzerklärung öffnen").
- **Kopier-Rückmeldung:** Ab Android 13 zeigt das System selbst eine Kopier-Bestätigung. Bis einschließlich 12L (API 32) empfiehlt Google einen eigenen Toast. Plan: Toast „Adresse kopiert" / „Address copied" nur bei `SDK_INT <= S_V2`, danach schließt der Dialog. (Ein neuer String, siehe Offene Fragen.)
- **Kein `<queries>` im Manifest, kein `resolveActivity`.** Ein Intent wird gestartet und `ActivityNotFoundException` abgefangen, wie es die offizielle Doku zur Package Visibility empfiehlt.
- **Keine neue Abhängigkeit, keine In-App-Review-Library.** Für das Kopieren wird `LocalClipboardManager` genutzt. Bei Compose BOM 2024.12.01 (UI 1.7.x) ist es noch nicht deprecated, das suspend-basierte `LocalClipboard` kommt erst mit 1.8.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `android/app/src/main/kotlin/com/stillmoment/domain/models/FeedbackLinks.kt` | Domain | Neu | Reines Kotlin-`object`: `MAIL_ADDRESS`, `MAIL_SUBJECT`, `STORE_URI` (`market://details?id=com.stillmoment`), `STORE_WEB_URL` (`https://play.google.com/store/apps/details?id=com.stillmoment`), `mailBody(appVersion, buildNumber, osVersion)`, `mailtoUri(appVersion, buildNumber, osVersion)` (RFC 6068, prozentkodiert) |
| `android/app/src/test/kotlin/com/stillmoment/domain/models/FeedbackLinksTest.kt` | Test | Neu | Fachliche Tests für Body, mailto-Kodierung und Store-Adressen |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/settings/FeedbackRows.kt` | Presentation | Neu | `RateAppRow`, `WriteToUsRow` (Titel + Untertitel), `NoMailAppDialog`, sowie die Intent-Helfer `Context.openStoreListing()` und `Context.composeFeedbackMail(): Boolean` (false = keine App gefunden) |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/settings/AppSettingsScreen.kt` | Presentation | Erweitern | `InfoLegalSection`: neue Zeilen einfügen, Dialog-State (`remember { mutableStateOf(false) }`). Die viermal wiederholten Divider werden in eine private Hilfsfunktion `InfoRowDivider()` gezogen, damit LongMethod (60) hält |
| `android/app/src/main/res/values/strings.xml` | Ressourcen | Erweitern | Neue Keys (siehe Lokalisierung) |
| `android/app/src/main/res/values-de/strings.xml` | Ressourcen | Erweitern | dto. |
| `ios/StillMoment/Presentation/Views/AppSettings/AppSettingsView.swift` | — | Nur gelesen | Referenz. Info-Section: `NavigationLink` Klänge, `Link` Datenschutz mit `accessibilityHint`, HStack Version. iOS nutzt Hint-Strings `accessibility.appSettings.*.hint` |

Bestehendes Muster der Datenschutz-Zeile (`AppSettingsScreen.kt:181-186`): `LocalContext.current` in `InfoLegalSection`, dann `context.startActivity(Intent(ACTION_VIEW, Uri.parse(PRIVACY_URL)))` im `onClick`, **ohne** Fehlerbehandlung. Die neuen Zeilen übernehmen das Muster (Context aus der Section, Intent in Presentation) und fangen zusätzlich `ActivityNotFoundException` ab. Die Datenschutz-Zeile selbst bleibt unverändert (nicht Teil des Tickets).

### Lokalisierung (neue Keys, Präfix wie Bestand)

| Key | EN | DE |
|-----|----|----|
| `app_settings_rate_app` | Rate the App | App bewerten |
| `accessibility_app_settings_rate_app_action` | open Google Play | Google Play öffnen |
| `app_settings_write_to_us` | Write to Us | Schreib uns |
| `app_settings_write_to_us_subtitle` | Say hello, say thanks, share feedback | Hallo sagen, danke sagen, Feedback geben |
| `accessibility_app_settings_write_to_us_action` | open your mail app | Mail-Programm öffnen |
| `app_settings_no_mail_app_title` | No Mail App Found | Kein Mail-Programm gefunden |
| `app_settings_no_mail_app_message` | You can reach us at %1$s | Du erreichst uns unter %1$s |
| `app_settings_copy_address` | Copy Address | Adresse kopieren |
| `app_settings_address_copied` | Address copied | Adresse kopiert |
| (bestehend) `common_ok` | OK | OK |

Die Adresse kommt als Format-Argument aus `FeedbackLinks.MAIL_ADDRESS` (`stringResource(R.string.app_settings_no_mail_app_message, FeedbackLinks.MAIL_ADDRESS)`), keine String-Interpolation.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Intent.ACTION_SENDTO` + `mailto:` | API 1 | [Common intents – Email](https://developer.android.com/guide/components/intents-common) | Offizielles Muster: `data = Uri.parse("mailto:")`, dazu `EXTRA_EMAIL` (Array), `EXTRA_SUBJECT`, `EXTRA_TEXT`. Mit `mailto:` antworten nur Mail-Apps |
| Subject/Body bei SENDTO | — | [K-9 Commit](https://code.moparisthebest.com/moparisthebest/k-9/commit/dc476eb3e8a4f7539e5f281bbbe76b8f11ccefc2), [B4X-Thread Gmail](https://www.b4x.com/android/forum/threads/intent-sendto-dont-work-correctly-with-gmail-app.114685/) | Die Extras bei SENDTO sind historisch nicht formal spezifiziert. Gmail hat Extras zeitweise ignoriert, andere Clients lesen nur Extras. **Entscheidung: doppelt** – Empfänger, `subject` und `body` in die mailto-URI (RFC 6068) **und** zusätzlich als Extras. Muss am Gerät mit Gmail und einem zweiten Client geprüft werden |
| `ActivityNotFoundException` statt `resolveActivity` | Android 11+ relevant | [Package visibility use cases](https://developer.android.com/training/package-visibility/use-cases) | „the most straightforward approach is to invoke the intent and handle the ActivityNotFoundException". Ohne `<queries>` ist `resolveActivity` ab API 30 unzuverlässig. Für das Starten selbst ist keine Package Visibility nötig |
| `market://details?id=` → Fallback `https://play.google.com/store/apps/details?id=` | — | Ticket / Play-Linking | Zuerst `market://` probieren, bei `ActivityNotFoundException` die https-URL. Scheitert auch die (Gerät ohne Browser), wird das abgefangen und nichts weiter getan |
| `LocalClipboardManager.setText(AnnotatedString)` | Compose UI 1.0+ | Compose BOM 2024.12.01 | In UI 1.7 nicht deprecated |
| Kopier-Rückmeldung | API 33 System, ≤ 32 selbst | [Copy and paste](https://developer.android.com/develop/ui/views/touch-and-input/copy-paste) | „In Android 12L (API level 32) and lower, we recommend alerting users … Toast or Snackbar". Ab 13 keinen eigenen Toast zeigen (Duplikat) |
| `BuildConfig.VERSION_NAME`, `BuildConfig.VERSION_CODE`, `Build.VERSION.RELEASE` | — | — | `buildConfig = true` ist bereits aktiv. `RELEASE` liefert z. B. „15" |

## Design-Entscheidungen

### 1. Fachlogik im Domain-Objekt `FeedbackLinks`, Intents in Presentation

**Trade-off:** `android.net.Uri` und `Intent` lassen sich in Unit-Tests nicht nutzen (kein Robolectric, `isReturnDefaultValues = true` liefert `null`). Ein Repository- oder Service-Protokoll wäre für zwei Intents Overengineering.
**Entscheidung:** Ein pures Kotlin-`object` in `domain/models` erzeugt alle Adressen und Texte als `String`. Die Prozentkodierung übernimmt `java.net.URLEncoder.encode(s, UTF_8).replace("+", "%20")`. `java.*` wird im Domain-Layer schon genutzt, ist also keine Android-Abhängigkeit. Die Composable-Schicht macht daraus nur `Uri.parse(...)` und startet das Intent, analog zur Datenschutz-Zeile. Kein ViewModel nötig, weil es keinen Zustand außer dem Dialog-Flag gibt.
Der Name `FeedbackLinks` sollte mit iOS abgestimmt werden (gleicher Name auf beiden Plattformen, siehe Offene Fragen).

### 2. Mail-Intent: URI-Query plus Extras

**Entscheidung:** `Intent(ACTION_SENDTO, Uri.parse(FeedbackLinks.mailtoUri(...)))` plus `EXTRA_EMAIL = arrayOf(MAIL_ADDRESS)`, `EXTRA_SUBJECT`, `EXTRA_TEXT`. So kommen Betreff und Text an, egal welchen Weg der Client liest. Risiko eines doppelt eingefügten Textes: am Gerät prüfen (Manueller Test).

### 3. Kein Mail-Programm → Dialog

`composeFeedbackMail()` gibt `false` zurück, wenn `ActivityNotFoundException` fliegt. Dann setzt `InfoLegalSection` `showNoMailDialog = true`. Der Dialog ist ein `AlertDialog` (Muster `LinkImportErrorDialogs.kt`):
- `confirmButton` = „Adresse kopieren": kopiert in die Zwischenablage, zeigt bei API ≤ 32 einen Toast und schließt den Dialog.
- `dismissButton` = „OK": schließt den Dialog.

Der catch-Parameter heißt `ignored` (detekt `SwallowedException` / `allowedExceptionNameRegex: "_|(ignore|expected).*"`).

### 4. Zeilen-Layout

`RateAppRow` wie `PrivacyPolicyRow` (body-Text + Chevron). `WriteToUsRow`: `Column(weight 1f)` mit Titel (`TextStyle.body`, `onSurface`) und Untertitel (`TextStyle.caption`, `onSurfaceVariant`, Hierarchie über Farbe), dazu ein Chevron. Jede Zeile ist ein eigenes Composable mit genau einem Root-Emitter (`Row`), damit MultipleEmitters nicht greift. Der Dialog wird innerhalb der äußeren `Column` von `InfoLegalSection` emittiert.

## Refactorings

1. **`InfoRowDivider()` extrahieren** in `AppSettingsScreen.kt`. Ohne das wächst `InfoLegalSection` von ~45 auf über 60 Zeilen (zwei Zeilen, zwei Divider, Dialog-State, Dialog). Rein mechanisch, kein Verhaltenswechsel. Risiko: niedrig.
   - Falls `InfoLegalSection` trotzdem knapp wird, auch die Callbacks für Store/Mail in die neuen Zeilen verlagern: `RateAppRow` holt `LocalContext` selbst, `WriteToUsRow` bekommt nur `onNoMailApp`.

## Fachliche Szenarien

### AK-1: Info-Bereich zeigt die neuen Einträge

- Gegeben: Einstellungen geöffnet
  Wenn: Person scrollt zum Info-Bereich
  Dann: Reihenfolge Klang-Nachweise, Datenschutz, App bewerten, Schreib uns (mit Untertitel „Hallo sagen, danke sagen, Feedback geben"), Version

### AK-2/3: App bewerten

- Gegeben: Google Play installiert
  Wenn: Person tippt „App bewerten"
  Dann: Google Play öffnet die Seite von Still Moment (auch im Debug-Build `com.stillmoment`, nicht `.dev`)
- Gegeben: Keine Play-Store-App vorhanden
  Wenn: Person tippt „App bewerten"
  Dann: Browser öffnet `https://play.google.com/store/apps/details?id=com.stillmoment`
- Unit: Die Store-Adresse ist `market://details?id=com.stillmoment`, die Ausweich-Adresse ist die https-Seite mit derselben ID

### AK-4/5: Schreib uns

- Gegeben: Gmail eingerichtet, App 2.5.0 (20) auf Android 15
  Wenn: Person tippt „Schreib uns"
  Dann: Neue Mail an `hello@stillmoment.app`, Betreff „Still Moment", Text: zwei Leerzeilen, dann `Still Moment 2.5.0 (20) · Android 15`. Alles editier- und löschbar
- Unit: Der Text endet genau mit `Still Moment 2.5.0 (20) · Android 15` und beginnt mit zwei Zeilenumbrüchen
- Unit: Die mailto-Adresse richtet sich an `hello@stillmoment.app` und enthält Betreff und Text so kodiert, dass Leerzeichen als `%20` (nicht `+`), Zeilenumbrüche als `%0A` und „·" UTF-8-kodiert ankommen. Test fachlich formuliert: Dekodieren ergibt wieder exakt Betreff und Text
- Unit: Eine Version mit Sonderzeichen (z. B. `2.5.0-dev`) bleibt nach dem Dekodieren unverändert

### AK-6: Kein Mail-Programm

- Gegeben: Keine App verarbeitet `mailto:` (z. B. Emulator ohne Gmail oder `pm disable-user com.google.android.gm`)
  Wenn: Person tippt „Schreib uns"
  Dann: Dialog „Kein Mail-Programm gefunden", Text „Du erreichst uns unter hello@stillmoment.app", Buttons „Adresse kopieren" und „OK"
- Gegeben: Dialog offen
  Wenn: Person tippt „Adresse kopieren"
  Dann: Adresse liegt in der Zwischenablage. Ab Android 13 kommt die System-Bestätigung, auf ≤ 12L ein Toast „Adresse kopiert". Der Dialog schließt
- Gegeben: Dialog offen
  Wenn: Person tippt „OK" oder außerhalb
  Dann: Dialog schließt, nichts wird kopiert

### AK-7: Keine automatische Bewertungsanfrage

- Kein Code-Pfad außer dem Tippen löst Store oder Review aus. Keine `com.google.android.play:review`-Abhängigkeit (Review des Diffs und von `libs.versions.toml`)

### AK-8: Accessibility

- Gegeben: TalkBack aktiv
  Wenn: Fokus auf „App bewerten"
  Dann: „App bewerten, Doppeltippen, um Google Play zu öffnen" (sinngemäß, Formel des Systems)
- Gegeben: TalkBack aktiv
  Wenn: Fokus auf „Schreib uns"
  Dann: Titel und Untertitel werden vorgelesen, der Hinweis sagt „Mail-Programm öffnen"

### AK-9: Bestand bleibt

- Klang-Nachweise navigiert weiter, Datenschutz öffnet weiter die Website, die Version zeigt weiter `VERSION_NAME`

## Reihenfolge der Akzeptanzkriterien

1. **AK-4/5 + AK-2/3 (Domain):** `FeedbackLinksTest` RED, dann `FeedbackLinks` GREEN (Body, mailto-Kodierung, Store-Adressen)
2. **Strings DE/EN** anlegen
3. **AK-1, AK-8 (UI):** `InfoRowDivider` extrahieren, dann `RateAppRow` und `WriteToUsRow` in `FeedbackRows.kt` und in `InfoLegalSection` einhängen
4. **AK-2/3, AK-4/5 (Intents):** `openStoreListing()` mit Fallback, `composeFeedbackMail()` mit URI und Extras
5. **AK-6:** `NoMailAppDialog` + Clipboard + Toast (≤ API 32)
6. `make check` (detekt: LongMethod, MultipleEmitters, SwallowedException, TooManyFunctions), `make test-unit-agent`
7. **Manueller Test** am Gerät: Gmail plus ein zweiter Mail-Client (z. B. K-9/Thunderbird oder Samsung Mail). Dabei prüfen, ob Betreff und Text genau einmal erscheinen. Danach Gmail deaktivieren und den Dialog prüfen. Play-Store-Fallback mit deaktiviertem Play Store prüfen

UI-Tests (androidTest) sind nicht geplant. `AppSettingsScreen` hat bisher keine, und der Intent-Start lässt sich ohne zusätzliche Abstraktion nicht sinnvoll prüfen. Die Fachlogik ist über Unit-Tests abgedeckt, der Rest über den manuellen Test.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Mail-Client übernimmt Betreff/Text nicht oder doppelt | URI-Query und Extras zugleich. Manueller Test mit Gmail und einem zweiten Client. Bei Duplikat Extras für Betreff und Text weglassen und nur `EXTRA_EMAIL` behalten |
| Gmail ohne eingerichtetes Konto fängt mailto ab (kein Dialog, sondern Konto-Einrichtung) | Akzeptabel: Tippen bleibt nicht ohne Reaktion. Der Dialog greift nur, wenn gar keine Mail-App installiert ist |
| detekt LongMethod in `InfoLegalSection` | Divider-Extraktion, Zeilen holen sich Context selbst |
| Debug-Build öffnet falsche Store-Seite | Feste Package-Konstante, Unit-Test prüft `com.stillmoment` |

## Offene Fragen

- [ ] **Name des Domain-Modells mit iOS abstimmen** (Vorschlag `FeedbackLinks`). Gleiche Fachbegriffe auf beiden Plattformen. Gegebenenfalls Glossar-Eintrag.
- [ ] **Toast „Adresse kopiert" auf Android ≤ 12L:** neuer String, über die gesetzten UX-Entscheidungen hinaus, aber von Google empfohlen. Alternative: kein eigener Hinweis, nur der Dialog schließt. iOS hat keine System-Bestätigung. Soll iOS eine eigene Rückmeldung zeigen, oder bleibt es dort beim Schließen des Dialogs?
- [ ] **Accessibility-Hinweis-Wortlaut:** Android nutzt den Infinitiv („Google Play öffnen", „Mail-Programm öffnen") wegen der TalkBack-Formel „Doppeltippen, um …", iOS die Form „Öffnet Google Play". Inhaltlich gleich, sprachlich plattformgerecht. Bitte bestätigen.

## Entscheidungen zu den offenen Fragen (2026-10-09)

- **Name:** `FeedbackLinks` auf beiden Plattformen (iOS: `enum FeedbackLinks`, Android: `object FeedbackLinks`).
- **Toast „Adresse kopiert“ auf Android ≤ 12L:** ja, wie von Google empfohlen. iOS bekommt keine eigene Bestätigung, der Dialog schließt einfach. Das ist ein bewusster Plattformunterschied.
- **Accessibility-Hinweise:** Android im Infinitiv („Google Play öffnen“, „Mail-Programm öffnen“), iOS „Öffnet …“. Bestätigt.

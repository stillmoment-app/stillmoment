# Implementierungsplan: shared-134 (iOS)

Ticket: shared-134
Erstellt: 2026-10-09

## Annahmen

Gesetzte UX-Entscheidungen (gelten für iOS und Android gleich):

- **Platzierung:** Info-Bereich (`AppSettingsView.infoSection`), Reihenfolge: Klang-Nachweise, Datenschutz, **App bewerten**, **Schreib uns** (mit Untertitel), Version.
- **Texte:**

  | Key | DE | EN |
  |-----|----|----|
  | `app.settings.rateApp.title` | App bewerten | Rate the App |
  | `app.settings.writeToUs.title` | Schreib uns | Write to Us |
  | `app.settings.writeToUs.subtitle` | Hallo sagen, danke sagen, Feedback geben | Say hello, say thanks, share feedback |
  | `accessibility.appSettings.rateApp.hint` | Öffnet den App Store | Opens the App Store |
  | `accessibility.appSettings.writeToUs.hint` | Öffnet dein Mail-Programm | Opens your mail app |
  | `app.settings.writeToUs.noMailApp.title` | Kein Mail-Programm gefunden | No Mail App Found |
  | `app.settings.writeToUs.noMailApp.message` | Du erreichst uns unter %@ | You can reach us at %@ |
  | `app.settings.writeToUs.noMailApp.copy` | Adresse kopieren | Copy Address |
  | (OK-Button) | `common.ok` (existiert) | `common.ok` |

  **EN-Großschreibung geprüft:** Die bestehenden EN-Einträge im Settings-Tab verwenden Title Case („Privacy Policy“, „Sound Attributions“, „Guided Meditations“, „Info & Legal“). „Rate the App“ und „Write to Us“ passen dazu und bleiben so. Untertitel, Hinweise und Dialogtext stehen im Satzstil (wie `settings.preparationTime.subtitle.on`, `accessibility.appSettings.privacy.hint`). Der Dialogtitel „No Mail App Found“ steht wie andere Alert-Titel in Title Case.
- **Store-Adresse:** `https://apps.apple.com/app/id6755774465?action=write-review`. Kein StoreKit und kein `requestReview`. Ein Grep zeigt heute in `ios/StillMoment` und `android/app/src/main` keinen Treffer für `StoreKit|requestReview`, das bleibt so.
- **Mail:** Empfänger `hello@stillmoment.app`, Betreff `Still Moment` (Markenname, nicht lokalisiert). Text: zwei Leerzeilen, dann `Still Moment <Version> (<Build>) · iOS <OS-Version>`, z. B. `Still Moment 2.5.0 (11) · iOS 18.4`.
- **Zeilenumbruch im Text:** `\r\n` (CRLF) nach RFC 6068 („line breaks in the body … MUST be encoded with %0D%0A“). Text also `"\r\n\r\nStill Moment …"`. `URLComponents` kodiert das automatisch zu `%0D%0A`.
- **Datenquellen:** Version kommt aus `CFBundleShortVersionString` (wie die bestehende Versionszeile), Build aus `CFBundleVersion` (kommt über `GENERATE_INFOPLIST_FILE` aus `CURRENT_PROJECT_VERSION`). Die OS-Version liefert `UIDevice.current.systemVersion`, z. B. `"18.4"`, also genau das Format aus dem Beispiel. Gelesen wird das in der View (Presentation), wie heute `appVersion`.
- **Nach „Adresse kopieren“ schließt der Dialog** (Standardverhalten von Alert-Buttons). Es gibt keine eigene Bestätigung „Kopiert“. iOS 16+ zeigt beim programmatischen Schreiben ins Pasteboard nichts an. Der Ticket-Text verlangt nur, dass sich die Adresse kopieren lässt.
- **Kein neuer Dienst, kein ViewModel:** Die Funktion ist zustandslos (zwei Adressen, ein Dialog-Flag). Ein ViewModel bzw. ein `…Service` in `AppDependencies` wäre Overengineering. Testbar ist das, was Logik enthält: der Aufbau der Adressen im Domain-Layer.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Domain/Models/FeedbackLinks.swift` | Domain | Neu | Reines `enum` (nur `Foundation`, wie `ApplePodcastsLink`): `contactAddress`, `rateAppURL: URL?`, `static func writeToUsURL(appVersion:build:osVersion:) -> URL?` |
| `ios/StillMomentTests/Domain/FeedbackLinksTests.swift` | Test | Neu | Fachliche Tests zu Store- und Mail-Adresse (siehe Szenarien) |
| `ios/StillMoment/Presentation/Views/AppSettings/AppSettingsView.swift` | Presentation | Erweitern | Zwei Zeilen zwischen Datenschutz und Version, Dialog „Kein Mail-Programm“, `@Environment(\.openURL)`, `@State` für den Dialog, `buildNumber`/`osVersion` neben `appVersion` |
| `ios/StillMoment/Resources/de.lproj/Localizable.strings` | Resources | Erweitern | 8 neue Keys im Block `// MARK: - App Settings Tab` |
| `ios/StillMoment/Resources/en.lproj/Localizable.strings` | Resources | Erweitern | dieselben 8 Keys |
| `dev-docs/reference/glossary.md` | Docs | Erweitern | Eintrag `FeedbackLinks` (Quick Reference + Detail), den Namen übernimmt Android 1:1 |
| `CHANGELOG.md` | Docs | Erweitern | über `/implement-ticket` / `/close-ticket` |

Nicht betroffen: `AppDependencies` (kein neuer Dienst), `AppSettingsView+Previews.swift` (Init-Signatur bleibt gleich), `ScreenshotTests` (die Row-ID `app.settings.row.soundAttributions` bleibt).

**Datei-Länge:** `AppSettingsView.swift` hat heute 111 Zeilen. Mit zwei Zeilen-Views, Alert und drei Hilfs-Properties kommen etwa 70–90 dazu, deutlich unter `file_length` 400. Eine Aufteilung ist nicht nötig. Die neuen Zeilen kommen als eigene private Properties (`rateAppRow`, `writeToUsRow`), damit `infoSection` unter `function_body_length` (warning 40 / error 60) aus `ios/.swiftlint.yml` bleibt.

### Vorhandenes Muster: Datenschutz-Zeile

```swift
if let url = self.privacyURL {
    Link(destination: url) { Text("app.settings.privacy.title", bundle: .main).textStyle(.body, color: \.textPrimary) }
        .accessibilityIdentifier("app.settings.row.privacy")
        .accessibilityHint(NSLocalizedString("accessibility.appSettings.privacy.hint", comment: ""))
        .cardRowBackground()
}
```

- **App bewerten** übernimmt das Muster 1:1 (`Link(destination: FeedbackLinks.rateAppURL)`, ID `app.settings.row.rateApp`). Ein Fehlschlag ist hier unkritisch: `https` öffnet auf jedem Gerät mindestens Safari.
- **Schreib uns** braucht eine Rückmeldung, ob das Öffnen geklappt hat. `Link` liefert keine. Deshalb wird es ein `Button`, der `openURL(url) { accepted in … }` aus `@Environment(\.openURL)` aufruft. Bei `accepted == false` wird `showsNoMailAppAlert = true` gesetzt. ID `app.settings.row.writeToUs`. Das Label ist ein `VStack(alignment: .leading, spacing: 3)` mit Titel `.textStyle(.body, color: \.textPrimary)` und Untertitel `.textStyle(.caption, color: \.textSecondary)`, wie die Kopfkarte in `PreparationTimeSelectionView`. Damit die Zeile über die volle Breite tippbar ist, kommt `.frame(maxWidth: .infinity, alignment: .leading)` und `.contentShape(Rectangle())` dazu. Ein `Button` in einer `Form` fasst Titel und Untertitel für VoiceOver schon zu einem Element zusammen.
- Gibt `FeedbackLinks.writeToUsURL(...)` `nil` zurück (praktisch unmöglich), wird ebenfalls der Dialog gezeigt. So bleibt ein Tippen nie ohne Reaktion.

### Dialog

Aufbau wie die bestehenden `.alert(_:isPresented:actions:message:)` (z. B. `GuidedMeditationsListView`):

- Titel `NSLocalizedString("app.settings.writeToUs.noMailApp.title", …)`
- Button „Adresse kopieren“: `UIPasteboard.general.string = FeedbackLinks.contactAddress`
- Button `common.ok` mit `role: .cancel`
- Nachricht `Text(String(format: NSLocalizedString("app.settings.writeToUs.noMailApp.message", comment: ""), FeedbackLinks.contactAddress))`, also ein Format-Argument und keine Interpolation

`UIPasteboard` und `UIDevice` gehören zu UIKit. Sie werden nur in der Presentation-Datei verwendet (`import UIKit` bzw. über SwiftUI verfügbar), der Domain-Layer bleibt frei davon.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `OpenURLAction.callAsFunction(_:completion:)` (`@Environment(\.openURL)`) | iOS 14 | Apple Docs (JSON-Endpunkt der Doku-Seite) | Die Completion liefert ein `Bool`, das angibt, „whether the method can open the URL“. Sie wird aufgerufen, nachdem feststeht, ob sich die Adresse öffnen lässt, möglicherweise bevor sie ganz geöffnet ist. Läuft auf `@MainActor`, das Setzen von `@State` ist also sicher. |
| `Link(destination:label:)` | iOS 14 | bestehender Code | wie die Datenschutz-Zeile |
| `.alert(_:isPresented:actions:message:)` | iOS 15 | bestehender Code | Muster in `GuidedMeditationsListView`, `StillMomentApp` |
| `UIPasteboard.general.string` | iOS 3 | UIKit | Für `open` von `mailto` ist kein Eintrag in `LSApplicationQueriesSchemes` nötig, das betrifft nur `canOpenURL`. |
| `UIDevice.current.systemVersion` | iOS 2 | UIKit | liefert z. B. `"18.4"` (ohne `.0`) |
| `URLComponents` (scheme `mailto`, `path`, `queryItems`) | – | Foundation | kodiert Leerzeichen als `%20` (nicht `+`), `\r\n` als `%0D%0A`, `·` als `%C2%B7` |

**Woran man erkennt, dass mailto nicht geöffnet werden kann (iOS 16+):**

- `openURL(url) { accepted in }` ist das richtige Signal. `canOpenURL` ist ungeeignet: Es braucht einen Eintrag in `LSApplicationQueriesSchemes` und liefert laut Entwicklerberichten nach dem Löschen von Apple Mail trotzdem `true`.
- **Simulator** (keine Mail-App installiert): Das Öffnen von `mailto` schlägt fehl, `accepted == false`, unser Dialog erscheint. Damit lässt sich Schritt 4 des manuellen Tests direkt im Simulator prüfen. (Entwicklerberichte nennen für `canOpenURL(mailto)` im Simulator `false`. Für die `open`-Completion wird das gleiche Verhalten erwartet, beim Implementieren im Simulator verifizieren.)
- **Echtes Gerät, Apple Mail gelöscht:** iOS zeigt seinen eigenen Dialog „Mail wiederherstellen?“ (App-Store-Link). `accepted` kann dabei `true` sein, dann erscheint unser Dialog nicht. Das Akzeptanzkriterium „Tippen bleibt nie ohne Reaktion“ ist trotzdem erfüllt, weil der Systemdialog die Reaktion ist. Die Adresse zum Kopieren gibt es in diesem Fall aber nicht. Das kann eine App nicht erkennen (siehe Offene Fragen).
- **Apple Mail installiert, aber kein Konto eingerichtet:** Mail öffnet sich und führt selbst durch die Einrichtung, `accepted == true`. Auch das ist eine Reaktion.

Quellen: Apple Docs `OpenURLAction/callAsFunction(_:completion:)`; Apple Developer Forums [704707](https://developer.apple.com/forums/thread/704707) und [705573](https://developer.apple.com/forums/thread/705573) (Verhalten bei gelöschter Mail-App).

## Design-Entscheidungen

### 1. Adressaufbau im Domain-Layer als reines Enum

**Trade-off:** Die Adressen ließen sich direkt in der View bauen, ohne Domain-Typ. Dann wären sie aber nicht unit-testbar, und die Kodierung (`%20`, CRLF, `·`) ist die einzige Stelle mit echter Fehlergefahr. Ein Protokoll/Service mit DI wäre für zwei statische Adressen zu viel.
**Entscheidung:** `enum FeedbackLinks` in `Domain/Models/` mit statischen Membern, nur `Foundation`, keine Plattform-Imports, so wie `ApplePodcastsLink`. Version, Build und OS-Version kommen als einfache Strings rein. Die View liest sie aus `Bundle.main` und `UIDevice`. Die Zeile „· iOS“ ist im iOS-Domain-Typ fest verdrahtet, Android setzt „· Android“ in seinem eigenen Gegenstück.

### 2. `Button` + `openURL`-Completion statt `Link` für „Schreib uns“

**Trade-off:** `Link` passt optisch zur Datenschutz-Zeile, meldet aber keinen Fehlschlag. Dann bliebe ein Tippen im Simulator oder ohne Mail-Handler ohne Reaktion.
**Entscheidung:** `Button` mit `@Environment(\.openURL)` und Completion. `UIApplication.shared.open` (wie in `ContentGuideSheet`) würde ebenfalls gehen, `openURL` ist aber der SwiftUI-Weg und respektiert eventuelle Environment-Overrides. Overrides gibt es heute keine.

### 3. Kein `MFMailComposeViewController`

**Trade-off:** Der Composer bliebe in der App, funktioniert aber nur mit Apple Mail (`canSendMail()` ist `false`, sobald Apple Mail fehlt oder kein Konto eingerichtet ist). Personen, die Gmail oder Outlook als Standard nutzen, erreicht er nicht.
**Entscheidung:** `mailto:` öffnet das eingestellte Standard-Mail-Programm, wie es das Ticket verlangt („öffnet das Mail-Programm“).

## Refactorings

Keine. Die Änderung ist rein additiv.

## Fachliche Szenarien

### AK-1: Einträge im Info-Bereich

- Gegeben: Einstellungen sind geöffnet
  Wenn: Die Person zum Info-Bereich scrollt
  Dann: Sie sieht der Reihe nach „Klang-Nachweise“, „Datenschutz“, „App bewerten“, „Schreib uns“ mit dem Untertitel „Hallo sagen, danke sagen, Feedback geben“, und „Version“

### AK-2: App bewerten öffnet den App Store

- Gegeben: –
  Wenn: Die Adresse zum Bewerten gebildet wird
  Dann: Sie führt auf `apps.apple.com` zur App mit der ID 6755774465 und öffnet direkt das Schreiben einer Bewertung (`action=write-review`) *(Unit-Test)*
- Gegeben: Gerät mit App Store
  Wenn: Die Person auf „App bewerten“ tippt
  Dann: Der App Store öffnet Still Moment mit dem Bewertungsfenster *(manuell; der Simulator öffnet stattdessen Safari)*

### AK-4/5: Schreib uns öffnet eine vorbereitete Mail

- Gegeben: App-Version 2.5.0, Build 11, iOS 18.4
  Wenn: Die Mail-Adresse gebildet wird
  Dann: Empfänger ist `hello@stillmoment.app` *(Unit-Test)*
- … Dann: Der Betreff ist „Still Moment“ *(Unit-Test, nach Dekodieren)*
- … Dann: Der Text beginnt mit zwei Leerzeilen, die dritte Zeile lautet „Still Moment 2.5.0 (11) · iOS 18.4“ *(Unit-Test, nach Dekodieren)*
- … Dann: Leerzeichen sind als `%20` kodiert, nicht als `+`, sonst zeigen manche Mail-Programme Pluszeichen *(Unit-Test auf `absoluteString`)*
- Gegeben: Eine Version mit Sonderzeichen, z. B. `2.5.0-beta+1`
  Wenn: Die Mail-Adresse gebildet wird
  Dann: Nach dem Dekodieren steht die Version unverändert im Text (das `+` bleibt ein `+`) *(Unit-Test; prüft, dass `+` und `&` nicht den Query zerbrechen. Wenn `URLComponents` `+` nicht kodiert, `percentEncodedQueryItems` bzw. eigenes Kodieren nutzen. Beim Implementieren per Test klären.)*
- Gegeben: Gerät mit Mail-Programm
  Wenn: Die Person auf „Schreib uns“ tippt
  Dann: Das Mail-Programm zeigt eine neue Nachricht mit Empfänger, Betreff und Versionszeile. Die Zeile lässt sich vor dem Senden löschen *(manuell)*

### AK-6: Kein Mail-Programm

- Gegeben: Simulator ohne Mail-App
  Wenn: Die Person auf „Schreib uns“ tippt
  Dann: Der Dialog „Kein Mail-Programm gefunden“ erscheint mit „Du erreichst uns unter hello@stillmoment.app“ und den Buttons „Adresse kopieren“ und „OK“ *(manuell)*
- Gegeben: Der Dialog ist offen
  Wenn: Die Person auf „Adresse kopieren“ tippt
  Dann: Der Dialog schließt, und `hello@stillmoment.app` liegt in der Zwischenablage (Einfügen in Notizen o. ä. funktioniert) *(manuell)*
- Gegeben: Der Dialog ist offen
  Wenn: Die Person auf „OK“ tippt
  Dann: Der Dialog schließt, sonst passiert nichts

### AK-7: Keine automatische Bewertungsanfrage

- Gegeben: beliebiger Zeitpunkt (Start, nach Meditation)
  Dann: Kein Bewertungsfenster erscheint. *(Absicherung über Code-Review bzw. Grep: kein `StoreKit`/`requestReview` im Target. Ein Test dafür wäre nur technisch und bringt keinen fachlichen Mehrwert.)*

### AK-8: Accessibility

- Gegeben: VoiceOver aktiv
  Wenn: Der Fokus auf „App bewerten“ liegt
  Dann: VoiceOver liest „App bewerten, Taste, Öffnet den App Store“
- Wenn: Der Fokus auf „Schreib uns“ liegt
  Dann: VoiceOver liest Titel und Untertitel als ein Element, dazu den Hinweis „Öffnet dein Mail-Programm“
- Die Dialog-Buttons haben sichtbaren Text, damit sind sie automatisch beschriftet

### AK-9: Bestehende Einträge bleiben

- Klang-Nachweise öffnet weiterhin die Unterseite (die Screenshot-Tests verwenden `app.settings.row.soundAttributions`), Datenschutz öffnet die Webseite, Version zeigt `CFBundleShortVersionString` wie bisher

## Reihenfolge der Akzeptanzkriterien

1. **AK-2 + AK-4/5 (Domain):** `FeedbackLinksTests` zuerst (RED), danach `FeedbackLinks` (GREEN). Das ist die einzige Logik mit echter Fehlergefahr, nämlich die Kodierung.
2. **Lokalisierung:** alle 8 Keys in DE und EN anlegen (`make check` → `validate-localization` prüft Vollständigkeit und gleiche Platzhalter `%@`).
3. **AK-1, AK-2, AK-8 (View):** Zeile „App bewerten“ als `Link`.
4. **AK-4, AK-6, AK-8 (View):** Zeile „Schreib uns“ als `Button` + `openURL`-Completion + Dialog.
5. **AK-9 / AK-7:** Regression im Simulator prüfen (alle Zeilen, Hell und Dunkel, Dynamic Type groß) und `make check`.
6. **Doku:** Glossar-Eintrag `FeedbackLinks`, CHANGELOG.

## Manuelle Verifikation (Simulator + Gerät)

- Simulator: „Schreib uns“ → eigener Dialog; „Adresse kopieren“ → Einfügen prüfen; „App bewerten“ → Safari mit apps.apple.com
- Gerät mit Apple Mail: Nachricht mit Empfänger, Betreff und Versionszeile, Leerzeilen korrekt (CRLF wird nicht doppelt umgebrochen)
- Gerät mit Gmail/Outlook als Standard-Mail-App: Empfänger, Betreff und Text kommen an
- Gerät: „App bewerten“ öffnet im App Store direkt das Bewertungsfenster

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Apple Mail gelöscht: iOS zeigt „Mail wiederherstellen?“, `accepted` ist evtl. `true`, unser Dialog mit der Adresse erscheint nicht | Hinnehmen, weil die App das nicht erkennen kann. Das AK „nie ohne Reaktion“ bleibt erfüllt. Siehe Offene Fragen |
| CRLF (`%0D%0A`) erzeugt in einzelnen Mail-Apps doppelte Leerzeilen | Auf dem Gerät mit Apple Mail und Gmail prüfen. Falls nötig auf `\n` wechseln, der Test hängt am fachlichen Ergebnis (Zeilen), nicht an CRLF |
| `URLComponents.queryItems` kodiert `+` nicht und lässt die Version bei Sonderzeichen falsch dekodieren | Testszenario mit `+` in der Version. Bei Rot `+` gezielt nachkodieren |
| `Button` in `Form` wird mit der Akzentfarbe eingefärbt | Explizites `.textStyle(..., color:)` am Label setzt die Farbe. Optisch mit der Datenschutz-Zeile (`Link`) vergleichen, ggf. `.buttonStyle(.plain)` |

## Offene Fragen

- [ ] **Gelöschte Apple Mail auf dem Gerät:** Systemdialog „Mail wiederherstellen?“ statt unserem Dialog mit Kopier-Option. Ist das für das AK „sieht die Adresse und kann sie kopieren“ akzeptabel? Die App kann den Fall nicht zuverlässig erkennen. Eine Alternative wäre, die Adresse zusätzlich immer sichtbar zu machen (z. B. als Untertitel), das wäre aber eine UX-Änderung gegenüber den gesetzten Entscheidungen.
- [ ] **Zeilenumbruch CRLF vs. LF:** Der Plan nutzt CRLF (RFC-konform). Android baut die Mail per Intent, eventuell mit `EXTRA_TEXT` statt mailto-Body. Für Gleichheit reicht, dass das sichtbare Ergebnis gleich ist (2 Leerzeilen + Versionszeile).

## Entscheidungen zu den offenen Fragen (2026-10-09)

- **Gelöschte Apple Mail:** akzeptiert. Der Systemdialog „Mail wiederherstellen?“ ist eine Reaktion auf das Tippen. Die Adresse wird nicht zusätzlich dauerhaft angezeigt. Im Abschlussbericht als bekannte Einschränkung nennen.
- **CRLF:** beibehalten. Maßgeblich ist das sichtbare Ergebnis (2 Leerzeilen + Versionszeile).
- **Name:** `FeedbackLinks` auf beiden Plattformen.
- **Rückmeldung nach dem Kopieren:** keine eigene auf iOS, der Dialog schließt. Android zeigt auf ≤ 12L einen Toast (Plattform-Konvention).
